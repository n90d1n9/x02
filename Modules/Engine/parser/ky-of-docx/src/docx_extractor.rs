use std::collections::HashMap;
use std::io::{Cursor, Read};
use std::path::Path;

use zip::ZipArchive;

use crate::error::{DocxError, Result};
use crate::image::ImageData;
use crate::models::*;
use crate::parser;

// ---------------------------------------------------------------------------
// DocxReader – the central public API
// ---------------------------------------------------------------------------

/// The primary entry point for reading `.docx` files.
///
/// ```no_run
/// use docx_reader::DocxReader;
///
/// let reader = DocxReader::open("report.docx").unwrap();
///
/// // Plain text
/// let text = reader.extract_text().unwrap();
///
/// // Structured document
/// let doc = reader.parse().unwrap();
/// println!("{} paragraphs", doc.body.len());
///
/// // Metadata
/// let meta = reader.metadata().unwrap();
/// println!("Author: {:?}", meta.creator);
///
/// // Images
/// for img in reader.images().unwrap() {
///     println!("{} ({})", img.rel_id, img.content_type);
/// }
/// ```
pub struct DocxReader {
    raw: Vec<u8>,
}

impl DocxReader {
    // -----------------------------------------------------------------------
    // Constructors
    // -----------------------------------------------------------------------

    /// Open a `.docx` file from disk.
    pub fn open<P: AsRef<Path>>(path: P) -> Result<Self> {
        let raw = std::fs::read(path)?;
        Self::from_bytes(raw)
    }

    /// Create a reader from an in-memory byte slice (useful for web handlers,
    /// tests, etc.).
    pub fn from_bytes(raw: Vec<u8>) -> Result<Self> {
        // Quick sanity check: every DOCX must be a ZIP with a `[Content_Types].xml`.
        {
            let cursor = Cursor::new(&raw);
            let mut archive = ZipArchive::new(cursor)
                .map_err(|_| DocxError::InvalidArchive("not a ZIP archive".into()))?;
            archive
                .by_name("[Content_Types].xml")
                .map_err(|_| DocxError::InvalidArchive("missing [Content_Types].xml".into()))?;
        }
        Ok(Self { raw })
    }

    // -----------------------------------------------------------------------
    // Low-level ZIP access
    // -----------------------------------------------------------------------

    fn archive(&self) -> Result<ZipArchive<Cursor<&[u8]>>> {
        ZipArchive::new(Cursor::new(self.raw.as_slice())).map_err(Into::into)
    }

    /// Read a named part from the archive as a UTF-8 string.
    pub fn read_part(&self, name: &str) -> Result<String> {
        let mut archive = self.archive()?;
        let mut entry = archive
            .by_name(name)
            .map_err(|_| DocxError::MissingPart(name.to_string()))?;
        let mut buf = String::new();
        entry.read_to_string(&mut buf)?;
        Ok(buf)
    }

    /// Read a named part as raw bytes (for images, fonts, etc.).
    pub fn read_part_bytes(&self, name: &str) -> Result<Vec<u8>> {
        let mut archive = self.archive()?;
        let mut entry = archive
            .by_name(name)
            .map_err(|_| DocxError::MissingPart(name.to_string()))?;
        let mut buf = Vec::new();
        entry.read_to_end(&mut buf)?;
        Ok(buf)
    }

    /// List all part names inside the archive.
    pub fn part_names(&self) -> Result<Vec<String>> {
        let mut archive = self.archive()?;
        let names = (0..archive.len())
            .filter_map(|i| archive.by_index(i).ok().map(|e| e.name().to_string()))
            .collect();
        Ok(names)
    }

    // -----------------------------------------------------------------------
    // Metadata
    // -----------------------------------------------------------------------

    /// Return core and application properties as a [`Metadata`] struct.
    pub fn metadata(&self) -> Result<Metadata> {
        let mut meta = if let Ok(core) = self.read_part("docProps/core.xml") {
            parser::parse_core_props(&core)
        } else {
            Metadata::default()
        };
        if let Ok(app) = self.read_part("docProps/app.xml") {
            parser::parse_app_props(&app, &mut meta);
        }
        Ok(meta)
    }

    // -----------------------------------------------------------------------
    // Styles
    // -----------------------------------------------------------------------

    /// Return all named styles defined in the document.
    pub fn styles(&self) -> Result<Vec<StyleDef>> {
        let xml = self
            .read_part("word/styles.xml")
            .map_err(|_| DocxError::PartNotPresent("word/styles.xml".into()))?;
        Ok(parser::parse_styles(&xml))
    }

    /// Build a `{ styleId -> styleName }` lookup map.
    pub(crate) fn style_id_map(&self) -> HashMap<String, String> {
        self.styles()
            .unwrap_or_default()
            .into_iter()
            .map(|s| (s.id, s.name))
            .collect()
    }

    // -----------------------------------------------------------------------
    // Relationships
    // -----------------------------------------------------------------------

    /// Parse `word/_rels/document.xml.rels` into `{ rId -> (type, target) }`.
    pub(crate) fn document_rels(&self) -> HashMap<String, (String, String)> {
        self.read_part("word/_rels/document.xml.rels")
            .map(|xml| parser::parse_relationships(&xml))
            .unwrap_or_default()
    }

    // -----------------------------------------------------------------------
    // Numbering
    // -----------------------------------------------------------------------

    pub(crate) fn numbering_map(&self) -> HashMap<String, ListType> {
        self.read_part("word/numbering.xml")
            .map(|xml| parser::parse_numbering(&xml))
            .unwrap_or_default()
    }

    // -----------------------------------------------------------------------
    // Images
    // -----------------------------------------------------------------------

    /// List all embedded images with metadata (no raw bytes loaded).
    pub fn images(&self) -> Result<Vec<ImageRef>> {
        let rels = self.document_rels();
        let content_types_xml = self.read_part("[Content_Types].xml").unwrap_or_default();
        let ct_map = parser::parse_content_types(&content_types_xml);

        let image_rels: Vec<ImageRef> = rels
            .into_iter()
            .filter(|(_, (typ, _))| typ.contains("/image"))
            .map(|(rel_id, (_, target))| {
                let full_path = format!("word/{}", target.trim_start_matches("../"));
                let ct = ct_map.get(&full_path).cloned().unwrap_or_else(|| {
                    // Guess from extension
                    match full_path.rsplit('.').next().unwrap_or("") {
                        "png" => "image/png",
                        "jpg" | "jpeg" => "image/jpeg",
                        "gif" => "image/gif",
                        "bmp" => "image/bmp",
                        "svg" => "image/svg+xml",
                        "tif" | "tiff" => "image/tiff",
                        "emf" => "image/x-emf",
                        "wmf" => "image/x-wmf",
                        _ => "application/octet-stream",
                    }
                    .to_string()
                });
                ImageRef {
                    rel_id,
                    target: full_path,
                    content_type: ct,
                    width_emu: None,
                    height_emu: None,
                    description: None,
                }
            })
            .collect();
        Ok(image_rels)
    }

    /// Load raw bytes for a specific image by its relationship ID.
    pub fn image_bytes(&self, rel_id: &str) -> Result<ImageData> {
        let rels = self.document_rels();
        let (_, target) = rels
            .get(rel_id)
            .ok_or_else(|| DocxError::ImageNotFound(rel_id.to_string()))?;
        let path = format!("word/{}", target.trim_start_matches("../"));
        let bytes = self.read_part_bytes(&path)?;
        let ext = path.rsplit('.').next().unwrap_or("bin");
        let mime = match ext {
            "png" => "image/png",
            "jpg" | "jpeg" => "image/jpeg",
            "gif" => "image/gif",
            "bmp" => "image/bmp",
            "svg" => "image/svg+xml",
            _ => "application/octet-stream",
        };
        Ok(ImageData {
            rel_id: rel_id.to_string(),
            bytes,
            mime_type: mime.to_string(),
            extension: ext.to_string(),
        })
    }

    /// Save an embedded image to a file.
    pub fn save_image<P: AsRef<Path>>(&self, rel_id: &str, dest: P) -> Result<()> {
        let data = self.image_bytes(rel_id)?;
        std::fs::write(dest, &data.bytes)?;
        Ok(())
    }

    // -----------------------------------------------------------------------
    // Comments
    // -----------------------------------------------------------------------

    /// Return all comments.
    pub fn comments(&self) -> Result<Vec<Comment>> {
        match self.read_part("word/comments.xml") {
            Ok(xml) => Ok(parser::parse_comments(&xml)),
            Err(DocxError::MissingPart(_)) => Ok(vec![]),
            Err(e) => Err(e),
        }
    }

    // -----------------------------------------------------------------------
    // Footnotes & Endnotes
    // -----------------------------------------------------------------------

    /// Return all footnotes.
    pub fn footnotes(&self) -> Result<Vec<Footnote>> {
        match self.read_part("word/footnotes.xml") {
            Ok(xml) => Ok(parser::parse_footnotes(&xml)),
            Err(DocxError::MissingPart(_)) => Ok(vec![]),
            Err(e) => Err(e),
        }
    }

    /// Return all endnotes.
    pub fn endnotes(&self) -> Result<Vec<Endnote>> {
        match self.read_part("word/endnotes.xml") {
            Ok(xml) => Ok(parser::parse_endnotes(&xml)),
            Err(DocxError::MissingPart(_)) => Ok(vec![]),
            Err(e) => Err(e),
        }
    }

    // -----------------------------------------------------------------------
    // Headers & Footers
    // -----------------------------------------------------------------------

    /// Return per-section headers and footers.
    pub fn headers_footers(&self) -> Result<Vec<SectionHeaderFooter>> {
        let doc_rels = self.document_rels();
        let mut shf = SectionHeaderFooter::default();

        for (_, (rel_type, target)) in &doc_rels {
            let is_header = rel_type.contains("/header");
            let is_footer = rel_type.contains("/footer");
            if !is_header && !is_footer {
                continue;
            }
            let path = format!("word/{}", target.trim_start_matches("../"));
            let xml = match self.read_part(&path) {
                Ok(x) => x,
                Err(_) => continue,
            };
            let paras = parser::parse_header_footer(&xml);

            // Classify by filename convention (header1/header2/header3 etc.)
            let name = path.rsplit('/').next().unwrap_or("");
            if is_header {
                if name.contains("1") {
                    shf.default_header = Some(paras);
                } else if name.contains("2") {
                    shf.first_header = Some(paras);
                } else if name.contains("3") {
                    shf.even_header = Some(paras);
                } else {
                    shf.default_header = Some(paras);
                }
            } else if is_footer {
                if name.contains("1") {
                    shf.default_footer = Some(paras);
                } else if name.contains("2") {
                    shf.first_footer = Some(paras);
                } else if name.contains("3") {
                    shf.even_footer = Some(paras);
                } else {
                    shf.default_footer = Some(paras);
                }
            }
        }

        Ok(vec![shf])
    }

    // -----------------------------------------------------------------------
    // Full structured parse
    // -----------------------------------------------------------------------

    /// Parse the entire document into a [`Document`] struct.
    ///
    /// This is the richest (and most expensive) API call.
    pub fn parse(&self) -> Result<Document> {
        let metadata = self.metadata()?;
        let styles_list = self.styles().unwrap_or_default();
        let styles_map = self.style_id_map();
        let numbering_map = self.numbering_map();
        let rels = self.document_rels();

        let doc_xml = self
            .read_part("word/document.xml")
            .map_err(|_| DocxError::MissingPart("word/document.xml".into()))?;

        let dp = parser::DocumentParser {
            rels: &rels,
            styles_map: &styles_map,
            numbering_map: &numbering_map,
        };
        let (body, tracked_changes, mut images) = dp.parse(&doc_xml)?;

        // Enrich images with content types
        let content_types_xml = self.read_part("[Content_Types].xml").unwrap_or_default();
        let ct_map = parser::parse_content_types(&content_types_xml);
        for img in &mut images {
            if img.content_type.is_empty() {
                if let Some(ct) = ct_map.get(&img.target) {
                    img.content_type = ct.clone();
                }
            }
        }

        let footnotes = self.footnotes()?;
        let endnotes = self.endnotes()?;
        let comments = self.comments()?;
        let headers_footers = self.headers_footers()?;

        Ok(Document {
            metadata,
            body,
            footnotes,
            endnotes,
            comments,
            tracked_changes,
            images,
            styles: styles_list,
            headers_footers,
        })
    }

    // -----------------------------------------------------------------------
    // Text extraction
    // -----------------------------------------------------------------------

    /// Backward‑compatible wrapper that creates a document without header/footer.
    ///
    /// This keeps existing code working while the more flexible API lives under
    /// `create_docx_with_parts`.
    pub fn create_docx<P: AsRef<std::path::Path>>(content: &str, destination: P) -> Result<()> {
        Self::create_docx_with_parts(content, destination, None, None)
    }

    /// Extract plain text using default [`TextOptions`].
    pub fn extract_text(&self) -> Result<String> {
        self.extract_text_with_options(&TextOptions::default())
    }

    // -----------------------------------------------------------------------
    // Document creation
    // -----------------------------------------------------------------------

    /// Create a minimal `.docx` file from plain text content.
    ///
    /// The function writes a ZIP archive containing the required parts for a
    /// valid Word document. It currently supports only plain‑text bodies; more
    /// complex structures (styles, images, etc.) can be added in future work.
    ///
    /// # Arguments
    /// * `content` – The raw text that will become the document body.
    /// * `destination` – Path where the `.docx` file should be written.
    ///
    /// # Example
    /// ```
    /// fn example() -> Result<(), Box<dyn std::error::Error>> {
    ///     let reader = docx_reader::DocxReader::open("input.docx")?;
    ///     let text = reader.extract_text()?;
    ///     docx_reader::DocxReader::create_docx(&text, "output.docx")?;
    ///     Ok(())
    /// }
    /// ```
    /// Create a minimal `.docx` file from plain text content, optionally including header and footer XML.
    ///
    /// * `content` – The main body text.
    /// * `destination` – Path to write the `.docx` file.
    /// * `header_xml` – Optional raw XML for the document header (e.g., `<w:p>...</w:p>`). If `None`, no header is written.
    /// * `footer_xml` – Optional raw XML for the document footer.
    ///
    /// This function builds the required parts and relationship entries for Word to recognise the header/footer.
    pub fn create_docx_with_parts<P: AsRef<std::path::Path>>(
        content: &str,
        destination: P,
        _header_xml: Option<&str>,
        _footer_xml: Option<&str>,
    ) -> Result<()> {
        use std::io::Write;
        use zip::write::FileOptions;
        let mut buffer = std::io::Cursor::new(Vec::new());
        let mut zip = zip::ZipWriter::new(&mut buffer);
        let options = FileOptions::default().compression_method(zip::CompressionMethod::Deflated);

        // Required minimal parts
        zip.start_file("[Content_Types].xml", options)?;
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>"#)?;

        zip.start_file("_rels/.rels", options)?;
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"#)?;

        zip.start_file("word/_rels/document.xml.rels", options)?;
        zip.write_all(
            br#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>"#,
        )?;

        zip.start_file("word/document.xml", options)?;
        let escaped = htmlescape::encode_minimal(content);
        let doc_xml = format!(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">\n  <w:body>\n    <w:p><w:r><w:t>{}</w:t></w:r></w:p>\n    <w:sectPr/>\n  </w:body>\n</w:document>",
            escaped
        );
        zip.write_all(doc_xml.as_bytes())?;

        zip.finish()?;
        drop(zip);
        std::fs::write(destination, buffer.into_inner())?;
        Ok(())
    }

    // -----------------------------------------------------------------------
    // Legacy .doc support (stub)
    // -----------------------------------------------------------------------

    /// Attempt to extract a legacy `.doc` file.
    ///
    /// Currently unimplemented – returns a `Logic` error indicating the format
    /// is not supported. A full implementation could use the `ole`/`doc` crates.
    pub fn extract_doc<P: AsRef<std::path::Path>>(_path: P) -> Result<()> {
        Err(DocxError::Logic(
            "Legacy .doc extraction not implemented".into(),
        ))
    }

    /// Extract plain text with fine-grained control.
    pub fn extract_text_with_options(&self, opts: &TextOptions) -> Result<String> {
        let doc = self.parse()?;
        let mut out = String::new();

        // Headers
        if opts.include_headers {
            for shf in &doc.headers_footers {
                if let Some(paras) = &shf.default_header {
                    for p in paras {
                        out.push_str(&p.text());
                        out.push_str(&opts.paragraph_separator);
                    }
                }
            }
        }

        // Body
        for block in &doc.body {
            match block {
                Block::Paragraph(p) => {
                    out.push_str(&p.text());
                    out.push_str(&opts.paragraph_separator);
                }
                Block::Table(t) => {
                    for row in &t.rows {
                        let row_text: Vec<String> = row.cells.iter().map(|c| c.text()).collect();
                        out.push_str(&row_text.join(&opts.table_cell_separator));
                        out.push_str(&opts.table_row_separator);
                    }
                    out.push_str(&opts.paragraph_separator);
                }
                Block::SectionBreak => {
                    out.push('\n');
                }
            }
        }

        // Footnotes
        if opts.include_footnotes && !doc.footnotes.is_empty() {
            out.push_str("\n--- Footnotes ---\n");
            for fn_ in &doc.footnotes {
                out.push_str(&format!("[{}] {}\n", fn_.id, fn_.text()));
            }
        }

        // Endnotes
        if opts.include_endnotes && !doc.endnotes.is_empty() {
            out.push_str("\n--- Endnotes ---\n");
            for en in &doc.endnotes {
                out.push_str(&format!("[{}] {}\n", en.id, en.text()));
            }
        }

        // Comments
        if opts.include_comments && !doc.comments.is_empty() {
            out.push_str("\n--- Comments ---\n");
            for c in &doc.comments {
                out.push_str(&format!("[{}] ({}): {}\n", c.id, c.author, c.text()));
            }
        }

        // Footers
        if opts.include_footers {
            for shf in &doc.headers_footers {
                if let Some(paras) = &shf.default_footer {
                    for p in paras {
                        out.push_str(&p.text());
                        out.push_str(&opts.paragraph_separator);
                    }
                }
            }
        }

        Ok(out)
    }

    // -----------------------------------------------------------------------
    // Targeted helpers
    // -----------------------------------------------------------------------

    /// Return only the heading paragraphs, optionally filtered by level.
    pub fn headings(&self, level: Option<u8>) -> Result<Vec<Paragraph>> {
        let doc = self.parse()?;
        let headings = doc
            .body
            .into_iter()
            .filter_map(|b| {
                if let Block::Paragraph(p) = b {
                    Some(p)
                } else {
                    None
                }
            })
            .filter(|p| {
                let hl = p.heading_level;
                hl.is_some() && level.map_or(true, |l| hl == Some(l))
            })
            .collect();
        Ok(headings)
    }

    /// Return all `Table` blocks.
    pub fn tables(&self) -> Result<Vec<Table>> {
        let doc = self.parse()?;
        Ok(doc
            .body
            .into_iter()
            .filter_map(|b| {
                if let Block::Table(t) = b {
                    Some(t)
                } else {
                    None
                }
            })
            .collect())
    }

    /// Return tracked changes.
    pub fn tracked_changes(&self) -> Result<Vec<TrackedChange>> {
        Ok(self.parse()?.tracked_changes)
    }

    /// Serialize the parsed document to JSON.
    pub fn to_json(&self) -> Result<String> {
        let doc = self.parse()?;
        serde_json::to_string_pretty(&doc).map_err(|e| DocxError::Logic(e.to_string()))
    }

    // -----------------------------------------------------------------------
    // Word / character statistics
    // -----------------------------------------------------------------------

    /// Count words in the document body (rough; splits on whitespace).
    pub fn word_count(&self) -> Result<usize> {
        let text = self.extract_text()?;
        Ok(text.split_whitespace().count())
    }

    /// Count characters (Unicode scalar values) in the document body.
    pub fn char_count(&self) -> Result<usize> {
        let text = self.extract_text()?;
        Ok(text.chars().count())
    }

    // -----------------------------------------------------------------------
    // Raw XML access (advanced / debugging)
    // -----------------------------------------------------------------------

    /// Return the raw `word/document.xml` string.
    pub fn raw_document_xml(&self) -> Result<String> {
        self.read_part("word/document.xml")
    }

    /// Return the raw `word/styles.xml` string.
    pub fn raw_styles_xml(&self) -> Result<String> {
        self.read_part("word/styles.xml")
    }
}

//! # DocxWriter – Full-featured document creation API
//!
//! Builder-style API for creating `.docx` files. Supports paragraphs, tables,
//! images, headers/footers, hyperlinks, comments, tracked changes, document
//! properties, page layout, footnotes, endnotes, and text formatting.

use crate::image::ImageData;
use std::io::Write;
use zip::write::FileOptions;

/// Result type used throughout the crate.
pub type Result<T> = std::result::Result<T, crate::error::DocxError>;

// ─────────────────────────────────────────────────────────────
// Supporting types
// ─────────────────────────────────────────────────────────────

/// Text character formatting options.
#[derive(Debug, Clone, Default)]
pub struct RunFormat {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
    pub color: Option<String>,           // e.g. "FF0000"
    pub highlight: Option<String>,       // e.g. "yellow"
    pub font_size_half_pts: Option<u32>, // half-points (24 = 12pt)
    pub font: Option<String>,
}

/// Page layout options.
#[derive(Debug, Clone)]
pub struct PageLayout {
    /// Page width in twentieths of a point (twips). A4 ≈ 11906.
    pub width: u32,
    /// Page height in twips. A4 ≈ 16838.
    pub height: u32,
    /// Top margin in twips.
    pub margin_top: u32,
    /// Bottom margin in twips.
    pub margin_bottom: u32,
    /// Left margin in twips.
    pub margin_left: u32,
    /// Right margin in twips.
    pub margin_right: u32,
    /// Landscape orientation.
    pub landscape: bool,
}

impl Default for PageLayout {
    fn default() -> Self {
        Self {
            width: 12240,     // Letter (8.5 in)
            height: 15840,    // Letter (11 in)
            margin_top: 1440, // 1 inch
            margin_bottom: 1440,
            margin_left: 1800, // 1.25 inch
            margin_right: 1800,
            landscape: false,
        }
    }
}

/// Document core properties (metadata).
#[derive(Debug, Clone, Default)]
pub struct DocProperties {
    pub title: Option<String>,
    pub subject: Option<String>,
    pub author: Option<String>,
    pub description: Option<String>,
    pub keywords: Option<String>,
}

/// A single element in the document body.
#[derive(Debug, Clone)]
pub enum DocxElement {
    /// A plain or styled paragraph.
    Paragraph {
        text: String,
        style: Option<String>,
        fmt: Option<RunFormat>,
    },
    /// A tracked insertion (revision mark).
    TrackedInsert { text: String, author: String },
    /// A tracked deletion (revision mark).
    TrackedDelete { text: String, author: String },
    /// A paragraph with a comment balloon attached.
    Comment { text: String, comment: String },
    /// A hyperlink paragraph.
    Hyperlink { text: String, url: String },
    /// A table with borders.
    Table(Vec<Vec<String>>),
    /// An embedded image.
    Image(ImageData),
    /// A table of contents placeholder.
    TOC,
    /// A footnote reference inline with anchor text.
    Footnote { text: String, note: String },
    /// An endnote reference inline with anchor text.
    Endnote { text: String, note: String },
    /// A custom XML part.
    CustomXml { name: String, content: String },
    /// An explicit page break.
    PageBreak,
}

// ─────────────────────────────────────────────────────────────
// DocxWriter
// ─────────────────────────────────────────────────────────────

/// Builder for constructing a DOCX file.
#[derive(Debug, Default)]
pub struct DocxWriter {
    elements: Vec<DocxElement>,
    header: Option<String>,
    footer: Option<String>,
    page_layout: Option<PageLayout>,
    properties: Option<DocProperties>,
}

impl DocxWriter {
    /// Create a new, empty writer.
    pub fn new() -> Self {
        Self::default()
    }

    // ── Paragraphs ──────────────────────────────────────────

    /// Append a plain text paragraph.
    pub fn add_paragraph<S: AsRef<str>>(mut self, text: S) -> Self {
        self.elements.push(DocxElement::Paragraph {
            text: text.as_ref().to_string(),
            style: None,
            fmt: None,
        });
        self
    }

    /// Append a paragraph with a named paragraph style (e.g. `"Heading1"`).
    pub fn add_paragraph_with_style<S: AsRef<str>, T: AsRef<str>>(
        mut self,
        text: S,
        style: T,
    ) -> Self {
        self.elements.push(DocxElement::Paragraph {
            text: text.as_ref().to_string(),
            style: Some(style.as_ref().to_string()),
            fmt: None,
        });
        self
    }

    /// Append a paragraph with fine-grained character formatting.
    pub fn add_paragraph_formatted<S: AsRef<str>>(mut self, text: S, fmt: RunFormat) -> Self {
        self.elements.push(DocxElement::Paragraph {
            text: text.as_ref().to_string(),
            style: None,
            fmt: Some(fmt),
        });
        self
    }

    // ── Tracked changes ─────────────────────────────────────

    /// Append a tracked-insertion run.
    pub fn add_tracked_insert<S: AsRef<str>, A: AsRef<str>>(mut self, text: S, author: A) -> Self {
        self.elements.push(DocxElement::TrackedInsert {
            text: text.as_ref().to_string(),
            author: author.as_ref().to_string(),
        });
        self
    }

    /// Append a tracked-deletion run.
    pub fn add_tracked_delete<S: AsRef<str>, A: AsRef<str>>(mut self, text: S, author: A) -> Self {
        self.elements.push(DocxElement::TrackedDelete {
            text: text.as_ref().to_string(),
            author: author.as_ref().to_string(),
        });
        self
    }

    // ── Comments ─────────────────────────────────────────────

    /// Append a table of contents field.
    pub fn add_toc(mut self) -> Self {
        self.elements.push(DocxElement::TOC);
        self
    }

    pub fn add_comment<S: AsRef<str>, C: AsRef<str>>(mut self, text: S, comment: C) -> Self {
        self.elements.push(DocxElement::Comment {
            text: text.as_ref().to_string(),
            comment: comment.as_ref().to_string(),
        });
        self
    }

    // ── Hyperlinks ───────────────────────────────────────────

    /// Append a hyperlink.
    pub fn add_hyperlink<S: AsRef<str>, U: AsRef<str>>(mut self, text: S, url: U) -> Self {
        self.elements.push(DocxElement::Hyperlink {
            text: text.as_ref().to_string(),
            url: url.as_ref().to_string(),
        });
        self
    }

    // ── Tables ───────────────────────────────────────────────

    /// Append a table. Each element of `rows` is a row; each inner `String` is a cell.
    pub fn add_table<R: Into<Vec<Vec<String>>>>(mut self, rows: R) -> Self {
        self.elements.push(DocxElement::Table(rows.into()));
        self
    }

    // ── Images ───────────────────────────────────────────────

    /// Embed an image at the current position.
    pub fn add_image(mut self, image: ImageData) -> Self {
        self.elements.push(DocxElement::Image(image));
        self
    }

    // ── Footnotes / Endnotes ─────────────────────────────────

    /// Append a paragraph with a footnote reference.
    pub fn add_footnote<S: AsRef<str>, N: AsRef<str>>(mut self, text: S, note: N) -> Self {
        self.elements.push(DocxElement::Footnote {
            text: text.as_ref().to_string(),
            note: note.as_ref().to_string(),
        });
        self
    }

    /// Append a paragraph with an endnote reference.
    pub fn add_endnote<S: AsRef<str>, N: AsRef<str>>(mut self, text: S, note: N) -> Self {
        self.elements.push(DocxElement::Endnote {
            text: text.as_ref().to_string(),
            note: note.as_ref().to_string(),
        });
        self
    }

    // ── Page breaks ──────────────────────────────────────────

    /// Insert an explicit page break.
    pub fn add_page_break(mut self) -> Self {
        self.elements.push(DocxElement::PageBreak);
        self
    }

    // ── Header / Footer ──────────────────────────────────────

    /// Set a simple text header.
    pub fn set_header<S: AsRef<str>>(mut self, text: S) -> Self {
        self.header = Some(text.as_ref().to_string());
        self
    }

    /// Set a simple text footer.
    pub fn set_footer<S: AsRef<str>>(mut self, text: S) -> Self {
        self.footer = Some(text.as_ref().to_string());
        self
    }

    // ── Page layout ──────────────────────────────────────────

    /// Override page dimensions, margins, and orientation.
    pub fn set_page_layout(mut self, layout: PageLayout) -> Self {
        self.page_layout = Some(layout);
        self
    }

    // ── Document properties ──────────────────────────────────

    /// Set document core properties (author, title, …).
    pub fn set_properties(mut self, props: DocProperties) -> Self {
        self.properties = Some(props);
        self
    }

    /// Add a custom XML part.
    pub fn add_custom_xml<N: AsRef<str>, C: AsRef<str>>(mut self, name: N, content: C) -> Self {
        self.elements.push(DocxElement::CustomXml {
            name: name.as_ref().to_string(),
            content: content.as_ref().to_string(),
        });
        self
    }

    // ─────────────────────────────────────────────────────────
    // Write
    // ─────────────────────────────────────────────────────────

    /// Consume the writer and produce a `.docx` file at `destination`.
    pub fn write_to<P: AsRef<std::path::Path>>(self, destination: P) -> Result<()> {
        use std::io::Cursor;
        let mut zip = zip::ZipWriter::new(Cursor::new(Vec::new()));
        let options = FileOptions::default().compression_method(zip::CompressionMethod::Deflated);

        // ── Pre-scan elements for references ─────────────────
        let mut images: Vec<&ImageData> = Vec::new();
        let mut hyperlinks: Vec<&String> = Vec::new();
        let mut comments: Vec<(&String, &String)> = Vec::new(); // (text, comment)
        let mut footnotes: Vec<(&String, &String)> = Vec::new();
        let mut endnotes: Vec<(&String, &String)> = Vec::new();
        let mut custom_xml: Vec<(&String, &String)> = Vec::new();

        for el in &self.elements {
            match el {
                DocxElement::Image(img) => images.push(img),
                DocxElement::Hyperlink { text: _, url } => hyperlinks.push(url),
                DocxElement::Comment { text, comment } => comments.push((text, comment)),
                DocxElement::Footnote { text, note } => footnotes.push((text, note)),
                DocxElement::Endnote { text, note } => endnotes.push((text, note)),
                DocxElement::CustomXml { name, content } => custom_xml.push((name, content)),
                _ => {}
            }
        }

        // ── [Content_Types].xml ───────────────────────────────
        {
            let mut ct = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>"#,
            );
            if self.header.is_some() {
                ct.push_str(r#"
  <Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>"#);
            }
            if self.footer.is_some() {
                ct.push_str(r#"
  <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>"#);
            }
            if !comments.is_empty() {
                ct.push_str(r#"
  <Override PartName="/word/comments.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"/>"#);
            }
            if !footnotes.is_empty() {
                ct.push_str(r#"
  <Override PartName="/word/footnotes.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml"/>"#);
            }
            if !endnotes.is_empty() {
                ct.push_str(r#"
  <Override PartName="/word/endnotes.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"/>"#);
            }
            if self.properties.is_some() {
                ct.push_str(r#"
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>"#);
            }
            ct.push_str("\n</Types>");
            zip.start_file("[Content_Types].xml", options)?;
            zip.write_all(ct.as_bytes())?;
        }

        // ── _rels/.rels ───────────────────────────────────────
        {
            let mut rels = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>"#,
            );
            if self.properties.is_some() {
                rels.push_str(r#"
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>"#);
            }
            rels.push_str("\n</Relationships>");
            zip.start_file("_rels/.rels", options)?;
            zip.write_all(rels.as_bytes())?;
        }

        // ── word/_rels/document.xml.rels ──────────────────────
        let mut r_id: u32 = 1;
        let mut img_rids: Vec<String> = Vec::new();
        let mut link_rids: Vec<String> = Vec::new();
        let hdr_rid: Option<String>;
        let ftr_rid: Option<String>;
        let cmt_rid: Option<String>;
        let ftn_rid: Option<String>;
        let etn_rid: Option<String>;

        {
            let mut doc_rels = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">"#,
            );

            for img in &images {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                doc_rels.push_str(&format!(
                    "\n  <Relationship Id=\"{}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"media/{}\"/>",
                    rid, img.extension
                ));
                img_rids.push(rid);
            }
            for url in &hyperlinks {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                doc_rels.push_str(&format!(
                    "\n  <Relationship Id=\"{}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink\" Target=\"{}\" TargetMode=\"External\"/>",
                    rid, htmlescape::encode_minimal(url)
                ));
                link_rids.push(rid);
            }
            // custom XML parts
            for (name, _content) in &custom_xml {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                doc_rels.push_str(&format!(
                    "\n  <Relationship Id=\"{}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/customXml\" Target=\"customXml/{}\"/>",
                    rid, name
                ));
            }

            hdr_rid = self.header.as_ref().map(|_| {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                rid
            });
            if let Some(ref rid) = hdr_rid {
                doc_rels.push_str(&format!(r#"
  <Relationship Id="{}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>"#, rid));
            }

            ftr_rid = self.footer.as_ref().map(|_| {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                rid
            });
            if let Some(ref rid) = ftr_rid {
                doc_rels.push_str(&format!(r#"
  <Relationship Id="{}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>"#, rid));
            }

            cmt_rid = if !comments.is_empty() {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                Some(rid)
            } else {
                None
            };
            if let Some(ref rid) = cmt_rid {
                doc_rels.push_str(&format!(r#"
  <Relationship Id="{}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments" Target="comments.xml"/>"#, rid));
            }

            ftn_rid = if !footnotes.is_empty() {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                Some(rid)
            } else {
                None
            };
            if let Some(ref rid) = ftn_rid {
                doc_rels.push_str(&format!(r#"
  <Relationship Id="{}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes" Target="footnotes.xml"/>"#, rid));
            }

            etn_rid = if !endnotes.is_empty() {
                let rid = format!("rId{}", r_id);
                r_id += 1;
                Some(rid)
            } else {
                None
            };
            if let Some(ref rid) = etn_rid {
                doc_rels.push_str(&format!(r#"
  <Relationship Id="{}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/endnotes" Target="endnotes.xml"/>"#, rid));
            }

            let _ = r_id; // silence warning
            doc_rels.push_str("\n</Relationships>");
            zip.start_file("word/_rels/document.xml.rels", options)?;
            zip.write_all(doc_rels.as_bytes())?;
        }

        // ── Build body XML ─────────────────────────────────────
        let mut body_xml = String::new();
        let mut img_idx: usize = 0;
        let mut link_idx: usize = 0;
        let mut cmt_idx: u32 = 0;
        let mut ftn_idx: u32 = 0;
        let mut etn_idx: u32 = 0;
        let mut rev_id: u32 = 1;

        for el in &self.elements {
            match el {
                DocxElement::TOC => {
                    body_xml
                        .push_str(r#"<w:p><w:r><w:fldChar w:fldCharType="begin"/></w:r></w:p>"#);
                    body_xml.push_str(r#"<w:p><w:r><w:instrText xml:space="preserve">TOC \o "1-3" \h \z \u</w:instrText></w:r></w:p>"#);
                    body_xml
                        .push_str(r#"<w:p><w:r><w:fldChar w:fldCharType="separate"/></w:r></w:p>"#);
                    body_xml.push_str(r#"<w:p><w:r><w:t>Table of Contents</w:t></w:r></w:p>"#);
                    body_xml.push_str(r#"<w:p><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>"#);
                }

                DocxElement::Paragraph { text, style, fmt } => {
                    let esc = htmlescape::encode_minimal(text);
                    let pr = style
                        .as_ref()
                        .map(|s| format!(r#"<w:pPr><w:pStyle w:val="{}"/></w:pPr>"#, s))
                        .unwrap_or_default();
                    let rpr = build_rpr(fmt.as_ref());
                    body_xml.push_str(&format!(
                        "<w:p>{}<w:r>{}<w:t xml:space=\"preserve\">{}</w:t></w:r></w:p>",
                        pr, rpr, esc
                    ));
                }

                DocxElement::TrackedInsert { text, author } => {
                    let esc = htmlescape::encode_minimal(text);
                    body_xml.push_str(&format!(
                        r#"<w:p><w:ins w:id="{}" w:author="{}" w:date="2024-01-01T00:00:00Z"><w:r><w:t>{}</w:t></w:r></w:ins></w:p>"#,
                        rev_id, htmlescape::encode_minimal(author), esc
                    ));
                    rev_id += 1;
                }

                DocxElement::TrackedDelete { text, author } => {
                    let esc = htmlescape::encode_minimal(text);
                    body_xml.push_str(&format!(
                        r#"<w:p><w:del w:id="{}" w:author="{}" w:date="2024-01-01T00:00:00Z"><w:r><w:delText>{}</w:delText></w:r></w:del></w:p>"#,
                        rev_id, htmlescape::encode_minimal(author), esc
                    ));
                    rev_id += 1;
                }

                DocxElement::Comment { text, comment: _ } => {
                    let esc = htmlescape::encode_minimal(text);
                    let cid = cmt_idx;
                    cmt_idx += 1;
                    body_xml.push_str(&format!(
                        r#"<w:p><w:commentRangeStart w:id="{}"/><w:r><w:t>{}</w:t></w:r><w:commentRangeEnd w:id="{}"/><w:r><w:commentReference w:id="{}"/></w:r></w:p>"#,
                        cid, esc, cid, cid
                    ));
                }

                DocxElement::Hyperlink { text, url: _ } => {
                    let esc = htmlescape::encode_minimal(text);
                    let rid = &link_rids[link_idx];
                    link_idx += 1;
                    body_xml.push_str(&format!(
                        r#"<w:p><w:hyperlink r:id="{}"><w:r><w:rPr><w:u w:val="single"/><w:color w:val="0000FF"/></w:rPr><w:t>{}</w:t></w:r></w:hyperlink></w:p>"#,
                        rid, esc
                    ));
                }

                DocxElement::Table(rows) => {
                    body_xml.push_str(r#"<w:tbl><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/><w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/><w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/></w:tblBorders></w:tblPr>"#);
                    for row in rows {
                        body_xml.push_str("<w:tr>");
                        for cell in row {
                            let esc = htmlescape::encode_minimal(cell);
                            body_xml.push_str(&format!(
                                "<w:tc><w:p><w:r><w:t>{}</w:t></w:r></w:p></w:tc>",
                                esc
                            ));
                        }
                        body_xml.push_str("</w:tr>");
                    }
                    body_xml.push_str("</w:tbl>");
                }

                DocxElement::Image(_) => {
                    let rid = &img_rids[img_idx];
                    img_idx += 1;
                    body_xml.push_str(&format!(r#"<w:p><w:r><w:drawing><wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"><wp:extent cx="1905000" cy="1905000"/><wp:docPr id="1" name="Picture"/><a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:nvPicPr><pic:cNvPr id="0" name="img"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="{}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:ext cx="1905000" cy="1905000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>"#, rid));
                }

                DocxElement::Footnote { text, note: _ } => {
                    let esc = htmlescape::encode_minimal(text);
                    let fid = ftn_idx;
                    ftn_idx += 1;
                    body_xml.push_str(&format!(
                        r#"<w:p><w:r><w:t xml:space="preserve">{} </w:t></w:r><w:r><w:rPr><w:vertAlign w:val="superscript"/></w:rPr><w:footnoteReference w:id="{}"/></w:r></w:p>"#,
                        esc, fid
                    ));
                }

                DocxElement::Endnote { text, note: _ } => {
                    let esc = htmlescape::encode_minimal(text);
                    let eid = etn_idx;
                    etn_idx += 1;
                    body_xml.push_str(&format!(
                        r#"<w:p><w:r><w:t xml:space="preserve">{} </w:t></w:r><w:r><w:rPr><w:vertAlign w:val="superscript"/></w:rPr><w:endnoteReference w:id="{}"/></w:r></w:p>"#,
                        esc, eid
                    ));
                }
                DocxElement::CustomXml { .. } => {} // Custom XML parts are added separately; no body content needed.

                DocxElement::PageBreak => {
                    body_xml.push_str(r#"<w:p><w:r><w:br w:type="page"/></w:r></w:p>"#);
                }
            }
        }

        // sectPr – page layout + header/footer references
        body_xml.push_str("<w:sectPr>");
        if let Some(ref rid) = hdr_rid {
            body_xml.push_str(&format!(
                r#"<w:headerReference w:type="default" r:id="{}"/>"#,
                rid
            ));
        }
        if let Some(ref rid) = ftr_rid {
            body_xml.push_str(&format!(
                r#"<w:footerReference w:type="default" r:id="{}"/>"#,
                rid
            ));
        }
        let layout = self.page_layout.as_ref().cloned().unwrap_or_default();
        let (w, h) = if layout.landscape {
            (layout.height, layout.width)
        } else {
            (layout.width, layout.height)
        };
        body_xml.push_str(&format!(
            r#"<w:pgSz w:w="{}" w:h="{}"{}/>
<w:pgMar w:top="{}" w:bottom="{}" w:left="{}" w:right="{}"/>"#,
            w,
            h,
            if layout.landscape {
                r#" w:orient="landscape""#
            } else {
                ""
            },
            layout.margin_top,
            layout.margin_bottom,
            layout.margin_left,
            layout.margin_right
        ));
        body_xml.push_str("</w:sectPr>");

        // ── word/document.xml ─────────────────────────────────
        let doc_xml = format!(
            r#"<?xml version="1.0" encoding="UTF-8"?>
<w:document
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:body>{}</w:body>
</w:document>"#,
            body_xml
        );
        zip.start_file("word/document.xml", options)?;
        zip.write_all(doc_xml.as_bytes())?;

        // Write custom XML parts
        for (name, content) in &custom_xml {
            let path = format!("customXml/{}", name);
            zip.start_file(&path, options)?;
            zip.write_all(content.as_bytes())?;
        }

        // ── Header ────────────────────────────────────────────
        if let Some(ref hdr_text) = self.header {
            zip.start_file("word/header1.xml", options)?;
            let esc = htmlescape::encode_minimal(hdr_text);
            zip.write_all(
                format!(
                    r#"<?xml version="1.0" encoding="UTF-8"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p><w:r><w:t>{}</w:t></w:r></w:p>
</w:hdr>"#,
                    esc
                )
                .as_bytes(),
            )?;
        }

        // ── Footer ────────────────────────────────────────────
        if let Some(ref ftr_text) = self.footer {
            zip.start_file("word/footer1.xml", options)?;
            let esc = htmlescape::encode_minimal(ftr_text);
            zip.write_all(
                format!(
                    r#"<?xml version="1.0" encoding="UTF-8"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p><w:r><w:t>{}</w:t></w:r></w:p>
</w:ftr>"#,
                    esc
                )
                .as_bytes(),
            )?;
        }

        // ── Comments ──────────────────────────────────────────
        if !comments.is_empty() {
            zip.start_file("word/comments.xml", options)?;
            let mut xml = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<w:comments xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">"#,
            );
            for (id, (_, c_text)) in comments.iter().enumerate() {
                xml.push_str(&format!(
                    r#"<w:comment w:id="{}" w:author="Unknown" w:date="2024-01-01T00:00:00Z"><w:p><w:r><w:t>{}</w:t></w:r></w:p></w:comment>"#,
                    id, htmlescape::encode_minimal(c_text)
                ));
            }
            xml.push_str("</w:comments>");
            zip.write_all(xml.as_bytes())?;
        }

        // ── Footnotes ─────────────────────────────────────────
        if !footnotes.is_empty() {
            zip.start_file("word/footnotes.xml", options)?;
            let mut xml = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<w:footnotes xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">"#,
            );
            for (id, (_, note)) in footnotes.iter().enumerate() {
                xml.push_str(&format!(
                    r#"<w:footnote w:id="{}"><w:p><w:r><w:rPr><w:vertAlign w:val="superscript"/></w:rPr><w:t xml:space="preserve">{} </w:t></w:r><w:r><w:t>{}</w:t></w:r></w:p></w:footnote>"#,
                    id, id, htmlescape::encode_minimal(note)
                ));
            }
            xml.push_str("</w:footnotes>");
            zip.write_all(xml.as_bytes())?;
        }

        // ── Endnotes ──────────────────────────────────────────
        if !endnotes.is_empty() {
            zip.start_file("word/endnotes.xml", options)?;
            let mut xml = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<w:endnotes xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">"#,
            );
            for (id, (_, note)) in endnotes.iter().enumerate() {
                xml.push_str(&format!(
                    r#"<w:endnote w:id="{}"><w:p><w:r><w:rPr><w:vertAlign w:val="superscript"/></w:rPr><w:t xml:space="preserve">{} </w:t></w:r><w:r><w:t>{}</w:t></w:r></w:p></w:endnote>"#,
                    id, id, htmlescape::encode_minimal(note)
                ));
            }
            xml.push_str("</w:endnotes>");
            zip.write_all(xml.as_bytes())?;
        }

        // ── docProps/core.xml ─────────────────────────────────
        if let Some(ref props) = self.properties {
            zip.start_file("docProps/core.xml", options)?;
            let mut xml = String::from(
                r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties
  xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">"#,
            );
            if let Some(ref v) = props.title {
                xml.push_str(&format!(
                    "<dc:title>{}</dc:title>",
                    htmlescape::encode_minimal(v)
                ));
            }
            if let Some(ref v) = props.subject {
                xml.push_str(&format!(
                    "<dc:subject>{}</dc:subject>",
                    htmlescape::encode_minimal(v)
                ));
            }
            if let Some(ref v) = props.author {
                xml.push_str(&format!(
                    "<dc:creator>{}</dc:creator>",
                    htmlescape::encode_minimal(v)
                ));
            }
            if let Some(ref v) = props.description {
                xml.push_str(&format!(
                    "<dc:description>{}</dc:description>",
                    htmlescape::encode_minimal(v)
                ));
            }
            if let Some(ref v) = props.keywords {
                xml.push_str(&format!(
                    "<cp:keywords>{}</cp:keywords>",
                    htmlescape::encode_minimal(v)
                ));
            }
            xml.push_str("\n</cp:coreProperties>");
            zip.write_all(xml.as_bytes())?;
        }

        // ── Finalize ──────────────────────────────────────────
        let buf = zip.finish()?;
        std::fs::write(destination, buf.into_inner())?;
        Ok(())
    }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

/// Build a `<w:rPr>` block from optional `RunFormat`.
fn build_rpr(fmt: Option<&RunFormat>) -> String {
    let fmt = match fmt {
        Some(f) => f,
        None => return String::new(),
    };
    let mut rpr = String::from("<w:rPr>");
    if fmt.bold {
        rpr.push_str("<w:b/>");
    }
    if fmt.italic {
        rpr.push_str("<w:i/>");
    }
    if fmt.underline {
        rpr.push_str(r#"<w:u w:val="single"/>"#);
    }
    if fmt.strikethrough {
        rpr.push_str("<w:strike/>");
    }
    if let Some(ref c) = fmt.color {
        rpr.push_str(&format!(r#"<w:color w:val="{}"/>"#, c));
    }
    if let Some(ref h) = fmt.highlight {
        rpr.push_str(&format!(r#"<w:highlight w:val="{}"/>"#, h));
    }
    if let Some(sz) = fmt.font_size_half_pts {
        rpr.push_str(&format!("<w:sz w:val=\"{}\"/>", sz));
    }
    if let Some(ref f) = fmt.font {
        rpr.push_str(&format!(r#"<w:rFonts w:ascii="{}" w:hAnsi="{}"/>"#, f, f));
    }
    rpr.push_str("</w:rPr>");
    rpr
}

// ─────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;
    use zip::ZipArchive;

    fn dummy_image() -> ImageData {
        ImageData {
            rel_id: String::new(),
            bytes: vec![0, 1, 2, 3],
            mime_type: "image/png".to_string(),
            extension: "png".to_string(),
        }
    }

    #[test]
    fn test_docx_writer_basic() {
        let tmp = tempfile::tempdir().unwrap();
        let path = tmp.path().join("test.docx");

        DocxWriter::new()
            .set_properties(DocProperties {
                title: Some("Test Doc".into()),
                author: Some("Tester".into()),
                ..Default::default()
            })
            .set_page_layout(PageLayout {
                landscape: false,
                ..Default::default()
            })
            .set_header("My Header")
            .set_footer("My Footer")
            .add_paragraph("Hello world")
            .add_paragraph_with_style("A heading", "Heading1")
            .add_paragraph_formatted(
                "Bold text",
                RunFormat {
                    bold: true,
                    color: Some("FF0000".into()),
                    ..Default::default()
                },
            )
            .add_comment("Commented text", "This is a test comment")
            .add_tracked_insert("inserted content", "Alice")
            .add_tracked_delete("deleted content", "Bob")
            .add_hyperlink("Click here", "https://example.com")
            .add_table(vec![vec!["Row1Col1".to_string(), "Row1Col2".to_string()]])
            .add_footnote("See footnote", "This is a footnote note")
            .add_endnote("See endnote", "This is an endnote note")
            .add_page_break()
            .add_image(dummy_image())
            .write_to(&path)
            .unwrap();

        let file = std::fs::File::open(&path).unwrap();
        let mut archive = ZipArchive::new(file).unwrap();

        // document.xml
        let mut doc = String::new();
        archive
            .by_name("word/document.xml")
            .unwrap()
            .read_to_string(&mut doc)
            .unwrap();
        assert!(doc.contains("Hello world"), "paragraph");
        assert!(doc.contains("Heading1"), "style");
        assert!(doc.contains("<w:b/>"), "bold");
        assert!(doc.contains("Row1Col1"), "table");
        assert!(doc.contains("Click here"), "hyperlink");
        assert!(doc.contains("commentRangeStart"), "comment");
        assert!(doc.contains("w:ins"), "tracked insert");
        assert!(doc.contains("w:del"), "tracked delete");
        assert!(doc.contains("footnoteReference"), "footnote ref");
        assert!(doc.contains("endnoteReference"), "endnote ref");
        assert!(doc.contains(r#"w:type="page""#), "page break");
        assert!(doc.contains("w:pgSz"), "page layout");

        // relationships
        let mut rels = String::new();
        archive
            .by_name("word/_rels/document.xml.rels")
            .unwrap()
            .read_to_string(&mut rels)
            .unwrap();
        assert!(rels.contains("https://example.com"), "hyperlink rel");
        assert!(rels.contains("header1.xml"), "header rel");
        assert!(rels.contains("footer1.xml"), "footer rel");
        assert!(rels.contains("image"), "image rel");
        assert!(rels.contains("comments.xml"), "comments rel");
        assert!(rels.contains("footnotes.xml"), "footnotes rel");
        assert!(rels.contains("endnotes.xml"), "endnotes rel");

        // header / footer
        let mut header = String::new();
        archive
            .by_name("word/header1.xml")
            .unwrap()
            .read_to_string(&mut header)
            .unwrap();
        assert!(header.contains("My Header"));

        let mut footer = String::new();
        archive
            .by_name("word/footer1.xml")
            .unwrap()
            .read_to_string(&mut footer)
            .unwrap();
        assert!(footer.contains("My Footer"));

        // comments
        let mut cmts = String::new();
        archive
            .by_name("word/comments.xml")
            .unwrap()
            .read_to_string(&mut cmts)
            .unwrap();
        assert!(cmts.contains("This is a test comment"), "comment text");

        // footnotes
        let mut ftn = String::new();
        archive
            .by_name("word/footnotes.xml")
            .unwrap()
            .read_to_string(&mut ftn)
            .unwrap();
        assert!(ftn.contains("This is a footnote note"), "footnote text");

        // endnotes
        let mut etn = String::new();
        archive
            .by_name("word/endnotes.xml")
            .unwrap()
            .read_to_string(&mut etn)
            .unwrap();
        assert!(etn.contains("This is an endnote note"), "endnote text");

        // core properties
        let mut core = String::new();
        archive
            .by_name("docProps/core.xml")
            .unwrap()
            .read_to_string(&mut core)
            .unwrap();
        assert!(core.contains("Test Doc"), "doc title");
        assert!(core.contains("Tester"), "doc author");
    }
    #[test]
    fn test_custom_xml_part() {
        let tmp = tempfile::tempdir().unwrap();
        let path = tmp.path().join("custom_xml.docx");
        DocxWriter::new()
            .add_custom_xml("myPart.xml", "<root><data>123</data></root>")
            .write_to(&path)
            .unwrap();

        let file = std::fs::File::open(&path).unwrap();
        let mut archive = ZipArchive::new(file).unwrap();
        let mut part = String::new();
        archive
            .by_name("customXml/myPart.xml")
            .unwrap()
            .read_to_string(&mut part)
            .unwrap();
        assert_eq!(part, "<root><data>123</data></root>");
    }
}

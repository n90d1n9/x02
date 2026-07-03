//! `PdfDocument` — the main public API.

use lopdf::Document;
use std::path::Path;

use crate::{
    annotator, diff, editor,
    error::{Error, Result},
    exporter::{export, ExportFormat},
    extractor, image_decoder,
    models::{
        Annotation, BookmarkNode, DecodedImage, ExtractionResult, FormField, ImageInfo, Metadata,
        PageDiff, PageText, RichSpan, SearchHit, TextTable,
    },
    rich_text, search, table_extractor,
};

/// The central entry point for all PDF operations.
pub struct PdfDocument {
    pub(crate) inner: Document,
}

impl PdfDocument {
    // ── Constructors ──────────────────────────────────────────────────────────

    /// Open a PDF from a filesystem path.
    pub fn open<P: AsRef<Path>>(path: P) -> Result<Self> {
        Ok(PdfDocument {
            inner: Document::load(path)?,
        })
    }

    /// Open a password-protected PDF.
    pub fn open_with_password<P: AsRef<Path>>(path: P, password: &str) -> Result<Self> {
        let mut doc = Document::load(path)?;
        if doc.is_encrypted() {
            doc.decrypt(password).map_err(|_| Error::WrongPassword)?;
        }
        Ok(PdfDocument { inner: doc })
    }

    /// Parse a PDF from an in-memory byte slice.
    pub fn from_bytes(bytes: &[u8]) -> Result<Self> {
        Ok(PdfDocument {
            inner: Document::load_mem(bytes)?,
        })
    }

    /// Parse a password-protected PDF from bytes.
    pub fn from_bytes_with_password(bytes: &[u8], password: &str) -> Result<Self> {
        let mut doc = Document::load_mem(bytes)?;
        if doc.is_encrypted() {
            doc.decrypt(password).map_err(|_| Error::WrongPassword)?;
        }
        Ok(PdfDocument { inner: doc })
    }

    // ── Document info ─────────────────────────────────────────────────────────

    pub fn is_encrypted(&self) -> bool {
        self.inner.is_encrypted()
    }
    pub fn page_count(&self) -> usize {
        self.inner.get_pages().len()
    }

    // ── Metadata ──────────────────────────────────────────────────────────────

    /// Extract document metadata.
    pub fn metadata(&self) -> Result<Metadata> {
        extractor::extract_metadata(&self.inner)
    }

    // ── Plain text ────────────────────────────────────────────────────────────

    /// All text, pages joined by `\n\n`.
    pub fn extract_text_all(&self) -> Result<String> {
        let pages = extractor::extract_all_text(&self.inner)?;
        Ok(pages
            .iter()
            .map(|p| p.text.as_str())
            .collect::<Vec<_>>()
            .join("\n\n"))
    }

    /// Per-page text with statistics.
    pub fn extract_pages(&self) -> Result<Vec<PageText>> {
        extractor::extract_all_text(&self.inner)
    }

    /// Single page text (0-based index).
    pub fn extract_page_text(&self, page_index: usize) -> Result<String> {
        let pages = self.inner.get_pages();
        let total = pages.len();
        let page_id = pages
            .get(&((page_index + 1) as u32))
            .copied()
            .ok_or(Error::PageOutOfRange(page_index, total))?;
        extractor::extract_page_text(&self.inner, page_id)
    }

    /// Slice of pages (inclusive, 0-based).
    pub fn extract_page_range(&self, from: usize, to: usize) -> Result<Vec<PageText>> {
        let all = extractor::extract_all_text(&self.inner)?;
        let total = all.len();
        if from >= total || to >= total {
            return Err(Error::PageOutOfRange(to, total));
        }
        Ok(all
            .into_iter()
            .filter(|p| p.page_index >= from && p.page_index <= to)
            .collect())
    }

    // ── Rich text ─────────────────────────────────────────────────────────────

    /// Extract styled text spans from all pages.
    ///
    /// Each [`RichSpan`] carries font name, size, colour, bold/italic flag,
    /// and approximate (x, y) position.
    ///
    /// ```rust,no_run
    /// let doc = rustpdf::PdfDocument::open("file.pdf").unwrap();
    /// for span in doc.extract_rich_text().unwrap() {
    ///     println!("{} {}pt bold={} \"{}\"",
    ///         span.base_font.as_deref().unwrap_or("?"),
    ///         span.font_size, span.bold, span.text);
    /// }
    /// ```
    pub fn extract_rich_text(&self) -> Result<Vec<RichSpan>> {
        rich_text::extract_rich_text_all(&self.inner)
    }

    /// Styled text spans for a single page (0-based).
    pub fn extract_rich_text_page(&self, page_index: usize) -> Result<Vec<RichSpan>> {
        let pages = self.inner.get_pages();
        let total = pages.len();
        let page_id = pages
            .get(&((page_index + 1) as u32))
            .copied()
            .ok_or(Error::PageOutOfRange(page_index, total))?;
        rich_text::extract_rich_text_page(&self.inner, page_id, page_index)
    }

    // ── Images ────────────────────────────────────────────────────────────────

    /// Extract raw image info from all pages.
    pub fn extract_images(&self) -> Result<Vec<ImageInfo>> {
        extractor::extract_images(&self.inner)
    }

    /// Extract images from a single page (0-based).
    pub fn extract_images_from_page(&self, page_index: usize) -> Result<Vec<ImageInfo>> {
        let total = self.page_count();
        if page_index >= total {
            return Err(Error::PageOutOfRange(page_index, total));
        }
        Ok(extractor::extract_images(&self.inner)?
            .into_iter()
            .filter(|img| img.page_index == page_index)
            .collect())
    }

    /// Decode all images, converting each to a proper PNG or JPEG byte payload
    /// with a ready-to-use `data_url` string.
    ///
    /// ```rust,no_run
    /// let doc = rustpdf::PdfDocument::open("file.pdf").unwrap();
    /// for img in doc.decode_images().unwrap() {
    ///     println!("{}", img.data_url); // "data:image/png;base64,..."
    ///     std::fs::write(format!("img_{}.png", img.info.image_index), &img.encoded_bytes).unwrap();
    /// }
    /// ```
    pub fn decode_images(&self) -> Result<Vec<DecodedImage>> {
        extractor::extract_images(&self.inner)?
            .into_iter()
            .map(|info| image_decoder::decode_image(&info))
            .collect()
    }

    /// Decode images on a single page (0-based).
    pub fn decode_images_from_page(&self, page_index: usize) -> Result<Vec<DecodedImage>> {
        self.extract_images_from_page(page_index)?
            .into_iter()
            .map(|info| image_decoder::decode_image(&info))
            .collect()
    }

    // ── Bookmarks ─────────────────────────────────────────────────────────────

    pub fn extract_bookmarks(&self) -> Result<Vec<BookmarkNode>> {
        extractor::extract_bookmarks(&self.inner)
    }

    // ── Form fields ───────────────────────────────────────────────────────────

    pub fn extract_form_fields(&self) -> Result<Vec<FormField>> {
        extractor::extract_form_fields(&self.inner)
    }

    // ── Annotations ───────────────────────────────────────────────────────────

    /// Extract all annotations (comments, highlights, links, stamps, …).
    pub fn extract_annotations(&self) -> Result<Vec<Annotation>> {
        annotator::extract_annotations(&self.inner)
    }

    /// Add a text (sticky-note) annotation.
    pub fn add_text_annotation(
        &mut self,
        page_index: usize,
        rect: [f64; 4],
        author: &str,
        contents: &str,
    ) -> Result<()> {
        annotator::add_text_annotation(&mut self.inner, page_index, rect, author, contents)
    }

    /// Add a web-link annotation.
    pub fn add_link_annotation(
        &mut self,
        page_index: usize,
        rect: [f64; 4],
        uri: &str,
    ) -> Result<()> {
        annotator::add_link_annotation(&mut self.inner, page_index, rect, uri)
    }

    /// Add a highlight annotation.
    pub fn add_highlight_annotation(
        &mut self,
        page_index: usize,
        rect: [f64; 4],
        color: [f64; 3],
        author: &str,
    ) -> Result<()> {
        annotator::add_highlight_annotation(&mut self.inner, page_index, rect, color, author)
    }

    // ── Tables ────────────────────────────────────────────────────────────────

    /// Detect tabular content via heuristic Y/X clustering of rich text spans.
    pub fn extract_tables(&self) -> Result<Vec<TextTable>> {
        let spans = rich_text::extract_rich_text_all(&self.inner)?;
        Ok(table_extractor::detect_tables(&spans, self.page_count()))
    }

    // ── Search ────────────────────────────────────────────────────────────────

    /// Case-insensitive full-text search.  
    /// Returns one [`SearchHit`] per occurrence with surrounding context.
    ///
    /// ```rust,no_run
    /// let doc = rustpdf::PdfDocument::open("file.pdf").unwrap();
    /// for hit in doc.search("invoice").unwrap() {
    ///     println!("p.{}: {}", hit.page_number, hit.context);
    /// }
    /// ```
    pub fn search(&self, query: &str) -> Result<Vec<SearchHit>> {
        let pages = extractor::extract_all_text(&self.inner)?;
        search::search_text(&pages, query)
    }

    /// Regex search across all pages.
    pub fn search_regex(&self, pattern: &str) -> Result<Vec<SearchHit>> {
        let pages = extractor::extract_all_text(&self.inner)?;
        search::search_regex(&pages, pattern)
    }

    // ── All-in-one ────────────────────────────────────────────────────────────

    /// Full extraction: metadata + text + bookmarks + forms + images + annotations + tables.
    pub fn extract_all(&self) -> Result<ExtractionResult> {
        let metadata = extractor::extract_metadata(&self.inner)?;
        let pages = extractor::extract_all_text(&self.inner)?;
        let bookmarks = extractor::extract_bookmarks(&self.inner).unwrap_or_default();
        let form_fields = extractor::extract_form_fields(&self.inner).unwrap_or_default();
        let images = extractor::extract_images(&self.inner).unwrap_or_default();
        let annotations = annotator::extract_annotations(&self.inner).unwrap_or_default();
        let spans = rich_text::extract_rich_text_all(&self.inner).unwrap_or_default();
        let tables = table_extractor::detect_tables(&spans, pages.len());
        Ok(ExtractionResult::build(
            metadata,
            pages,
            bookmarks,
            form_fields,
            images,
            annotations,
            tables,
        ))
    }

    // ── Editing ───────────────────────────────────────────────────────────────

    /// Remove a page (0-based).
    pub fn remove_page(&mut self, page_index: usize) -> Result<()> {
        editor::remove_page(&mut self.inner, page_index)
    }

    /// Rotate a page by 0/90/180/270 degrees.
    pub fn rotate_page(&mut self, page_index: usize, degrees: i64) -> Result<()> {
        editor::rotate_page(&mut self.inner, page_index, degrees)
    }

    /// Reorder all pages according to `new_order` (0-based indices).
    pub fn reorder_pages(&mut self, new_order: &[usize]) -> Result<()> {
        editor::reorder_pages(&mut self.inner, new_order)
    }

    /// Extract a page range into a new `PdfDocument`.
    pub fn extract_document_range(&self, from: usize, to: usize) -> Result<PdfDocument> {
        Ok(PdfDocument {
            inner: editor::extract_page_range(&self.inner, from, to)?,
        })
    }

    /// Merge another `PdfDocument` into this one (appends pages).
    pub fn merge(&mut self, other: &PdfDocument) -> Result<()> {
        editor::merge_documents(&mut self.inner, &other.inner)
    }

    /// Stamp diagonal text watermark on every page.
    ///
    /// `font_size` defaults to 48.0; `opacity` 0.0–1.0 defaults to 0.3.
    ///
    /// ```rust,no_run
    /// let mut doc = rustpdf::PdfDocument::open("report.pdf").unwrap();
    /// doc.watermark_text("CONFIDENTIAL", None, Some(0.25)).unwrap();
    /// doc.save("report_wm.pdf").unwrap();
    /// ```
    pub fn watermark_text(
        &mut self,
        text: &str,
        font_size: Option<f64>,
        opacity: Option<f64>,
    ) -> Result<()> {
        editor::watermark_text(&mut self.inner, text, font_size, opacity)
    }

    /// Inject a single line of text onto a page at (x, y) from bottom-left.
    pub fn inject_text(
        &mut self,
        page_index: usize,
        text: &str,
        x: f64,
        y: f64,
        font_size: f64,
    ) -> Result<()> {
        editor::inject_text(&mut self.inner, page_index, text, x, y, font_size)
    }

    /// Update document metadata fields (pass `None` to leave unchanged).
    pub fn update_metadata(
        &mut self,
        title: Option<&str>,
        author: Option<&str>,
        subject: Option<&str>,
        keywords: Option<&str>,
        creator: Option<&str>,
    ) -> Result<()> {
        editor::update_metadata(&mut self.inner, title, author, subject, keywords, creator)
    }

    /// Set an AcroForm field value by fully-qualified name.
    pub fn set_field_value(&mut self, field_name: &str, value: &str) -> Result<()> {
        editor::set_field_value(&mut self.inner, field_name, value)
    }

    // ── Diff ──────────────────────────────────────────────────────────────────

    /// Compare this document with another, returning per-page text diffs.
    pub fn diff(&self, other: &PdfDocument) -> Result<Vec<PageDiff>> {
        diff::diff_documents(&self.inner, &other.inner)
    }

    /// Returns `true` if both documents are textually identical on every page.
    pub fn is_identical_to(&self, other: &PdfDocument) -> Result<bool> {
        diff::are_identical(&self.inner, &other.inner)
    }

    // ── Export ────────────────────────────────────────────────────────────────

    /// Extract everything and export in the requested format.
    ///
    /// | `ExportFormat`  | Output                                    |
    /// |-----------------|-------------------------------------------|
    /// | `Json`          | Full structured JSON (images as base64)   |
    /// | `PlainText`     | Human-readable plain text                 |
    /// | `Markdown`      | Markdown with metadata table              |
    /// | `Html`          | Self-contained HTML page                  |
    /// | `Csv`           | CSV — one row per page                    |
    pub fn export(&self, format: ExportFormat) -> Result<String> {
        let result = self.extract_all()?;
        export(&result, format)
    }

    /// Export a pre-built [`ExtractionResult`] (avoids re-extracting).
    pub fn export_result(result: &ExtractionResult, format: ExportFormat) -> Result<String> {
        export(result, format)
    }

    // ── Persistence ───────────────────────────────────────────────────────────

    /// Save the (possibly edited) document to a file.
    ///
    /// ```rust,no_run
    /// let mut doc = rustpdf::PdfDocument::open("in.pdf").unwrap();
    /// doc.watermark_text("DRAFT", None, None).unwrap();
    /// doc.save("out.pdf").unwrap();
    /// ```
    pub fn save<P: AsRef<Path>>(&mut self, path: P) -> Result<()> {
        self.inner.save(path).map(|_| ()).map_err(|e| Error::Io(e))
    }

    /// Serialize the document to bytes (useful for in-memory pipelines).
    pub fn to_bytes(&mut self) -> Result<Vec<u8>> {
        let mut buf = Vec::new();
        self.inner.save_to(&mut buf).map_err(Error::Io)?;
        Ok(buf)
    }
}

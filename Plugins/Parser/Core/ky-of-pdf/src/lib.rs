//! # rustpdf v0.2
//!
//! A complete PDF **reader**, **extractor**, **exporter**, and **editor** library for Rust.
//!
//! ## What's new in v0.2
//! - **Rich text** extraction with font name, size, colour, bold/italic per span
//! - **Image decoding**: JPEG, PNG (Flate+predictor), raw RGB/Gray → PNG bytes
//! - **Full-text search** with page and byte-offset results
//! - **Table detection** via heuristic bounding-box clustering
//! - **Document editing**: add / remove / rotate / reorder pages
//! - **Watermarks**: stamp text or image onto every page
//! - **Annotations**: read and write comments, highlights, web-links
//! - **Metadata editing**: update title, author, dates, keywords
//! - **Form fill**: set AcroForm field values and flatten
//! - **Merge / split / extract page ranges** into new documents
//! - **Diff**: compare two PDFs page-by-page and report differences
//!
//! ## Quick start
//!
//! ```rust,no_run
//! use rustpdf::{PdfDocument, ExportFormat};
//!
//! fn main() -> rustpdf::Result<()> {
//!     let mut doc = PdfDocument::open("report.pdf")?;
//!
//!     // Rich text
//!     for span in doc.extract_rich_text_page(0)? {
//!         println!("{:?} {}pt  \"{}\"", span.font_name, span.font_size, span.text);
//!     }
//!
//!     // Search
//!     for hit in doc.search("invoice")? {
//!         println!("p.{} offset {}", hit.page_number, hit.char_offset);
//!     }
//!
//!     // Edit: stamp watermark then save
//!     doc.watermark_text("CONFIDENTIAL", None, None)?;
//!     doc.save("report_wm.pdf")?;
//!
//!     // Export
//!     std::fs::write("report.html", doc.export(ExportFormat::Html)?)?;
//!     Ok(())
//! }
//! ```

pub mod annotator;
pub mod diff;
pub mod document;
pub mod editor;
pub mod error;
pub mod exporter;
pub mod extractor;
pub mod image_decoder;
pub mod models;
pub mod rich_text;
pub mod search;
pub mod table_extractor;

pub use document::PdfDocument;
pub use error::{Error, Result};
pub use exporter::ExportFormat;
pub use models::{
    Annotation, AnnotationKind, BookmarkNode, DecodedImage, ExtractionResult, FieldType, FormField,
    ImageFormat, ImageInfo, Metadata, PageDiff, PageText, RichSpan, SearchHit, TableCell, TableRow,
    TextTable,
};

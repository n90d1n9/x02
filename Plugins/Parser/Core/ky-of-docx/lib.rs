//! # docx_reader
//!
//! A comprehensive, ergonomic library for reading and extracting content from `.docx` files.
//!
//! ## Features
//!
//! - **Text extraction** – plain text, with optional paragraph/run granularity  
//! - **Rich structure** – headings, paragraphs, lists, tables, hyperlinks, footnotes  
//! - **Metadata** – core properties (author, title, dates, keywords, …)  
//! - **Images** – enumerate and export embedded images  
//! - **Styles** – paragraph and character style names  
//! - **Tracked changes** – insertions and deletions with author/date  
//! - **Comments** – comment text with author, date and anchor range  
//! - **Headers & footers** – per-section  
//!
//! ## Quick start
//!
//! ```no_run
//! use docx_reader::DocxReader;
//!
//! let doc = DocxReader::open("my_document.docx").unwrap();
//! println!("{}", doc.extract_text().unwrap());
//! ```

#[path = "src/charts.rs"]
pub mod charts;
#[path = "src/diagrams.rs"]
pub mod diagrams;
#[path = "src/embeddings.rs"]
pub mod embeddings;
pub mod error;
pub mod extractor;
pub mod image;
pub mod models;
pub mod parser;
pub mod writer;

pub use charts::Chart;
pub use diagrams::Diagram;
pub use embeddings::EmbeddedObject;
pub use error::{DocxError, Result};
pub use extractor::DocxReader;
pub use models::*;
pub use writer::DocxWriter;

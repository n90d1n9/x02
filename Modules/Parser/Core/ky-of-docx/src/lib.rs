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

pub mod error;
pub mod models;
pub mod parser;
pub mod extractor;
pub mod metadata;
pub mod image;
pub mod styles;

pub use error::{DocxError, Result};
pub use models::*;
pub use extractor::DocxReader;

pub use crate::extractor::*;
pub use crate::models::*;
pub use crate::parser::*;

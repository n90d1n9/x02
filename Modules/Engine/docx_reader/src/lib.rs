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
//! 
//! 

pub mod error;
pub mod models;
pub mod parser;
pub mod extractor;
pub mod metadata;
pub mod image;
pub mod styles;

pub use waraq_core::core;

pub mod block;
pub mod document;
pub mod ops;
pub mod selection;
pub mod session;

pub use block::{Block, BlockType, InlineStyle};
pub use document::Document;
pub use ops::{
    apply_document_edit, apply_document_operation, document_operation, document_snapshot,
    DocumentEdit, DocumentEditOutcome, DocumentOperation, DocumentOperationLog, DocumentSnapshot,
    DocumentTransaction, DOCUMENT_ENGINE_ID,
};
pub use selection::{DocumentSelection, DocumentTextSelection};
pub use session::{document_session, DocumentSession};


pub use error::{DocxError, Result};
pub use models::*;
pub use extractor::DocxReader;

pub use crate::extractor::*;
pub use crate::models::*;
pub use crate::parser::*;

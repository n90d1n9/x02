//! # docx_reader
//!
//! A comprehensive document engine for reading, editing, and writing `.docx` files.
//!
//! ## Architecture
//!
//! This library provides a complete document processing pipeline:
//!
//! ### Core Components
//! - **Parser**: Extract content from existing .docx files
//! - **Models**: Rich data structures representing DOCX elements
//! - **Tree Engine**: Arena-based document representation for MS Word-like editing
//! - **Transactions**: Operational transformation for edits
//! - **Commands**: High-level editing operations
//!
//! ### Features
//! - Text extraction with paragraph/run granularity
//! - Rich structure: headings, paragraphs, lists, tables, hyperlinks, footnotes
//! - Metadata: core properties (author, title, dates, keywords)
//! - Images: enumerate and export embedded images
//! - Styles: paragraph and character style names
//! - Tracked changes: insertions and deletions with author/date
//! - Comments: comment text with author, date and anchor range
//! - Headers & footers: per-section
//!
//! ## Quick start
//!
//! ```no_run
//! // Parse an existing DOCX file
//! use docx_reader::DocxReader;
//!
//! let reader = DocxReader::open("my_document.docx").unwrap();
//! let doc = reader.parse().unwrap();
//! println!("{}", doc.extract_text());
//!
//! // Create and edit a document using the tree engine
//! use docx_reader::{Tree, Op, apply_transaction};
//!
//! let mut tree = Tree::new_empty();
//! let ops = vec![Op::InsertText { 
//!     node: tree.root, 
//!     offset: 0, 
//!     text: "Hello".to_string() 
//! }];
//! apply_transaction(&mut tree, &ops).unwrap();
//! ```

// Error types
pub mod error;
pub use error::{DocxError, Result};

// Document models
pub mod alignment;
pub mod block;
pub mod comments;
pub mod document;
pub mod embeddings;
pub mod footnotes;
pub mod headers_footers;
pub mod images;
pub mod list;
pub mod paragraph;
pub mod run;
pub mod styles;
pub mod table;
pub mod tracked_changes;

// Re-export model types
pub use alignment::Alignment;
pub use block::Block;
pub use comments::Comment;
pub use document::Document;
pub use embeddings::Embedding;
pub use footnotes::{Footnote, Endnote};
pub use headers_footers::SectionHeaderFooter;
pub use images::{ImageRef, ImageData};
pub use list::ListType;
pub use paragraph::Paragraph;
pub use run::{Run, RunProperties};
pub use styles::{StyleDef, StyleProperties};
pub use table::{Table, TableRow, TableCell};
pub use tracked_changes::TrackedChange;

// Extraction options
pub mod extraction_options;
pub use extraction_options::TextOptions;

// Core parsing and extraction
pub mod parser;
pub mod extractor;
pub use extractor::DocxReader;

// Tree engine (MS Word-like editing)
pub mod schema;
pub mod content_model;
pub mod tree;
pub mod transaction;
pub mod commands;
pub mod serialize;
pub mod agent;

// Re-export tree engine types
pub use schema::{AttrValue, BlockType as SchemaBlockType, Mark, MarkTag};
pub use content_model::{validate_child, ChildRef, SchemaViolation};
pub use tree::{DocError, DocResult, Node, NodeId, NodeKind, Tree};
pub use transaction::{apply_op, apply_transaction, NewNodeSpec, Op, OpOutcome, Transaction};
pub use commands::{apply_command, apply_commands, Command};

// Document editing
pub mod ops;
pub mod selection;
pub mod session;
pub mod writer;

// Re-export editing types
pub use ops::Op as EditOp;
pub use selection::Selection;
pub use session::Session;

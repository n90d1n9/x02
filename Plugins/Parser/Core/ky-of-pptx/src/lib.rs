//! # pptx_reader
//!
//! A comprehensive Rust library for reading and extracting content from PowerPoint (.pptx) files.
//!
//! ## Features
//! - Full slide content extraction (text, shapes, images, charts, tables)
//! - Rich text formatting (bold, italic, underline, colors, fonts, sizes)
//! - Animation extraction (entrance, exit, emphasis, motion paths)
//! - Embedded image extraction with metadata
//! - Chart data extraction (bar, line, pie, scatter, area, etc.)
//! - Table structure extraction
//! - Slide layout and master slide information
//! - Speaker notes extraction
//! - Slide transitions
//! - Hyperlinks and media references
//! - Presentation metadata (author, title, subject, keywords)
//!
//! ## Quick Start
//!
//! ```rust,no_run
//! use pptx_reader::PptxReader;
//!
//! fn main() -> Result<(), Box<dyn std::error::Error>> {
//!     let reader = PptxReader::open("presentation.pptx")?;
//!     let presentation = reader.extract()?;
//!
//!     println!("Title: {}", presentation.metadata.title.unwrap_or_default());
//!     println!("Slides: {}", presentation.slides.len());
//!
//!     for (i, slide) in presentation.slides.iter().enumerate() {
//!         println!("\n=== Slide {} ===", i + 1);
//!         for shape in &slide.shapes {
//!             if let Some(text) = &shape.text_frame {
//!                 println!("{}", text.plain_text());
//!             }
//!         }
//!     }
//!     Ok(())
//! }
//! ```

pub mod error;
pub mod models;
pub mod parsers;
pub mod extractors;

pub use error::{PptxError, Result};
pub use models::presentation::Presentation;
pub use models::slide::Slide;
pub use models::shape::{Shape, ShapeType};
pub use models::text::{TextFrame, Paragraph, Run, TextProperties};
pub use models::image::ImageData;
pub use models::chart::{Chart, ChartType, ChartSeries};
pub use models::table::{Table, TableRow, TableCell};
pub use models::animation::{Animation, AnimationEffect, AnimationTrigger};
pub use models::transition::SlideTransition;
pub use models::metadata::PresentationMetadata;
pub use models::color::Color;
pub use models::geometry::Geometry;
pub use extractors::PptxReader;

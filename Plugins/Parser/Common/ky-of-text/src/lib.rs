//! text module for Office Parser and Engine.

pub mod text;
pub mod format;
pub mod rich_text;
pub mod rich_text_extractor;

pub use text::{TextFrame, Paragraph, Run, ParagraphProperties};
pub use format::TextFormat;
pub use rich_text::RichText;

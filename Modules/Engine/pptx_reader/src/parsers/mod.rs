//! PPTX parsing modules

pub mod pptx_parser;
pub mod slide_parser;
pub mod shape_parser;
pub mod text_parser;
pub mod animation_parser;
pub mod transition_parser;
pub mod theme_parser;
pub mod chart_parser;
pub mod table_parser;
pub mod relationship_parser;
pub mod content_type_parser;

pub use pptx_parser::PptxParser;

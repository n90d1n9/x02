//! Common utilities for Office parser and engine crates.


pub mod hyperlink;
pub mod metadata;
pub mod numbering;

pub mod text;
pub mod format;
pub mod rich_text;
pub mod rich_text_extractor;

pub mod types;
pub mod models;
pub mod parser;

pub mod styles;
pub mod color;

pub mod header_footer;
pub mod footnote;
pub mod error;
pub mod comment;

pub mod draw_commands;
pub mod geometry;

pub use color::{Color, ThemeColor};
pub use styles::{Style, StylesCollection};

pub use comment::Comment;
pub use error::{PptxError, Result};
pub use header_footer::HeaderFooter;
pub use footnote::Footnote;
pub use types::shape_type::ShapeType;
pub use models::shape::{Shape, ShapeGeometry, ShapeText, ShapeFill, ShapeOutline};
pub use parser::xml_parser::{parse_shapes, parse_shape_from_string, ShapeParseError};


// Re-export main types for convenience
pub use types::table_type::{TableType, HeaderRowPosition, TableBorderStyle, BorderDef, BorderStyle};
pub use models::table::{
    Table, TableRow, TableCell, CellContent, TableDimensions, 
    TableStyle, RowStyle, CellStyle, CellMerge, BandingStyle,
    TextAlignment, HorizontalAlignment, VerticalAlignment,
    DataValidation, ValidationType, ValidationCriteria, CellBorders,
};
pub use parser::xml_parser::{TableParser, TableParseError};


pub use text::{TextFrame, Paragraph, Run, ParagraphProperties};
pub use format::TextFormat;
pub use rich_text::RichText;
//! Table module for Office Parser and Engine.
//! 
//! Provides comprehensive table data models, type definitions, and XML parsing capabilities
//! for handling tables in OOXML formats (DOCX, XLSX, PPTX).

pub mod types;
pub mod models;
pub mod parser;

// Re-export main types for convenience
pub use types::table_type::{TableType, HeaderRowPosition, TableBorderStyle, BorderDef, BorderStyle};
pub use models::table::{
    Table, TableRow, TableCell, CellContent, TableDimensions, 
    TableStyle, RowStyle, CellStyle, CellMerge, BandingStyle,
    TextAlignment, HorizontalAlignment, VerticalAlignment,
    DataValidation, ValidationType, ValidationCriteria, CellBorders,
};
pub use parser::xml_parser::{TableParser, TableParseError};

#[cfg(feature = "serde-support")]
pub use serde::{Deserialize, Serialize};

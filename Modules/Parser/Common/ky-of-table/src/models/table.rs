//! Core table data models representing rows, cells, and complete table structures.

use serde::{Deserialize, Serialize};
use crate::types::table_type::{TableType, HeaderRowPosition, TableBorderStyle};
use ky_of_text::RichText;
use ky_of_color::Color;

/// Represents a complete table structure.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Table {
    /// Unique identifier for the table
    pub id: String,
    /// Optional name of the table
    pub name: Option<String>,
    /// Type/style of the table
    #[serde(default)]
    pub table_type: TableType,
    /// Position of header row
    #[serde(default = "default_header_position")]
    pub header_position: HeaderRowPosition,
    /// Table dimensions
    pub dimensions: TableDimensions,
    /// All rows in the table
    pub rows: Vec<TableRow>,
    /// Styling information
    pub style: Option<TableStyle>,
    /// Alternative text for accessibility
    pub alt_text: Option<String>,
    /// Whether the table has a total row
    #[serde(default)]
    pub has_total_row: bool,
}

fn default_header_position() -> HeaderRowPosition {
    HeaderRowPosition::Top
}

/// Dimensions of the table.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct TableDimensions {
    pub row_count: usize,
    pub column_count: usize,
}

/// Represents a single row in a table.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TableRow {
    /// Row index (0-based)
    pub index: usize,
    /// Cells in this row
    pub cells: Vec<TableCell>,
    /// Row height in points (optional)
    pub height: Option<f32>,
    /// Whether this is a header row
    #[serde(default)]
    pub is_header: bool,
    /// Whether this is a total row
    #[serde(default)]
    pub is_total: bool,
    /// Row style overrides
    pub style: Option<RowStyle>,
}

/// Represents a single cell in a table.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TableCell {
    /// Column index (0-based)
    pub column_index: usize,
    /// Cell content
    pub content: CellContent,
    /// Cell merging info
    pub merge: Option<CellMerge>,
    /// Cell style overrides
    pub style: Option<CellStyle>,
    /// Data validation rules
    pub validation: Option<DataValidation>,
    /// Formula (for spreadsheet tables)
    pub formula: Option<String>,
}

/// Content of a table cell.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum CellContent {
    /// Empty cell
    Empty,
    /// Text content with formatting
    Text(RichText),
    /// Numeric value
    Number(f64),
    /// Date/time value
    DateTime(String), // ISO 8601 format
    /// Boolean value
    Boolean(bool),
    /// Error value
    Error(String),
}

impl Default for CellContent {
    fn default() -> Self {
        CellContent::Empty
    }
}

/// Cell merge information.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CellMerge {
    /// Number of rows to span
    pub row_span: usize,
    /// Number of columns to span
    pub column_span: usize,
}

/// Style information for a table.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TableStyle {
    /// Border styles
    pub borders: Option<TableBorderStyle>,
    /// Header row style
    pub header_style: Option<RowStyle>,
    /// Total row style
    pub total_style: Option<RowStyle>,
    /// Alternating row colors (banding)
    pub banding: Option<BandingStyle>,
    /// Background color
    pub background_color: Option<Color>,
}

/// Style information for a row.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RowStyle {
    /// Background color
    pub background_color: Option<Color>,
    /// Text alignment
    pub text_alignment: Option<TextAlignment>,
    /// Font properties (inherited from rich text usually)
    pub font_bold: Option<bool>,
    pub font_italic: Option<bool>,
}

/// Banding style for alternating rows/columns.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BandingStyle {
    /// Enable row banding
    #[serde(default)]
    pub row_banding: bool,
    /// Enable column banding
    #[serde(default)]
    pub column_banding: bool,
    /// First row color
    pub first_row_color: Option<Color>,
    /// Second row color
    pub second_row_color: Option<Color>,
}

/// Text alignment options.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TextAlignment {
    pub horizontal: HorizontalAlignment,
    pub vertical: VerticalAlignment,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum HorizontalAlignment {
    Left,
    Center,
    Right,
    Justify,
    Distribute,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum VerticalAlignment {
    Top,
    Center,
    Bottom,
    Justify,
    Distribute,
}

/// Cell style overrides.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CellStyle {
    /// Background color
    pub background_color: Option<Color>,
    /// Text alignment
    pub text_alignment: Option<TextAlignment>,
    /// Border overrides
    pub borders: Option<CellBorders>,
    /// Number format (for numeric cells)
    pub number_format: Option<String>,
}

/// Individual cell border definitions.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CellBorders {
    pub top: Option<BorderDef>,
    pub bottom: Option<BorderDef>,
    pub left: Option<BorderDef>,
    pub right: Option<BorderDef>,
}

use crate::types::table_type::BorderDef;

/// Data validation rules for a cell.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataValidation {
    /// Type of validation
    pub validation_type: ValidationType,
    /// Validation criteria
    pub criteria: ValidationCriteria,
    /// Error message to display on invalid input
    pub error_message: Option<String>,
    /// Input message to guide user
    pub input_message: Option<String>,
    /// Whether to show error alert
    #[serde(default)]
    pub show_error: bool,
    /// Whether to show input message
    #[serde(default)]
    pub show_input: bool,
}

/// Types of data validation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ValidationType {
    None,
    WholeNumber,
    Decimal,
    List,
    Date,
    Time,
    TextLength,
    Custom,
}

/// Validation criteria based on type.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum ValidationCriteria {
    /// For list validation: allowed values
    ListValues(Vec<String>),
    /// For range validations: min/max values
    Range {
        min: Option<String>,
        max: Option<String>,
    },
    /// For custom formula validation
    Formula(String),
}

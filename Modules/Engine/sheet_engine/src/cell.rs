use serde::{Deserialize, Serialize};

/// Represents the possible values that can be stored in a spreadsheet cell.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum CellValue {
    Empty,
    Number(f64),
    String(String),
    Boolean(bool),
    Error(String),
}

/// Cell formatting options for visual presentation.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CellFormat {
    pub bold: bool,
    pub italic: bool,
    pub background_color: Option<String>,
    pub text_color: Option<String>,
    pub number_format: Option<String>, // e.g., "0.00", "$#,##0.00"
}

impl Default for CellFormat {
    fn default() -> Self {
        Self {
            bold: false,
            italic: false,
            background_color: None,
            text_color: None,
            number_format: None,
        }
    }
}

/// A single cell in the spreadsheet grid.
/// 
/// Contains both the raw content (as entered by the user) and the evaluated value
/// (the result after formula evaluation). Also includes formatting information.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Cell {
    pub raw_content: String, // e.g., "=A1+B1" or "123"
    pub evaluated_value: CellValue,
    pub format: CellFormat,
}

impl Default for Cell {
    fn default() -> Self {
        Self {
            raw_content: String::new(),
            evaluated_value: CellValue::Empty,
            format: CellFormat::default(),
        }
    }
}

impl Cell {
    pub fn new(content: impl Into<String>) -> Self {
        Self {
            raw_content: content.into(),
            evaluated_value: CellValue::Empty, // Needs evaluation
            format: CellFormat::default(),
        }
    }

    pub fn is_formula(&self) -> bool {
        self.raw_content.starts_with('=')
    }
}

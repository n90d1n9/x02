//! Table model - embedded tables

use serde::{Deserialize, Serialize};

/// Table - embedded table in a slide
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Table {
    /// Unique identifier
    pub id: String,
    /// Number of rows
    pub row_count: usize,
    /// Number of columns
    pub column_count: usize,
    /// Table rows
    pub rows: Vec<TableRow>,
    /// Has header row
    pub has_header_row: bool,
    /// Has banded rows
    pub has_banded_rows: bool,
    /// Has first column special formatting
    pub has_first_column: bool,
}

impl Table {
    pub fn new(id: &str, rows: usize, cols: usize) -> Self {
        let mut table = Self {
            id: id.to_string(),
            row_count: rows,
            column_count: cols,
            rows: Vec::with_capacity(rows),
            has_header_row: true,
            has_banded_rows: false,
            has_first_column: false,
        };
        
        // Initialize empty rows
        for _ in 0..rows {
            table.rows.push(TableRow::new(cols));
        }
        
        table
    }
    
    pub fn get_cell(&self, row: usize, col: usize) -> Option<&TableCell> {
        self.rows.get(row).and_then(|r| r.cells.get(col))
    }
    
    pub fn get_cell_mut(&mut self, row: usize, col: usize) -> Option<&mut TableCell> {
        self.rows.get_mut(row).and_then(|r| r.cells.get_mut(col))
    }
}

/// Table Row
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TableRow {
    /// Cells in the row
    pub cells: Vec<TableCell>,
    /// Row height
    pub height: Option<f64>,
    /// Row style
    pub style: Option<RowStyle>,
}

impl TableRow {
    pub fn new(col_count: usize) -> Self {
        Self {
            cells: (0..col_count).map(|_| TableCell::default()).collect(),
            height: None,
            style: None,
        }
    }
}

/// Table Cell
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TableCell {
    /// Cell content (text)
    pub content: String,
    /// Column span
    pub colspan: usize,
    /// Row span
    pub rowspan: usize,
    /// Horizontal alignment
    pub horizontal_align: HorizontalAlignment,
    /// Vertical alignment
    pub vertical_align: VerticalAlignment,
    /// Cell borders
    pub borders: CellBorders,
    /// Background color
    pub background_color: Option<String>,
}

impl TableCell {
    pub fn with_content(content: &str) -> Self {
        Self {
            content: content.to_string(),
            ..Default::default()
        }
    }
}

/// Row Style
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RowStyle {
    /// Background color
    pub background_color: Option<String>,
    /// Font color
    pub font_color: Option<String>,
}

/// Horizontal Alignment
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub enum HorizontalAlignment {
    #[default]
    Left,
    Center,
    Right,
    Justify,
}

/// Vertical Alignment
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub enum VerticalAlignment {
    #[default]
    Top,
    Middle,
    Bottom,
}

/// Cell Borders
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct CellBorders {
    pub top: Option<BorderDef>,
    pub bottom: Option<BorderDef>,
    pub left: Option<BorderDef>,
    pub right: Option<BorderDef>,
}

/// Border Definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BorderDef {
    pub style: BorderStyle,
    pub color: String,
    pub width: f64,
}

/// Border Style
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum BorderStyle {
    None,
    Single,
    Double,
    Thick,
    Dashed,
    Dotted,
}

impl Default for BorderStyle {
    fn default() -> Self {
        BorderStyle::None
    }
}

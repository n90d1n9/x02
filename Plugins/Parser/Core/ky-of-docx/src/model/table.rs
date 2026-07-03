use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Table {
    pub rows: Vec<TableRow>,
    /// Column widths in twips, if specified.
    pub column_widths: Vec<u32>,
    pub style: Option<String>,
}

impl Table {
    /// Number of rows.
    pub fn row_count(&self) -> usize {
        self.rows.len()
    }

    /// Number of columns (derived from the first row).
    pub fn col_count(&self) -> usize {
        self.rows.first().map_or(0, |r| r.cells.len())
    }

    /// Extract all text from the table as a 2-D vector `[row][col]`.
    pub fn to_text_grid(&self) -> Vec<Vec<String>> {
        self.rows
            .iter()
            .map(|r| r.cells.iter().map(|c| c.text()).collect())
            .collect()
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TableRow {
    pub cells: Vec<TableCell>,
    pub is_header: bool,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TableCell {
    pub paragraphs: Vec<Paragraph>,
    /// Column span.
    pub col_span: u32,
    /// Row span.
    pub row_span: u32,
    /// Width in twips.
    pub width: Option<u32>,
    pub background_color: Option<String>,
    pub vertical_align: Option<CellVerticalAlign>,
}

impl TableCell {
    /// Concatenate all paragraph text, separated by newlines.
    pub fn text(&self) -> String {
        self.paragraphs
            .iter()
            .map(|p| p.text())
            .collect::<Vec<_>>()
            .join("\n")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CellVerticalAlign {
    Top,
    Center,
    Bottom,
}

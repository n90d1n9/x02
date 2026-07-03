


// ═══════════════════════════════════════════════
// Tables
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TableCell {
    pub text: String,
    pub col: usize,
    pub row: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TableRow {
    pub cells: Vec<TableCell>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextTable {
    pub page_index: usize,
    pub rows: Vec<TableRow>,
    pub col_count: usize,
}

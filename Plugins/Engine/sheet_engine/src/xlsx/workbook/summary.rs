/// Summary of a workbook loaded through the XLSX adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct XlsxWorkbookSummary {
    /// Stable workbook identity supplied by the caller.
    pub workbook_id: String,
    /// Ordered summaries for each loaded sheet.
    pub sheets: Vec<XlsxSheetSummary>,
}

impl XlsxWorkbookSummary {
    /// Return the number of sheets included in this summary.
    pub fn sheet_count(&self) -> usize {
        self.sheets.len()
    }

    /// Return the total number of non-empty cells across all sheets.
    pub fn total_cell_count(&self) -> usize {
        self.sheets.iter().map(|sheet| sheet.cell_count).sum()
    }

    /// Return sheet names in workbook order.
    pub fn sheet_names(&self) -> Vec<&str> {
        self.sheets
            .iter()
            .map(|sheet| sheet.name.as_str())
            .collect()
    }
}

/// Summary of a single worksheet loaded through the XLSX adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct XlsxSheetSummary {
    /// Zero-based sheet index in workbook order.
    pub index: usize,
    /// Display name of the worksheet tab.
    pub name: String,
    /// Number of non-empty rows reported by the reader.
    pub row_count: u32,
    /// Maximum populated column width reported by the reader.
    pub col_count: u16,
    /// Number of non-empty cells reported by the reader.
    pub cell_count: usize,
}

//! Formula reference translation offsets.

/// Offset used when translating relative cell references inside formulas.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FormulaReferenceOffset {
    pub col_delta: i64,
    pub row_delta: i64,
}

impl FormulaReferenceOffset {
    /// Create a translation offset from source and target cell coordinates.
    pub fn from_cells(source_col: u32, source_row: u32, target_col: u32, target_row: u32) -> Self {
        Self {
            col_delta: i64::from(target_col) - i64::from(source_col),
            row_delta: i64::from(target_row) - i64::from(source_row),
        }
    }

    /// Return true when this offset would leave references unchanged.
    pub fn is_zero(self) -> bool {
        self.col_delta == 0 && self.row_delta == 0
    }
}

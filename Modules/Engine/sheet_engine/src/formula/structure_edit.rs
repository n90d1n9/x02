//! Formula reference structure-edit descriptors.

/// Structural sheet edit used when rewriting formula references.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FormulaReferenceStructureEdit {
    /// Insert rows at a zero-based row index.
    InsertRows { row: u32, count: u32 },
    /// Delete rows from a zero-based row index.
    DeleteRows { row: u32, count: u32 },
    /// Insert columns at a zero-based column index.
    InsertColumns { col: u32, count: u32 },
    /// Delete columns from a zero-based column index.
    DeleteColumns { col: u32, count: u32 },
}

impl FormulaReferenceStructureEdit {
    pub(super) fn is_noop(self) -> bool {
        match self {
            Self::InsertRows { count, .. }
            | Self::DeleteRows { count, .. }
            | Self::InsertColumns { count, .. }
            | Self::DeleteColumns { count, .. } => count == 0,
        }
    }
}

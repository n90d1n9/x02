//! Public sheet structure edit contract and formula rewrite mapping.

use serde::{Deserialize, Serialize};

use crate::FormulaReferenceStructureEdit;

/// Structural row or column edit applied to a sparse sheet grid.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SheetStructureEdit {
    /// Insert empty rows before the zero-based row index.
    InsertRows { row: u32, count: u32 },
    /// Delete rows starting at the zero-based row index.
    DeleteRows { row: u32, count: u32 },
    /// Insert empty columns before the zero-based column index.
    InsertColumns { col: u32, count: u32 },
    /// Delete columns starting at the zero-based column index.
    DeleteColumns { col: u32, count: u32 },
}

impl SheetStructureEdit {
    /// Build an insert-rows structural edit.
    pub fn insert_rows(row: u32, count: u32) -> Self {
        Self::InsertRows { row, count }
    }

    /// Build a delete-rows structural edit.
    pub fn delete_rows(row: u32, count: u32) -> Self {
        Self::DeleteRows { row, count }
    }

    /// Build an insert-columns structural edit.
    pub fn insert_columns(col: u32, count: u32) -> Self {
        Self::InsertColumns { col, count }
    }

    /// Build a delete-columns structural edit.
    pub fn delete_columns(col: u32, count: u32) -> Self {
        Self::DeleteColumns { col, count }
    }

    /// Return true when this edit does not change sheet structure.
    pub fn is_noop(self) -> bool {
        match self {
            Self::InsertRows { count, .. }
            | Self::DeleteRows { count, .. }
            | Self::InsertColumns { count, .. }
            | Self::DeleteColumns { count, .. } => count == 0,
        }
    }

    /// Return the opposite structural edit for undo and redo routing.
    pub fn inverse(self) -> Self {
        match self {
            Self::InsertRows { row, count } => Self::DeleteRows { row, count },
            Self::DeleteRows { row, count } => Self::InsertRows { row, count },
            Self::InsertColumns { col, count } => Self::DeleteColumns { col, count },
            Self::DeleteColumns { col, count } => Self::InsertColumns { col, count },
        }
    }

    pub(super) fn formula_edit(self) -> FormulaReferenceStructureEdit {
        match self {
            Self::InsertRows { row, count } => {
                FormulaReferenceStructureEdit::InsertRows { row, count }
            }
            Self::DeleteRows { row, count } => {
                FormulaReferenceStructureEdit::DeleteRows { row, count }
            }
            Self::InsertColumns { col, count } => {
                FormulaReferenceStructureEdit::InsertColumns { col, count }
            }
            Self::DeleteColumns { col, count } => {
                FormulaReferenceStructureEdit::DeleteColumns { col, count }
            }
        }
    }
}

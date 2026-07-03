use serde::{Deserialize, Serialize};

use crate::XlsxWorkbookSessionStatus;

/// Compact command state for common workbook toolbar and sidebar controls.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxWorkbookCommandState {
    pub active_sheet_name: String,
    pub sheet_count: usize,
    pub is_dirty: bool,
    pub pending_operation_count: usize,
    pub can_remove_sheet: bool,
    pub can_undo: bool,
    pub can_redo: bool,
}

impl XlsxWorkbookCommandState {
    /// Build command state from a workbook session status summary.
    pub fn from_status(status: &XlsxWorkbookSessionStatus) -> Self {
        Self {
            active_sheet_name: status.active_sheet_name.clone(),
            sheet_count: status.sheet_count,
            is_dirty: status.is_dirty(),
            pending_operation_count: status.pending_operation_count,
            can_remove_sheet: status.sheet_count > 1,
            can_undo: status.can_undo,
            can_redo: status.can_redo,
        }
    }
}

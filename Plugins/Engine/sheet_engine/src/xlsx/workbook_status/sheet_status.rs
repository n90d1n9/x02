//! Per-sheet status summary model.

use serde::{Deserialize, Serialize};
use waraq_core::{DocumentId, OfficeSelectionKind};

/// Read-only status summary for a sheet inside an XLSX workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetSessionStatus {
    pub sheet_name: String,
    pub document_id: DocumentId,
    pub is_active: bool,
    pub cell_count: usize,
    pub max_col: u32,
    pub max_row: u32,
    pub sequence: u64,
    pub is_dirty: bool,
    pub dirty_sequence_range: Option<(u64, u64)>,
    pub pending_operation_count: usize,
    pub operation_log_count: usize,
    pub selection_kind: OfficeSelectionKind,
    pub selection_is_empty: bool,
    pub can_undo: bool,
    pub can_redo: bool,
}

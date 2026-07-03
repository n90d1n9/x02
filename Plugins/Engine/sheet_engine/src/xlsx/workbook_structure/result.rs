//! Direct structure edit result contract.

use serde::{Deserialize, Serialize};
use waraq_core::DocumentId;

use crate::{CellPosition, SheetEditOutcome, SheetStructureEdit, XlsxSheetEditResult};

/// Result returned after routing a row or column structure edit through a workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetStructureEditResult {
    pub sheet_name: String,
    pub document_id: DocumentId,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub edit: SheetStructureEdit,
    pub outcome: SheetEditOutcome,
}

impl XlsxSheetStructureEditResult {
    /// Create a structure edit result with resolved sheet and operation metadata.
    pub fn new(
        sheet_name: impl Into<String>,
        document_id: DocumentId,
        sequence: u64,
        timestamp_ms: u64,
        edit: SheetStructureEdit,
        outcome: SheetEditOutcome,
    ) -> Self {
        Self {
            sheet_name: sheet_name.into(),
            document_id,
            sequence,
            timestamp_ms,
            edit,
            outcome,
        }
    }

    /// Build a structure edit result from the generic sheet edit routing result.
    pub(crate) fn from_sheet_edit_result(
        edit: SheetStructureEdit,
        result: XlsxSheetEditResult,
    ) -> Self {
        Self::new(
            result.sheet_name,
            result.document_id,
            result.sequence,
            result.timestamp_ms,
            edit,
            result.outcome,
        )
    }

    /// Return the cells moved, removed, or formula-shifted by the structure edit.
    pub fn changed_cells(&self) -> &[CellPosition] {
        &self.outcome.changed_cells
    }

    /// Return the number of cells moved, removed, or formula-shifted by the structure edit.
    pub fn changed_cell_count(&self) -> usize {
        self.outcome.changed_cells.len()
    }
}

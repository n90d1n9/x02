//! Undoable structure edit request and result contracts.

use serde::{Deserialize, Serialize};
use waraq_core::{ActorId, OperationId, TransactionId};

use crate::{CellPosition, SheetStructureEdit};

use super::XlsxSheetStructureEditResult;

/// Request for applying an undoable row or column structure edit through a workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxUndoableSheetStructureEditRequest {
    sheet_name: Option<String>,
    transaction_id: TransactionId,
    operation_id: OperationId,
    inverse_operation_id_prefix: OperationId,
    actor_id: ActorId,
    timestamp_ms: u64,
    edit: SheetStructureEdit,
}

impl XlsxUndoableSheetStructureEditRequest {
    /// Create an undoable structure edit request targeting the active sheet.
    pub fn new(
        transaction_id: impl Into<TransactionId>,
        operation_id: impl Into<OperationId>,
        inverse_operation_id_prefix: impl Into<OperationId>,
        actor_id: impl Into<ActorId>,
        timestamp_ms: u64,
        edit: SheetStructureEdit,
    ) -> Self {
        Self {
            sheet_name: None,
            transaction_id: transaction_id.into(),
            operation_id: operation_id.into(),
            inverse_operation_id_prefix: inverse_operation_id_prefix.into(),
            actor_id: actor_id.into(),
            timestamp_ms,
            edit,
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet structure edit.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the core transaction id committed for this undoable structure edit.
    pub fn transaction_id(&self) -> &TransactionId {
        &self.transaction_id
    }

    /// Return the forward operation id used for this structure edit.
    pub fn operation_id(&self) -> &OperationId {
        &self.operation_id
    }

    /// Return the operation id prefix used for generated inverse operations.
    pub fn inverse_operation_id_prefix(&self) -> &OperationId {
        &self.inverse_operation_id_prefix
    }

    /// Return the actor id used by the forward and inverse operations.
    pub fn actor_id(&self) -> &ActorId {
        &self.actor_id
    }

    /// Return the structure edit timestamp.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    /// Return the row or column structure edit payload.
    pub fn edit(&self) -> SheetStructureEdit {
        self.edit
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }

    pub(crate) fn inverse_operation_id_at(&self, index: usize) -> OperationId {
        OperationId::new(format!(
            "{}:{}",
            self.inverse_operation_id_prefix,
            index + 1
        ))
    }
}

/// Result returned after committing an undoable row or column structure transaction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxUndoableSheetStructureEditResult {
    pub transaction_id: TransactionId,
    pub edit: XlsxSheetStructureEditResult,
    pub inverse_operation_count: usize,
}

impl XlsxUndoableSheetStructureEditResult {
    /// Create an undoable structure edit result with transaction and inverse metadata.
    pub fn new(
        transaction_id: TransactionId,
        edit: XlsxSheetStructureEditResult,
        inverse_operation_count: usize,
    ) -> Self {
        Self {
            transaction_id,
            edit,
            inverse_operation_count,
        }
    }

    /// Return the cells moved, removed, or formula-shifted by the structure edit.
    pub fn changed_cells(&self) -> &[CellPosition] {
        self.edit.changed_cells()
    }

    /// Return the number of cells moved, removed, or formula-shifted by the structure edit.
    pub fn changed_cell_count(&self) -> usize {
        self.edit.changed_cell_count()
    }
}

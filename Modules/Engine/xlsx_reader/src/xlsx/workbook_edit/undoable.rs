//! Undoable sheet edit request and result contracts.

use serde::{Deserialize, Serialize};
use waraq_core::{ActorId, OperationId, TransactionId};

use crate::SheetEdit;

use super::XlsxSheetEditResult;

/// Request for applying a single undoable sheet edit through an XLSX workbook session.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XlsxUndoableSheetEditRequest {
    sheet_name: Option<String>,
    transaction_id: TransactionId,
    operation_id: OperationId,
    inverse_operation_id: OperationId,
    actor_id: ActorId,
    timestamp_ms: u64,
    edit: SheetEdit,
    inverse_edit: SheetEdit,
}

impl XlsxUndoableSheetEditRequest {
    /// Create an undoable edit request targeting the active sheet.
    pub fn new(
        transaction_id: impl Into<TransactionId>,
        operation_id: impl Into<OperationId>,
        inverse_operation_id: impl Into<OperationId>,
        actor_id: impl Into<ActorId>,
        timestamp_ms: u64,
        edit: SheetEdit,
        inverse_edit: SheetEdit,
    ) -> Self {
        Self {
            sheet_name: None,
            transaction_id: transaction_id.into(),
            operation_id: operation_id.into(),
            inverse_operation_id: inverse_operation_id.into(),
            actor_id: actor_id.into(),
            timestamp_ms,
            edit,
            inverse_edit,
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet edit.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the core transaction id to commit for undo history.
    pub fn transaction_id(&self) -> &TransactionId {
        &self.transaction_id
    }

    /// Return the forward operation id.
    pub fn operation_id(&self) -> &OperationId {
        &self.operation_id
    }

    /// Return the inverse operation id.
    pub fn inverse_operation_id(&self) -> &OperationId {
        &self.inverse_operation_id
    }

    /// Return the actor id to use for the forward and inverse operations.
    pub fn actor_id(&self) -> &ActorId {
        &self.actor_id
    }

    /// Return the edit timestamp.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    /// Return the forward sheet edit payload.
    pub fn edit(&self) -> &SheetEdit {
        &self.edit
    }

    /// Return the inverse sheet edit payload used by undo.
    pub fn inverse_edit(&self) -> &SheetEdit {
        &self.inverse_edit
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }
}

/// Result returned after committing an undoable sheet edit transaction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxUndoableSheetEditResult {
    pub transaction_id: TransactionId,
    pub edit: XlsxSheetEditResult,
}

impl XlsxUndoableSheetEditResult {
    /// Create an undoable edit result with transaction and operation metadata.
    pub fn new(transaction_id: TransactionId, edit: XlsxSheetEditResult) -> Self {
        Self {
            transaction_id,
            edit,
        }
    }
}

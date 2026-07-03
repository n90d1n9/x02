//! Format-range request contract.

use serde::{Deserialize, Serialize};
use waraq_core::{ActorId, OperationId, TransactionId};

use crate::XlsxSheetRange;

use super::XlsxCellFormatPatch;

/// Request for applying a format patch to a sheet range as one undoable transaction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxFormatRangeRequest {
    sheet_name: Option<String>,
    transaction_id: TransactionId,
    operation_id_prefix: OperationId,
    inverse_operation_id_prefix: OperationId,
    actor_id: ActorId,
    timestamp_ms: u64,
    range: XlsxSheetRange,
    patch: XlsxCellFormatPatch,
}

impl XlsxFormatRangeRequest {
    /// Create a format-range request targeting the active sheet.
    pub fn new(
        transaction_id: impl Into<TransactionId>,
        operation_id_prefix: impl Into<OperationId>,
        inverse_operation_id_prefix: impl Into<OperationId>,
        actor_id: impl Into<ActorId>,
        timestamp_ms: u64,
        range: XlsxSheetRange,
        patch: XlsxCellFormatPatch,
    ) -> Self {
        Self {
            sheet_name: None,
            transaction_id: transaction_id.into(),
            operation_id_prefix: operation_id_prefix.into(),
            inverse_operation_id_prefix: inverse_operation_id_prefix.into(),
            actor_id: actor_id.into(),
            timestamp_ms,
            range,
            patch,
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet format action.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the core transaction id committed for the whole format action.
    pub fn transaction_id(&self) -> &TransactionId {
        &self.transaction_id
    }

    /// Return the operation id prefix used for generated format operations.
    pub fn operation_id_prefix(&self) -> &OperationId {
        &self.operation_id_prefix
    }

    /// Return the operation id prefix used for generated inverse operations.
    pub fn inverse_operation_id_prefix(&self) -> &OperationId {
        &self.inverse_operation_id_prefix
    }

    /// Return the actor id used by all operations in the format transaction.
    pub fn actor_id(&self) -> &ActorId {
        &self.actor_id
    }

    /// Return the format action timestamp.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    /// Return the target range to format.
    pub fn range(&self) -> XlsxSheetRange {
        self.range
    }

    /// Return the format patch applied to each target cell.
    pub fn patch(&self) -> &XlsxCellFormatPatch {
        &self.patch
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }
}

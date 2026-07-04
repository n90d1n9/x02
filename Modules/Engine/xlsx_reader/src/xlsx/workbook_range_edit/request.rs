//! Range edit request contract and validation helpers.

use serde::{Deserialize, Serialize};
use waraq_core::{ActorId, OperationId, TransactionId};

use crate::XlsxWorkbookError;

use super::{XlsxRangeCellUpdate, XlsxSheetRange};

/// Request for applying a multi-cell sheet edit as a single undoable transaction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetRangeEditRequest {
    sheet_name: Option<String>,
    transaction_id: TransactionId,
    operation_id_prefix: OperationId,
    inverse_operation_id_prefix: OperationId,
    actor_id: ActorId,
    timestamp_ms: u64,
    range: XlsxSheetRange,
    updates: Vec<XlsxRangeCellUpdate>,
    inverse_updates: Vec<XlsxRangeCellUpdate>,
}

impl XlsxSheetRangeEditRequest {
    /// Create a range edit request targeting the active sheet.
    pub fn new(
        transaction_id: impl Into<TransactionId>,
        operation_id_prefix: impl Into<OperationId>,
        inverse_operation_id_prefix: impl Into<OperationId>,
        actor_id: impl Into<ActorId>,
        timestamp_ms: u64,
        range: XlsxSheetRange,
        updates: Vec<XlsxRangeCellUpdate>,
        inverse_updates: Vec<XlsxRangeCellUpdate>,
    ) -> Self {
        Self {
            sheet_name: None,
            transaction_id: transaction_id.into(),
            operation_id_prefix: operation_id_prefix.into(),
            inverse_operation_id_prefix: inverse_operation_id_prefix.into(),
            actor_id: actor_id.into(),
            timestamp_ms,
            range,
            updates,
            inverse_updates,
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet range edit.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the core transaction id committed for the whole range.
    pub fn transaction_id(&self) -> &TransactionId {
        &self.transaction_id
    }

    /// Return the operation id prefix used for generated forward operations.
    pub fn operation_id_prefix(&self) -> &OperationId {
        &self.operation_id_prefix
    }

    /// Return the operation id prefix used for generated inverse operations.
    pub fn inverse_operation_id_prefix(&self) -> &OperationId {
        &self.inverse_operation_id_prefix
    }

    /// Return the actor id used by all operations in the transaction.
    pub fn actor_id(&self) -> &ActorId {
        &self.actor_id
    }

    /// Return the edit timestamp.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    /// Return the target cell range.
    pub fn range(&self) -> XlsxSheetRange {
        self.range
    }

    /// Return forward updates in row-major range order.
    pub fn updates(&self) -> &[XlsxRangeCellUpdate] {
        &self.updates
    }

    /// Return inverse updates in row-major range order.
    pub fn inverse_updates(&self) -> &[XlsxRangeCellUpdate] {
        &self.inverse_updates
    }

    /// Return the number of cells expected by this range.
    pub fn expected_cell_count(&self) -> usize {
        self.range.cell_count()
    }

    /// Return the actual number of forward updates.
    pub fn update_count(&self) -> usize {
        self.updates.len()
    }

    /// Return the actual number of inverse updates.
    pub fn inverse_update_count(&self) -> usize {
        self.inverse_updates.len()
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }

    pub(crate) fn validate_cell_counts(&self) -> Result<(), XlsxWorkbookError> {
        let expected = self.expected_cell_count();
        let actual = self.update_count();
        let inverse_actual = self.inverse_update_count();
        if actual != expected || inverse_actual != expected {
            return Err(XlsxWorkbookError::RangeEditCellCountMismatch {
                expected,
                actual,
                inverse_actual,
            });
        }
        Ok(())
    }

    pub(crate) fn operation_id_at(&self, index: usize) -> OperationId {
        OperationId::new(format!("{}:{}", self.operation_id_prefix, index + 1))
    }

    pub(crate) fn inverse_operation_id_at(&self, index: usize) -> OperationId {
        OperationId::new(format!(
            "{}:{}",
            self.inverse_operation_id_prefix,
            index + 1
        ))
    }
}

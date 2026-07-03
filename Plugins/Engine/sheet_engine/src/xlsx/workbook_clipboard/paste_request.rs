//! Paste request contract and target-range calculation for workbook clipboard commands.

use serde::{Deserialize, Serialize};
use waraq_core::{ActorId, OperationId, TransactionId};

use crate::{CellPosition, XlsxSheetRange, XlsxWorkbookError};

use super::XlsxSheetClipboardPayload;

/// Request for pasting a copied range payload into a workbook sheet.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxPasteClipboardRequest {
    sheet_name: Option<String>,
    transaction_id: TransactionId,
    operation_id_prefix: OperationId,
    inverse_operation_id_prefix: OperationId,
    actor_id: ActorId,
    timestamp_ms: u64,
    target_start: CellPosition,
    payload: XlsxSheetClipboardPayload,
    #[serde(default = "default_translate_formulas")]
    translate_formulas: bool,
}

impl XlsxPasteClipboardRequest {
    /// Create a paste request targeting the active sheet.
    pub fn new(
        transaction_id: impl Into<TransactionId>,
        operation_id_prefix: impl Into<OperationId>,
        inverse_operation_id_prefix: impl Into<OperationId>,
        actor_id: impl Into<ActorId>,
        timestamp_ms: u64,
        target_start: CellPosition,
        payload: XlsxSheetClipboardPayload,
    ) -> Self {
        Self {
            sheet_name: None,
            transaction_id: transaction_id.into(),
            operation_id_prefix: operation_id_prefix.into(),
            inverse_operation_id_prefix: inverse_operation_id_prefix.into(),
            actor_id: actor_id.into(),
            timestamp_ms,
            target_start,
            payload,
            translate_formulas: default_translate_formulas(),
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return a request with formula-reference translation enabled or disabled.
    pub fn with_formula_translation(mut self, translate_formulas: bool) -> Self {
        self.translate_formulas = translate_formulas;
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet paste.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the transaction id used by the generated range edit.
    pub fn transaction_id(&self) -> &TransactionId {
        &self.transaction_id
    }

    /// Return the operation id prefix used by generated forward operations.
    pub fn operation_id_prefix(&self) -> &OperationId {
        &self.operation_id_prefix
    }

    /// Return the operation id prefix used by generated inverse operations.
    pub fn inverse_operation_id_prefix(&self) -> &OperationId {
        &self.inverse_operation_id_prefix
    }

    /// Return the actor id used by generated operations.
    pub fn actor_id(&self) -> &ActorId {
        &self.actor_id
    }

    /// Return the timestamp used by generated operations.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    /// Return the top-left target cell for the paste.
    pub fn target_start(&self) -> CellPosition {
        self.target_start
    }

    /// Return the copied payload to paste.
    pub fn payload(&self) -> &XlsxSheetClipboardPayload {
        &self.payload
    }

    /// Return whether relative formula references should move with the paste target.
    pub fn translate_formulas(&self) -> bool {
        self.translate_formulas
    }

    /// Return the target range covered by this paste.
    pub fn target_range(&self) -> Result<XlsxSheetRange, XlsxWorkbookError> {
        let width_offset = u32::try_from(self.payload.width().saturating_sub(1))
            .map_err(|_| self.target_overflow())?;
        let height_offset = u32::try_from(self.payload.height().saturating_sub(1))
            .map_err(|_| self.target_overflow())?;
        let end_col = self
            .target_start
            .col
            .checked_add(width_offset)
            .ok_or_else(|| self.target_overflow())?;
        let end_row = self
            .target_start
            .row
            .checked_add(height_offset)
            .ok_or_else(|| self.target_overflow())?;

        Ok(XlsxSheetRange::new(
            self.target_start,
            CellPosition::new(end_col, end_row),
        ))
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }

    fn target_overflow(&self) -> XlsxWorkbookError {
        XlsxWorkbookError::ClipboardPasteTargetOverflow {
            start_col: self.target_start.col,
            start_row: self.target_start.row,
            width: self.payload.width(),
            height: self.payload.height(),
        }
    }
}

fn default_translate_formulas() -> bool {
    true
}

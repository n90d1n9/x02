//! Undoable sheet edit transaction routing for workbook sessions.

use super::super::XlsxWorkbookSession;
use crate::{
    sheet_operation, SheetTransaction, XlsxSheetEditResult, XlsxUndoableSheetEditRequest,
    XlsxUndoableSheetEditResult, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Apply an undoable sheet edit to the active sheet.
    pub fn apply_active_undoable_sheet_edit(
        &mut self,
        request: XlsxUndoableSheetEditRequest,
    ) -> Result<XlsxUndoableSheetEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.apply_undoable_sheet_edit(request)
    }

    /// Route an undoable sheet edit to its target sheet and commit undo history.
    pub fn apply_undoable_sheet_edit(
        &mut self,
        request: XlsxUndoableSheetEditRequest,
    ) -> Result<XlsxUndoableSheetEditResult, XlsxWorkbookError> {
        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let session = self.sheet_session_mut(&sheet_name).ok_or_else(|| {
            XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: sheet_name.clone(),
            }
        })?;
        let document_id = session.document_id().clone();
        let sequence = session.sequence() + 1;
        let timestamp_ms = request.timestamp_ms();
        let operation = sheet_operation(
            request.operation_id().clone(),
            document_id.clone(),
            request.actor_id().clone(),
            sequence,
            timestamp_ms,
            request.edit().clone(),
        );
        let inverse_operation = sheet_operation(
            request.inverse_operation_id().clone(),
            document_id.clone(),
            request.actor_id().clone(),
            sequence,
            timestamp_ms,
            request.inverse_edit().clone(),
        );
        let transaction = SheetTransaction::new(request.transaction_id().clone())
            .with_operation(operation)
            .with_inverse_operation(inverse_operation);
        let mut outcomes = session.apply_transaction(transaction).map_err(|error| {
            XlsxWorkbookError::SheetEditFailed {
                sheet_name: sheet_name.clone(),
                message: format!("{error:?}"),
            }
        })?;
        let outcome = outcomes
            .pop()
            .expect("single-operation transaction returns one outcome");
        let edit =
            XlsxSheetEditResult::new(sheet_name, document_id, sequence, timestamp_ms, outcome);

        Ok(XlsxUndoableSheetEditResult::new(
            request.transaction_id().clone(),
            edit,
        ))
    }
}

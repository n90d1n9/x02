//! Undoable structure edit transaction routing for workbook sessions.

use super::super::super::workbook_structure::inverse_edits_for_structure_undo;
use super::super::XlsxWorkbookSession;
use crate::{
    sheet_operation, SheetEdit, SheetTransaction, XlsxSheetStructureEditResult,
    XlsxUndoableSheetStructureEditRequest, XlsxUndoableSheetStructureEditResult, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Apply an undoable row or column structure edit to the active sheet.
    pub fn apply_active_undoable_sheet_structure_edit(
        &mut self,
        request: XlsxUndoableSheetStructureEditRequest,
    ) -> Result<XlsxUndoableSheetStructureEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.apply_undoable_sheet_structure_edit(request)
    }

    /// Route an undoable row or column structure edit and commit its inverse transaction.
    pub fn apply_undoable_sheet_structure_edit(
        &mut self,
        request: XlsxUndoableSheetStructureEditRequest,
    ) -> Result<XlsxUndoableSheetStructureEditResult, XlsxWorkbookError> {
        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let edit = request.edit();
        let timestamp_ms = request.timestamp_ms();
        let (document_id, sequence, inverse_edits) =
            {
                let session = self.sheet_session(&sheet_name).ok_or_else(|| {
                    XlsxWorkbookError::UnknownWorkbookSheet {
                        sheet_name: sheet_name.clone(),
                    }
                })?;
                let inverse_edits = inverse_edits_for_structure_undo(session.state(), edit)
                    .map_err(|error| XlsxWorkbookError::SheetEditFailed {
                        sheet_name: sheet_name.clone(),
                        message: format!("{error:?}"),
                    })?;

                (
                    session.document_id().clone(),
                    session.sequence() + 1,
                    inverse_edits,
                )
            };
        let inverse_operation_count = inverse_edits.len();
        let session = self.sheet_session_mut(&sheet_name).ok_or_else(|| {
            XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: sheet_name.clone(),
            }
        })?;
        let operation = sheet_operation(
            request.operation_id().clone(),
            document_id.clone(),
            request.actor_id().clone(),
            sequence,
            timestamp_ms,
            SheetEdit::ApplyStructure { edit },
        );
        let mut transaction =
            SheetTransaction::new(request.transaction_id().clone()).with_operation(operation);

        for (index, inverse_edit) in inverse_edits.into_iter().enumerate() {
            transaction.push_inverse_operation(sheet_operation(
                request.inverse_operation_id_at(index),
                document_id.clone(),
                request.actor_id().clone(),
                sequence + index as u64 + 1,
                timestamp_ms,
                inverse_edit,
            ));
        }

        let mut outcomes = session.apply_transaction(transaction).map_err(|error| {
            XlsxWorkbookError::SheetEditFailed {
                sheet_name: sheet_name.clone(),
                message: format!("{error:?}"),
            }
        })?;
        let outcome = outcomes
            .pop()
            .expect("single-operation structure transaction returns one outcome");
        let edit_result = XlsxSheetStructureEditResult::new(
            sheet_name,
            document_id,
            sequence,
            timestamp_ms,
            edit,
            outcome,
        );

        Ok(XlsxUndoableSheetStructureEditResult::new(
            request.transaction_id().clone(),
            edit_result,
            inverse_operation_count,
        ))
    }
}

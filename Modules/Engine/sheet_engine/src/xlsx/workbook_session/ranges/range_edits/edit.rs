//! Multi-cell edit transaction behavior for workbook sessions.

use super::super::super::XlsxWorkbookSession;
use crate::{
    sheet_operation, SheetTransaction, XlsxSheetRangeEditRequest, XlsxSheetRangeEditResult,
    XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Apply a multi-cell range edit to the active sheet.
    pub fn apply_active_range_edit(
        &mut self,
        request: XlsxSheetRangeEditRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.apply_range_edit(request)
    }

    /// Route a multi-cell range edit to its target sheet as one undoable transaction.
    pub fn apply_range_edit(
        &mut self,
        request: XlsxSheetRangeEditRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        request.validate_cell_counts()?;

        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let session = self.sheet_session_mut(&sheet_name).ok_or_else(|| {
            XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: sheet_name.clone(),
            }
        })?;
        let document_id = session.document_id().clone();
        let timestamp_ms = request.timestamp_ms();
        let positions = request.range().positions();
        let start_sequence = session.sequence() + 1;
        let mut transaction = SheetTransaction::new(request.transaction_id().clone());

        for (index, position) in positions.into_iter().enumerate() {
            let sequence = start_sequence + index as u64;
            let operation = sheet_operation(
                request.operation_id_at(index),
                document_id.clone(),
                request.actor_id().clone(),
                sequence,
                timestamp_ms,
                request.updates()[index].to_sheet_edit(position),
            );
            let inverse_operation = sheet_operation(
                request.inverse_operation_id_at(index),
                document_id.clone(),
                request.actor_id().clone(),
                sequence,
                timestamp_ms,
                request.inverse_updates()[index].to_sheet_edit(position),
            );
            transaction.push_operation(operation);
            transaction.push_inverse_operation(inverse_operation);
        }

        let outcomes = session.apply_transaction(transaction).map_err(|error| {
            XlsxWorkbookError::SheetRangeEditFailed {
                sheet_name: sheet_name.clone(),
                message: format!("{error:?}"),
            }
        })?;
        let end_sequence = session.sequence();

        Ok(XlsxSheetRangeEditResult::new(
            request.transaction_id().clone(),
            sheet_name,
            document_id,
            start_sequence,
            end_sequence,
            timestamp_ms,
            request.range(),
            outcomes,
        ))
    }
}

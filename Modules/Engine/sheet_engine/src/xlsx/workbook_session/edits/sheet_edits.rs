//! Direct sheet edit routing for workbook sessions.

use super::super::XlsxWorkbookSession;
use crate::{
    sheet_operation, SheetEditOutcome, XlsxSheetEditRequest, XlsxSheetEditResult, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Apply a sheet edit to the active sheet.
    pub fn apply_active_sheet_edit(
        &mut self,
        request: XlsxSheetEditRequest,
    ) -> Result<XlsxSheetEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.apply_sheet_edit(request)
    }

    /// Route a sheet edit to its target sheet with the next core operation sequence.
    pub fn apply_sheet_edit(
        &mut self,
        request: XlsxSheetEditRequest,
    ) -> Result<XlsxSheetEditResult, XlsxWorkbookError> {
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
        let outcome: SheetEditOutcome = session.apply_operation(operation).map_err(|error| {
            XlsxWorkbookError::SheetEditFailed {
                sheet_name: sheet_name.clone(),
                message: format!("{error:?}"),
            }
        })?;

        Ok(XlsxSheetEditResult::new(
            sheet_name,
            document_id,
            sequence,
            timestamp_ms,
            outcome,
        ))
    }
}

//! Undo and redo behavior for workbook sessions.

use super::XlsxWorkbookSession;
use crate::{
    XlsxSheetHistoryAction, XlsxSheetHistoryRequest, XlsxSheetHistoryResult, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Undo the latest transaction on the active sheet.
    pub fn undo_active_sheet(
        &mut self,
        timestamp_ms: u64,
    ) -> Result<XlsxSheetHistoryResult, XlsxWorkbookError> {
        let request =
            XlsxSheetHistoryRequest::new(timestamp_ms).for_sheet(self.active_sheet_name.clone());
        self.undo_sheet(request)
    }

    /// Undo the latest transaction on a target sheet.
    pub fn undo_sheet(
        &mut self,
        request: XlsxSheetHistoryRequest,
    ) -> Result<XlsxSheetHistoryResult, XlsxWorkbookError> {
        self.apply_sheet_history(request, XlsxSheetHistoryAction::Undo)
    }

    /// Redo the latest undone transaction on the active sheet.
    pub fn redo_active_sheet(
        &mut self,
        timestamp_ms: u64,
    ) -> Result<XlsxSheetHistoryResult, XlsxWorkbookError> {
        let request =
            XlsxSheetHistoryRequest::new(timestamp_ms).for_sheet(self.active_sheet_name.clone());
        self.redo_sheet(request)
    }

    /// Redo the latest undone transaction on a target sheet.
    pub fn redo_sheet(
        &mut self,
        request: XlsxSheetHistoryRequest,
    ) -> Result<XlsxSheetHistoryResult, XlsxWorkbookError> {
        self.apply_sheet_history(request, XlsxSheetHistoryAction::Redo)
    }
    fn apply_sheet_history(
        &mut self,
        request: XlsxSheetHistoryRequest,
        action: XlsxSheetHistoryAction,
    ) -> Result<XlsxSheetHistoryResult, XlsxWorkbookError> {
        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let timestamp_ms = request.timestamp_ms();
        let session = self.sheet_session_mut(&sheet_name).ok_or_else(|| {
            XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: sheet_name.clone(),
            }
        })?;
        let document_id = session.document_id().clone();
        let outcomes = match action {
            XlsxSheetHistoryAction::Undo => session.undo(timestamp_ms),
            XlsxSheetHistoryAction::Redo => session.redo(timestamp_ms),
        }
        .map_err(|error| XlsxWorkbookError::SheetHistoryFailed {
            sheet_name: sheet_name.clone(),
            action: action.as_str().to_owned(),
            message: format!("{error:?}"),
        })?;
        let sequence = session.sequence();

        Ok(XlsxSheetHistoryResult::new(
            action,
            sheet_name,
            document_id,
            sequence,
            timestamp_ms,
            outcomes,
        ))
    }
}

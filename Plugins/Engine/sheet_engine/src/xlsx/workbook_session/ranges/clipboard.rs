//! Clipboard copy, paste, and spreadsheet text behavior for workbook sessions.

use super::{super::XlsxWorkbookSession, inverse_updates_for_range};
use crate::{
    XlsxClipboardTextCodec, XlsxClipboardTextResult, XlsxCopyRangeRequest,
    XlsxCopyRangeTextRequest, XlsxPasteClipboardRequest, XlsxPasteClipboardTextRequest,
    XlsxSheetClipboardPayload, XlsxSheetRange, XlsxSheetRangeEditRequest, XlsxSheetRangeEditResult,
    XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Copy a rectangular range from the active sheet into a clipboard payload.
    pub fn copy_active_range(
        &self,
        range: XlsxSheetRange,
    ) -> Result<XlsxSheetClipboardPayload, XlsxWorkbookError> {
        let request = XlsxCopyRangeRequest::new(range).for_sheet(self.active_sheet_name.clone());
        self.copy_range(request)
    }

    /// Copy a rectangular range from a target sheet into a clipboard payload.
    pub fn copy_range(
        &self,
        request: XlsxCopyRangeRequest,
    ) -> Result<XlsxSheetClipboardPayload, XlsxWorkbookError> {
        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let session = self.sheet_session(&sheet_name).ok_or_else(|| {
            XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: sheet_name.clone(),
            }
        })?;
        let range = request.range();
        let raw_values = range
            .positions()
            .into_iter()
            .map(|position| {
                session
                    .state()
                    .get_cell(&position)
                    .map(|cell| cell.raw_content.clone())
            })
            .collect::<Vec<_>>();
        let formats = range
            .positions()
            .into_iter()
            .map(|position| {
                session
                    .state()
                    .get_cell(&position)
                    .map(|cell| cell.format.clone())
            })
            .collect::<Vec<_>>();

        Ok(XlsxSheetClipboardPayload::new_with_formats(
            sheet_name, range, raw_values, formats,
        ))
    }

    /// Copy a rectangular range from a target sheet as spreadsheet-compatible text.
    pub fn copy_range_as_text(
        &self,
        request: XlsxCopyRangeTextRequest,
    ) -> Result<XlsxClipboardTextResult, XlsxWorkbookError> {
        let payload = self.copy_range(request.copy_range().clone())?;
        let sheet_name = payload.source_sheet_name.clone();
        let text = XlsxClipboardTextCodec::encode_with_options(&payload, request.options())?;

        Ok(XlsxClipboardTextResult::new(sheet_name, text))
    }

    /// Copy a rectangular range from the active sheet as spreadsheet-compatible text.
    pub fn copy_active_range_as_text(
        &self,
        range: XlsxSheetRange,
    ) -> Result<XlsxClipboardTextResult, XlsxWorkbookError> {
        let request =
            XlsxCopyRangeTextRequest::new(range).for_sheet(self.active_sheet_name.clone());
        self.copy_range_as_text(request)
    }

    /// Paste a clipboard payload into the active sheet as one undoable transaction.
    pub fn paste_active_clipboard(
        &mut self,
        request: XlsxPasteClipboardRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.paste_clipboard(request)
    }

    /// Paste a clipboard payload into a target sheet as one undoable transaction.
    pub fn paste_clipboard(
        &mut self,
        request: XlsxPasteClipboardRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        request.payload().validate_cell_count()?;
        let target_range = request.target_range()?;
        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let inverse_updates = inverse_updates_for_range(self, &sheet_name, target_range)?;
        let range_request = XlsxSheetRangeEditRequest::new(
            request.transaction_id().clone(),
            request.operation_id_prefix().clone(),
            request.inverse_operation_id_prefix().clone(),
            request.actor_id().clone(),
            request.timestamp_ms(),
            target_range,
            request
                .payload()
                .to_updates_for_target_range(target_range, request.translate_formulas()),
            inverse_updates,
        )
        .for_sheet(sheet_name);

        self.apply_range_edit(range_request)
    }

    /// Paste spreadsheet-compatible text into a target sheet as one undoable transaction.
    pub fn paste_clipboard_text(
        &mut self,
        request: XlsxPasteClipboardTextRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let paste_request = request
            .to_paste_request(request.source_sheet_name().to_owned())?
            .for_sheet(sheet_name);

        self.paste_clipboard(paste_request)
    }

    /// Paste spreadsheet-compatible text into the active sheet as one undoable transaction.
    pub fn paste_active_clipboard_text(
        &mut self,
        request: XlsxPasteClipboardTextRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.paste_clipboard_text(request)
    }
}

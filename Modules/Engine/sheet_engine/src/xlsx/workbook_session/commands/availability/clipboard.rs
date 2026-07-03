//! Clipboard command availability rules.

use super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxCopyRangeRequest, XlsxCopyRangeTextRequest, XlsxPasteClipboardRequest,
    XlsxPasteClipboardTextRequest, XlsxWorkbookCommand, XlsxWorkbookCommandAvailability,
    XlsxWorkbookCommandDisabledReason, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    pub(super) fn availability_for_copy_range(
        &self,
        request: &XlsxCopyRangeRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_copy_range_text(
        &self,
        request: &XlsxCopyRangeTextRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_paste_clipboard(
        &self,
        request: &XlsxPasteClipboardRequest,
    ) -> XlsxWorkbookCommandAvailability {
        use XlsxWorkbookCommandDisabledReason as DisabledReason;

        match request.payload().validate_cell_count() {
            Ok(()) => {}
            Err(XlsxWorkbookError::ClipboardPayloadCellCountMismatch { expected, actual }) => {
                return XlsxWorkbookCommandAvailability::disabled(
                    DisabledReason::ClipboardPayloadCellCountMismatch { expected, actual },
                );
            }
            Err(XlsxWorkbookError::ClipboardPayloadFormatCountMismatch { expected, actual }) => {
                return XlsxWorkbookCommandAvailability::disabled(
                    DisabledReason::ClipboardPayloadFormatCountMismatch { expected, actual },
                );
            }
            Err(_) => {}
        }
        if let Err(XlsxWorkbookError::ClipboardPasteTargetOverflow {
            start_col,
            start_row,
            width,
            height,
        }) = request.target_range()
        {
            return XlsxWorkbookCommandAvailability::disabled(
                DisabledReason::ClipboardPasteTargetOverflow {
                    start_col,
                    start_row,
                    width,
                    height,
                },
            );
        }

        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_paste_clipboard_text(
        &self,
        request: &XlsxPasteClipboardTextRequest,
    ) -> XlsxWorkbookCommandAvailability {
        use XlsxWorkbookCommandDisabledReason as DisabledReason;

        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        if self.sheets.session_for_sheet(sheet_name).is_none() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::MissingSheet {
                sheet_name: sheet_name.to_owned(),
            });
        }

        match request
            .to_paste_request(request.source_sheet_name().to_owned())
            .map(|paste_request| paste_request.for_sheet(sheet_name.to_owned()))
        {
            Ok(paste_request) => {
                self.command_availability(&XlsxWorkbookCommand::paste_clipboard(paste_request))
            }
            Err(XlsxWorkbookError::ClipboardTextParseFailed { row, col, message }) => {
                XlsxWorkbookCommandAvailability::disabled(
                    DisabledReason::ClipboardTextParseFailed { row, col, message },
                )
            }
            Err(XlsxWorkbookError::ClipboardTextRangeOverflow {
                start_col,
                start_row,
                width,
                height,
            }) => XlsxWorkbookCommandAvailability::disabled(
                DisabledReason::ClipboardTextRangeOverflow {
                    start_col,
                    start_row,
                    width,
                    height,
                },
            ),
            Err(_) => XlsxWorkbookCommandAvailability::enabled(),
        }
    }
}

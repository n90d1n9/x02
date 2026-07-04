//! Format range behavior for workbook sessions.

use super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxFormatRangeRequest, XlsxRangeCellUpdate, XlsxSheetRangeEditRequest,
    XlsxSheetRangeEditResult, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Apply a format patch to the active sheet range as one undoable transaction.
    pub fn format_active_range(
        &mut self,
        request: XlsxFormatRangeRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.format_range(request)
    }

    /// Apply a format patch to a target sheet range as one undoable transaction.
    pub fn format_range(
        &mut self,
        request: XlsxFormatRangeRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        if request.patch().is_empty() {
            return Err(XlsxWorkbookError::EmptyFormatPatch);
        }

        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let range = request.range();
        let (updates, inverse_updates) = {
            let session = self.sheet_session(&sheet_name).ok_or_else(|| {
                XlsxWorkbookError::UnknownWorkbookSheet {
                    sheet_name: sheet_name.clone(),
                }
            })?;
            let mut updates = Vec::with_capacity(range.cell_count());
            let mut inverse_updates = Vec::with_capacity(range.cell_count());
            for position in range.positions() {
                let existing_cell = session.state().get_cell(&position);
                let current_format = existing_cell
                    .map(|cell| cell.format.clone())
                    .unwrap_or_default();
                updates.push(XlsxRangeCellUpdate::set_format(
                    request.patch().apply_to(&current_format),
                ));
                inverse_updates.push(
                    existing_cell
                        .map(|cell| {
                            XlsxRangeCellUpdate::set_with_format(
                                cell.raw_content.clone(),
                                cell.format.clone(),
                            )
                        })
                        .unwrap_or_else(XlsxRangeCellUpdate::clear),
                );
            }
            (updates, inverse_updates)
        };
        let range_request = XlsxSheetRangeEditRequest::new(
            request.transaction_id().clone(),
            request.operation_id_prefix().clone(),
            request.inverse_operation_id_prefix().clone(),
            request.actor_id().clone(),
            request.timestamp_ms(),
            range,
            updates,
            inverse_updates,
        )
        .for_sheet(sheet_name);

        self.apply_range_edit(range_request)
    }
}

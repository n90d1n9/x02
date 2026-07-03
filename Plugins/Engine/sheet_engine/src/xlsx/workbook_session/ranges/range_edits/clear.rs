//! Clear range behavior for workbook sessions.

use super::super::{super::XlsxWorkbookSession, inverse_updates_for_range};
use crate::{
    XlsxClearRangeRequest, XlsxRangeCellUpdate, XlsxSheetRangeEditRequest,
    XlsxSheetRangeEditResult, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Clear a rectangular range from the active sheet as one undoable transaction.
    pub fn clear_active_range(
        &mut self,
        request: XlsxClearRangeRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.clear_range(request)
    }

    /// Clear a rectangular range from a target sheet as one undoable transaction.
    pub fn clear_range(
        &mut self,
        request: XlsxClearRangeRequest,
    ) -> Result<XlsxSheetRangeEditResult, XlsxWorkbookError> {
        let sheet_name = request
            .target_sheet_name(&self.active_sheet_name)
            .to_owned();
        let range = request.range();
        let inverse_updates = inverse_updates_for_range(self, &sheet_name, range)?;
        let updates = vec![XlsxRangeCellUpdate::clear(); range.cell_count()];
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

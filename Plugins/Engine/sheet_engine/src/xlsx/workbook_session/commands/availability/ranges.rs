//! Range command availability rules.

use super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxClearRangeRequest, XlsxFormatRangeRequest, XlsxSheetRangeEditRequest,
    XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason,
};

impl XlsxWorkbookSession {
    pub(super) fn availability_for_range_edit(
        &self,
        request: &XlsxSheetRangeEditRequest,
    ) -> XlsxWorkbookCommandAvailability {
        use XlsxWorkbookCommandDisabledReason as DisabledReason;

        if request.update_count() != request.expected_cell_count()
            || request.inverse_update_count() != request.expected_cell_count()
        {
            return XlsxWorkbookCommandAvailability::disabled(
                DisabledReason::RangeEditCellCountMismatch {
                    expected: request.expected_cell_count(),
                    actual: request.update_count(),
                    inverse_actual: request.inverse_update_count(),
                },
            );
        }

        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_clear_range(
        &self,
        request: &XlsxClearRangeRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_format_range(
        &self,
        request: &XlsxFormatRangeRequest,
    ) -> XlsxWorkbookCommandAvailability {
        if request.patch().is_empty() {
            return XlsxWorkbookCommandAvailability::disabled(
                XlsxWorkbookCommandDisabledReason::EmptyFormatPatch,
            );
        }

        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }
}

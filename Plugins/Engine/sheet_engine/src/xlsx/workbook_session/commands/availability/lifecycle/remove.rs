//! Remove-sheet availability rules.

use super::super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxRemoveSheetRequest, XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason,
};

impl XlsxWorkbookSession {
    pub(in crate::xlsx::workbook_session::commands::availability) fn availability_for_remove_sheet(
        &self,
        request: &XlsxRemoveSheetRequest,
    ) -> XlsxWorkbookCommandAvailability {
        use XlsxWorkbookCommandDisabledReason as DisabledReason;

        let sheet_name = request.normalized_sheet_name();
        if self.sheet_count() <= 1 {
            return XlsxWorkbookCommandAvailability::disabled(
                DisabledReason::CannotRemoveLastSheet,
            );
        }
        if self.sheets.session_for_sheet(&sheet_name).is_none() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::MissingSheet {
                sheet_name,
            });
        }
        XlsxWorkbookCommandAvailability::enabled()
    }
}

//! Move-sheet availability rules.

use super::super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxMoveSheetRequest, XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason,
};

impl XlsxWorkbookSession {
    pub(in crate::xlsx::workbook_session::commands::availability) fn availability_for_move_sheet(
        &self,
        request: &XlsxMoveSheetRequest,
    ) -> XlsxWorkbookCommandAvailability {
        use XlsxWorkbookCommandDisabledReason as DisabledReason;

        let sheet_name = request.normalized_sheet_name();
        if self.sheets.session_for_sheet(&sheet_name).is_none() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::MissingSheet {
                sheet_name,
            });
        }
        if request.target_index() >= self.sheet_count() {
            return XlsxWorkbookCommandAvailability::disabled(
                DisabledReason::SheetIndexOutOfRange {
                    index: request.target_index(),
                    sheet_count: self.sheet_count(),
                },
            );
        }
        XlsxWorkbookCommandAvailability::enabled()
    }
}

//! Rename-sheet availability rules.

use super::super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxRenameSheetRequest, XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason,
};

impl XlsxWorkbookSession {
    pub(in crate::xlsx::workbook_session::commands::availability) fn availability_for_rename_sheet(
        &self,
        request: &XlsxRenameSheetRequest,
    ) -> XlsxWorkbookCommandAvailability {
        use XlsxWorkbookCommandDisabledReason as DisabledReason;

        let sheet_name = request.normalized_sheet_name();
        if self.sheets.session_for_sheet(&sheet_name).is_none() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::MissingSheet {
                sheet_name,
            });
        }

        let new_sheet_name = request.normalized_new_sheet_name();
        if new_sheet_name.is_empty() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::EmptySheetName);
        }
        if new_sheet_name != sheet_name && self.sheets.session_for_sheet(&new_sheet_name).is_some()
        {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::DuplicateSheetName {
                sheet_name: new_sheet_name,
            });
        }

        XlsxWorkbookCommandAvailability::enabled()
    }
}

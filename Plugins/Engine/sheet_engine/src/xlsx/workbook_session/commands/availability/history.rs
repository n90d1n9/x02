//! History command availability rules.

use super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxSheetHistoryRequest, XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason,
};

impl XlsxWorkbookSession {
    pub(super) fn availability_for_undo_sheet(
        &self,
        request: &XlsxSheetHistoryRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        let Some(session) = self.sheet_session(sheet_name) else {
            return XlsxWorkbookCommandAvailability::disabled(
                XlsxWorkbookCommandDisabledReason::MissingSheet {
                    sheet_name: sheet_name.to_owned(),
                },
            );
        };
        if session.can_undo() {
            XlsxWorkbookCommandAvailability::enabled()
        } else {
            XlsxWorkbookCommandAvailability::disabled(
                XlsxWorkbookCommandDisabledReason::NoUndoHistory {
                    sheet_name: sheet_name.to_owned(),
                },
            )
        }
    }

    pub(super) fn availability_for_redo_sheet(
        &self,
        request: &XlsxSheetHistoryRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        let Some(session) = self.sheet_session(sheet_name) else {
            return XlsxWorkbookCommandAvailability::disabled(
                XlsxWorkbookCommandDisabledReason::MissingSheet {
                    sheet_name: sheet_name.to_owned(),
                },
            );
        };
        if session.can_redo() {
            XlsxWorkbookCommandAvailability::enabled()
        } else {
            XlsxWorkbookCommandAvailability::disabled(
                XlsxWorkbookCommandDisabledReason::NoRedoHistory {
                    sheet_name: sheet_name.to_owned(),
                },
            )
        }
    }
}

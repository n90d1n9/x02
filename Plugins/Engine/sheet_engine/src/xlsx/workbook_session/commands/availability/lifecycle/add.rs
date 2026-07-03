//! Add-sheet availability rules.

use super::super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxAddSheetRequest, XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason,
    XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    pub(in crate::xlsx::workbook_session::commands::availability) fn availability_for_add_sheet(
        &self,
        request: &XlsxAddSheetRequest,
    ) -> XlsxWorkbookCommandAvailability {
        use XlsxWorkbookCommandDisabledReason as DisabledReason;

        let sheet_name = request.normalized_sheet_name();
        if sheet_name.is_empty() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::EmptySheetName);
        }
        if self.sheets.session_for_sheet(&sheet_name).is_some() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::DuplicateSheetName {
                sheet_name,
            });
        }

        let document_id = request.resolved_document_id(self.workbook_id(), &sheet_name);
        if document_id.as_str().trim().is_empty() {
            return XlsxWorkbookCommandAvailability::disabled(DisabledReason::EmptyDocumentId {
                sheet_name,
            });
        }
        if self
            .sheets
            .entries()
            .iter()
            .any(|entry| entry.document_id() == &document_id)
        {
            return XlsxWorkbookCommandAvailability::disabled(
                DisabledReason::DuplicateDocumentId { sheet_name },
            );
        }

        match request.insert_index(self.sheet_count()) {
            Ok(_) => XlsxWorkbookCommandAvailability::enabled(),
            Err(XlsxWorkbookError::SheetIndexOutOfRange { index, sheet_count }) => {
                XlsxWorkbookCommandAvailability::disabled(DisabledReason::SheetIndexOutOfRange {
                    index,
                    sheet_count,
                })
            }
            Err(_) => XlsxWorkbookCommandAvailability::enabled(),
        }
    }
}

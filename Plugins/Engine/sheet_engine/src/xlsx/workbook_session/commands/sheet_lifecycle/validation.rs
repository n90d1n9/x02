//! Validation helpers for sheet lifecycle workbook commands.

use super::super::super::XlsxWorkbookSession;
use crate::XlsxWorkbookError;
use waraq_core::DocumentId;

impl XlsxWorkbookSession {
    pub(in crate::xlsx::workbook_session::commands) fn sheet_index_or_error(
        &self,
        sheet_name: &str,
    ) -> Result<usize, XlsxWorkbookError> {
        self.sheets
            .entry_index(sheet_name)
            .ok_or_else(|| XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: sheet_name.trim().to_owned(),
            })
    }

    pub(super) fn ensure_valid_new_sheet_name(
        &self,
        sheet_name: &str,
    ) -> Result<(), XlsxWorkbookError> {
        if sheet_name.is_empty() {
            return Err(XlsxWorkbookError::EmptySheetName {
                index: self.sheet_count(),
            });
        }
        if self.sheets.session_for_sheet(sheet_name).is_some() {
            return Err(XlsxWorkbookError::DuplicateSheetName {
                name: sheet_name.to_owned(),
            });
        }
        Ok(())
    }

    pub(super) fn ensure_valid_new_document_id(
        &self,
        sheet_name: &str,
        document_id: &DocumentId,
    ) -> Result<(), XlsxWorkbookError> {
        if document_id.as_str().trim().is_empty() {
            return Err(XlsxWorkbookError::EmptySheetDocumentId {
                sheet_name: sheet_name.to_owned(),
            });
        }
        if self
            .sheets
            .entries()
            .iter()
            .any(|entry| entry.document_id() == document_id)
        {
            return Err(XlsxWorkbookError::DuplicateSheetDocumentId {
                sheet_name: sheet_name.to_owned(),
            });
        }
        Ok(())
    }
}

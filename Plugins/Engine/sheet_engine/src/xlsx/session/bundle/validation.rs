//! Validation rules for workbook sheet-session bundles.

use std::collections::BTreeSet;

use crate::XlsxWorkbookError;

use super::XlsxSheetSessionBundle;

impl XlsxSheetSessionBundle {
    pub(super) fn validate(&self) -> Result<(), XlsxWorkbookError> {
        if self.workbook_id.is_empty() {
            return Err(XlsxWorkbookError::EmptyWorkbookId);
        }
        if self.entries.is_empty() {
            return Err(XlsxWorkbookError::EmptyWorkbook);
        }

        let mut seen = BTreeSet::new();
        let mut document_ids = BTreeSet::new();
        for (index, entry) in self.entries.iter().enumerate() {
            let sheet_name = entry.sheet_name().trim();
            if sheet_name.is_empty() {
                return Err(XlsxWorkbookError::EmptySheetName { index });
            }
            if !seen.insert(sheet_name.to_owned()) {
                return Err(XlsxWorkbookError::DuplicateSheetName {
                    name: sheet_name.to_owned(),
                });
            }
            if entry.document_id().as_str().trim().is_empty() {
                return Err(XlsxWorkbookError::EmptySheetDocumentId {
                    sheet_name: sheet_name.to_owned(),
                });
            }
            if !document_ids.insert(entry.document_id().as_str().trim().to_owned()) {
                return Err(XlsxWorkbookError::DuplicateSheetDocumentId {
                    sheet_name: sheet_name.to_owned(),
                });
            }
        }

        Ok(())
    }
}

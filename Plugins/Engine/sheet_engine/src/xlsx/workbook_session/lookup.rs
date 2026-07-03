use crate::{SheetSession, XlsxSheetSessionEntry, XlsxWorkbookError};
use waraq_core::DocumentId;

use super::XlsxWorkbookSession;

impl XlsxWorkbookSession {
    /// Return the stable workbook identity.
    pub fn workbook_id(&self) -> &str {
        self.sheets.workbook_id()
    }

    /// Return all sheet names in workbook order.
    pub fn sheet_names(&self) -> Vec<&str> {
        self.sheets.sheet_names()
    }

    /// Return the number of sheet sessions in this workbook.
    pub fn sheet_count(&self) -> usize {
        self.sheets.sheet_count()
    }

    /// Return the currently active sheet name.
    pub fn active_sheet_name(&self) -> &str {
        &self.active_sheet_name
    }

    /// Return the active sheet session entry.
    pub fn active_sheet_entry(&self) -> Result<&XlsxSheetSessionEntry, XlsxWorkbookError> {
        self.sheet_entry(&self.active_sheet_name).ok_or_else(|| {
            XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: self.active_sheet_name.clone(),
            }
        })
    }

    /// Return the active editable sheet session.
    pub fn active_session(&self) -> Result<&SheetSession, XlsxWorkbookError> {
        Ok(self.active_sheet_entry()?.session())
    }

    /// Return the active editable sheet session as mutable state.
    pub fn active_session_mut(&mut self) -> Result<&mut SheetSession, XlsxWorkbookError> {
        let active_sheet_name = self.active_sheet_name.clone();
        self.sheet_session_mut(&active_sheet_name)
            .ok_or(XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: active_sheet_name,
            })
    }

    /// Find a sheet session entry by trimmed sheet name.
    pub fn sheet_entry(&self, sheet_name: &str) -> Option<&XlsxSheetSessionEntry> {
        self.sheets.session_for_sheet(sheet_name)
    }

    /// Find a mutable sheet session entry by trimmed sheet name.
    pub fn sheet_entry_mut(&mut self, sheet_name: &str) -> Option<&mut XlsxSheetSessionEntry> {
        self.sheets.session_for_sheet_mut(sheet_name)
    }

    /// Find an editable sheet session by trimmed sheet name.
    pub fn sheet_session(&self, sheet_name: &str) -> Option<&SheetSession> {
        self.sheet_entry(sheet_name)
            .map(XlsxSheetSessionEntry::session)
    }

    /// Find a mutable editable sheet session by trimmed sheet name.
    pub fn sheet_session_mut(&mut self, sheet_name: &str) -> Option<&mut SheetSession> {
        self.sheet_entry_mut(sheet_name)
            .map(XlsxSheetSessionEntry::session_mut)
    }

    /// Find the core document id for a sheet by trimmed sheet name.
    pub fn sheet_document_id(&self, sheet_name: &str) -> Option<&DocumentId> {
        self.sheet_entry(sheet_name)
            .map(XlsxSheetSessionEntry::document_id)
    }

    /// Return all sheet document ids in workbook order.
    pub fn sheet_document_ids(&self) -> Vec<(&str, &DocumentId)> {
        self.sheets
            .entries()
            .iter()
            .map(|entry| (entry.sheet_name(), entry.document_id()))
            .collect()
    }

    pub(crate) fn sheet_entries(&self) -> &[XlsxSheetSessionEntry] {
        self.sheets.entries()
    }
}

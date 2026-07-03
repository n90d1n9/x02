//! Sheet lifecycle mutations for workbook command handling.

mod validation;

use super::super::XlsxWorkbookSession;
use crate::{
    sheet_session, SheetGrid, XlsxAddSheetRequest, XlsxMoveSheetRequest, XlsxRemoveSheetRequest,
    XlsxRenameSheetRequest, XlsxSheetSessionEntry, XlsxWorkbookError,
};
use waraq_core::DocumentId;

impl XlsxWorkbookSession {
    /// Add a new sheet, select it, and return its core document id.
    pub fn add_sheet(
        &mut self,
        request: XlsxAddSheetRequest,
    ) -> Result<DocumentId, XlsxWorkbookError> {
        let sheet_name = request.normalized_sheet_name();
        self.ensure_valid_new_sheet_name(&sheet_name)?;

        let document_id = request.resolved_document_id(self.workbook_id(), &sheet_name);
        self.ensure_valid_new_document_id(&sheet_name, &document_id)?;

        let index = request.insert_index(self.sheet_count())?;
        let entry = XlsxSheetSessionEntry::from_session(
            sheet_name.clone(),
            sheet_session(document_id.clone(), SheetGrid::new(&sheet_name)),
        );
        self.sheets.insert_entry(index, entry)?;
        self.active_sheet_name = sheet_name;

        Ok(document_id)
    }

    /// Rename an existing sheet while preserving its core document id and history.
    pub fn rename_sheet(
        &mut self,
        request: XlsxRenameSheetRequest,
    ) -> Result<(), XlsxWorkbookError> {
        let sheet_name = request.normalized_sheet_name();
        let new_sheet_name = request.normalized_new_sheet_name();
        let index = self.sheet_index_or_error(&sheet_name)?;
        let old_sheet_name = self.sheets.entries()[index].sheet_name().to_owned();

        if new_sheet_name.is_empty() {
            return Err(XlsxWorkbookError::EmptySheetName { index });
        }
        if old_sheet_name == new_sheet_name {
            return Ok(());
        }
        if self.sheets.session_for_sheet(&new_sheet_name).is_some() {
            return Err(XlsxWorkbookError::DuplicateSheetName {
                name: new_sheet_name,
            });
        }

        let was_active = self.active_sheet_name == old_sheet_name;
        self.sheets.entries_mut()[index].rename(new_sheet_name.clone());
        if was_active {
            self.active_sheet_name = new_sheet_name;
        }
        Ok(())
    }

    /// Remove a sheet and return its detached sheet session entry.
    pub fn remove_sheet(
        &mut self,
        request: XlsxRemoveSheetRequest,
    ) -> Result<XlsxSheetSessionEntry, XlsxWorkbookError> {
        if self.sheet_count() <= 1 {
            return Err(XlsxWorkbookError::CannotRemoveLastSheet);
        }

        let sheet_name = request.normalized_sheet_name();
        let index = self.sheet_index_or_error(&sheet_name)?;
        let removed_sheet_name = self.sheets.entries()[index].sheet_name().to_owned();
        let was_active = self.active_sheet_name == removed_sheet_name;
        let removed = self.sheets.remove_entry_at(index)?;

        if was_active {
            let next_index = index.min(self.sheet_count().saturating_sub(1));
            self.active_sheet_name = self.sheets.entries()[next_index].sheet_name().to_owned();
        }

        Ok(removed)
    }

    /// Move a sheet to a new zero-based workbook index.
    pub fn move_sheet(&mut self, request: XlsxMoveSheetRequest) -> Result<(), XlsxWorkbookError> {
        let sheet_name = request.normalized_sheet_name();
        let from_index = self.sheet_index_or_error(&sheet_name)?;
        self.sheets.move_entry(from_index, request.target_index())
    }
}

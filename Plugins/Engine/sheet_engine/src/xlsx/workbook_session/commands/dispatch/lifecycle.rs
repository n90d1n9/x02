//! Lifecycle command result builders for workbook command dispatch.

use super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxAddSheetRequest, XlsxMoveSheetRequest, XlsxRemoveSheetRequest, XlsxRenameSheetRequest,
    XlsxWorkbookCommandResult, XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    pub(super) fn execute_select_sheet_command(
        &mut self,
        sheet_name: String,
    ) -> Result<XlsxWorkbookCommandResult, XlsxWorkbookError> {
        self.set_active_sheet(&sheet_name)?;
        Ok(XlsxWorkbookCommandResult::SheetSelected {
            sheet_name: self.active_sheet_name.clone(),
        })
    }

    pub(super) fn execute_add_sheet_command(
        &mut self,
        request: XlsxAddSheetRequest,
    ) -> Result<XlsxWorkbookCommandResult, XlsxWorkbookError> {
        let sheet_name = request.normalized_sheet_name();
        let document_id = self.add_sheet(request)?;
        let index = self
            .sheets
            .entry_index(&sheet_name)
            .expect("added sheet exists in workbook order");

        Ok(XlsxWorkbookCommandResult::SheetAdded {
            sheet_name,
            document_id,
            index,
        })
    }

    pub(super) fn execute_rename_sheet_command(
        &mut self,
        request: XlsxRenameSheetRequest,
    ) -> Result<XlsxWorkbookCommandResult, XlsxWorkbookError> {
        let sheet_name = request.normalized_sheet_name();
        let new_sheet_name = request.normalized_new_sheet_name();
        self.rename_sheet(request)?;
        let index = self.sheet_index_or_error(&new_sheet_name)?;

        Ok(XlsxWorkbookCommandResult::SheetRenamed {
            sheet_name,
            new_sheet_name,
            index,
        })
    }

    pub(super) fn execute_remove_sheet_command(
        &mut self,
        request: XlsxRemoveSheetRequest,
    ) -> Result<XlsxWorkbookCommandResult, XlsxWorkbookError> {
        let sheet_name = request.normalized_sheet_name();
        let index = if self.sheet_count() <= 1 {
            0
        } else {
            self.sheet_index_or_error(&sheet_name)?
        };
        let removed = self.remove_sheet(request)?;

        Ok(XlsxWorkbookCommandResult::SheetRemoved {
            sheet_name: removed.sheet_name().to_owned(),
            document_id: removed.document_id().clone(),
            index,
            active_sheet_name: self.active_sheet_name.clone(),
        })
    }

    pub(super) fn execute_move_sheet_command(
        &mut self,
        request: XlsxMoveSheetRequest,
    ) -> Result<XlsxWorkbookCommandResult, XlsxWorkbookError> {
        let sheet_name = request.normalized_sheet_name();
        let from_index = self.sheet_index_or_error(&sheet_name)?;
        let target_index = request.target_index();
        self.move_sheet(request)?;

        Ok(XlsxWorkbookCommandResult::SheetMoved {
            sheet_name,
            from_index,
            target_index,
        })
    }
}

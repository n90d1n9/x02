//! Sheet edit command availability rules.

use super::super::super::XlsxWorkbookSession;
use crate::{
    XlsxSheetEditRequest, XlsxSheetStructureEditRequest, XlsxUndoableSheetEditRequest,
    XlsxUndoableSheetStructureEditRequest, XlsxWorkbookCommandAvailability,
};

impl XlsxWorkbookSession {
    pub(super) fn availability_for_sheet_edit(
        &self,
        request: &XlsxSheetEditRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_sheet_structure_edit(
        &self,
        request: &XlsxSheetStructureEditRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_undoable_sheet_edit(
        &self,
        request: &XlsxUndoableSheetEditRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }

    pub(super) fn availability_for_undoable_sheet_structure_edit(
        &self,
        request: &XlsxUndoableSheetStructureEditRequest,
    ) -> XlsxWorkbookCommandAvailability {
        let sheet_name = request.target_sheet_name(&self.active_sheet_name);
        self.availability_for_existing_sheet(sheet_name)
    }
}

//! Structure edit routing with typed workbook metadata.

use super::super::XlsxWorkbookSession;
use crate::{
    SheetEdit, XlsxSheetEditRequest, XlsxSheetStructureEditRequest, XlsxSheetStructureEditResult,
    XlsxWorkbookError,
};

impl XlsxWorkbookSession {
    /// Apply a row or column structure edit to the active sheet.
    pub fn apply_active_sheet_structure_edit(
        &mut self,
        request: XlsxSheetStructureEditRequest,
    ) -> Result<XlsxSheetStructureEditResult, XlsxWorkbookError> {
        let request = request.for_sheet(self.active_sheet_name.clone());
        self.apply_sheet_structure_edit(request)
    }

    /// Route a row or column structure edit to its target sheet with typed metadata.
    pub fn apply_sheet_structure_edit(
        &mut self,
        request: XlsxSheetStructureEditRequest,
    ) -> Result<XlsxSheetStructureEditResult, XlsxWorkbookError> {
        let edit = request.edit();
        let mut sheet_request = XlsxSheetEditRequest::new(
            request.operation_id().clone(),
            request.actor_id().clone(),
            request.timestamp_ms(),
            SheetEdit::ApplyStructure { edit },
        );

        if let Some(sheet_name) = request.sheet_name() {
            sheet_request = sheet_request.for_sheet(sheet_name.to_owned());
        }

        let result = self.apply_sheet_edit(sheet_request)?;
        Ok(XlsxSheetStructureEditResult::from_sheet_edit_result(
            edit, result,
        ))
    }
}

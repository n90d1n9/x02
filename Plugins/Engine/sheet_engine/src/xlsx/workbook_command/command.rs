//! Typed workbook command enum and constructor helpers.

use serde::{Deserialize, Serialize};

use crate::{
    XlsxClearRangeRequest, XlsxCopyRangeRequest, XlsxCopyRangeTextRequest, XlsxFormatRangeRequest,
    XlsxPasteClipboardRequest, XlsxPasteClipboardTextRequest, XlsxSheetEditRequest,
    XlsxSheetHistoryRequest, XlsxSheetRangeEditRequest, XlsxSheetStructureEditRequest,
    XlsxUndoableSheetEditRequest, XlsxUndoableSheetStructureEditRequest,
};

use super::{
    XlsxAddSheetRequest, XlsxMoveSheetRequest, XlsxRemoveSheetRequest, XlsxRenameSheetRequest,
};

/// Product-facing command that can be routed through an XLSX workbook session.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload", rename_all = "snake_case")]
pub enum XlsxWorkbookCommand {
    /// Select an existing sheet for future active-sheet actions.
    SelectSheet { sheet_name: String },
    /// Add a sheet to the workbook.
    AddSheet(XlsxAddSheetRequest),
    /// Rename an existing sheet.
    RenameSheet(XlsxRenameSheetRequest),
    /// Remove an existing sheet.
    RemoveSheet(XlsxRemoveSheetRequest),
    /// Move a sheet in workbook order.
    MoveSheet(XlsxMoveSheetRequest),
    /// Copy a sheet range into a reusable clipboard payload.
    CopyRange(XlsxCopyRangeRequest),
    /// Copy a sheet range as spreadsheet-compatible text.
    CopyRangeAsText(XlsxCopyRangeTextRequest),
    /// Paste a copied clipboard payload into a sheet.
    PasteClipboard(XlsxPasteClipboardRequest),
    /// Paste spreadsheet-compatible text into a sheet.
    PasteClipboardText(XlsxPasteClipboardTextRequest),
    /// Apply a sheet edit without adding undo history.
    ApplySheetEdit(XlsxSheetEditRequest),
    /// Apply a row or column structure edit without adding undo history.
    ApplySheetStructureEdit(XlsxSheetStructureEditRequest),
    /// Apply a sheet edit and commit its inverse operations to undo history.
    ApplyUndoableSheetEdit(XlsxUndoableSheetEditRequest),
    /// Apply a row or column structure edit and commit an inverse transaction.
    ApplyUndoableSheetStructureEdit(XlsxUndoableSheetStructureEditRequest),
    /// Apply a multi-cell sheet edit as one undoable transaction.
    ApplyRangeEdit(XlsxSheetRangeEditRequest),
    /// Clear a range as one undoable transaction.
    ClearRange(XlsxClearRangeRequest),
    /// Apply a format patch to a range as one undoable transaction.
    FormatRange(XlsxFormatRangeRequest),
    /// Undo the latest transaction on a sheet.
    UndoSheet(XlsxSheetHistoryRequest),
    /// Redo the latest undone transaction on a sheet.
    RedoSheet(XlsxSheetHistoryRequest),
}

impl XlsxWorkbookCommand {
    /// Build a command that selects a workbook sheet.
    pub fn select_sheet(sheet_name: impl Into<String>) -> Self {
        Self::SelectSheet {
            sheet_name: sheet_name.into(),
        }
    }

    /// Build a command that adds a workbook sheet.
    pub fn add_sheet(request: XlsxAddSheetRequest) -> Self {
        Self::AddSheet(request)
    }

    /// Build a command that renames a workbook sheet.
    pub fn rename_sheet(request: XlsxRenameSheetRequest) -> Self {
        Self::RenameSheet(request)
    }

    /// Build a command that removes a workbook sheet.
    pub fn remove_sheet(request: XlsxRemoveSheetRequest) -> Self {
        Self::RemoveSheet(request)
    }

    /// Build a command that moves a workbook sheet.
    pub fn move_sheet(request: XlsxMoveSheetRequest) -> Self {
        Self::MoveSheet(request)
    }

    /// Build a command that copies a sheet range.
    pub fn copy_range(request: XlsxCopyRangeRequest) -> Self {
        Self::CopyRange(request)
    }

    /// Build a command that copies a sheet range as text.
    pub fn copy_range_as_text(request: XlsxCopyRangeTextRequest) -> Self {
        Self::CopyRangeAsText(request)
    }

    /// Build a command that pastes a clipboard payload.
    pub fn paste_clipboard(request: XlsxPasteClipboardRequest) -> Self {
        Self::PasteClipboard(request)
    }

    /// Build a command that pastes spreadsheet-compatible text.
    pub fn paste_clipboard_text(request: XlsxPasteClipboardTextRequest) -> Self {
        Self::PasteClipboardText(request)
    }

    /// Build a command that applies a sheet edit.
    pub fn apply_sheet_edit(request: XlsxSheetEditRequest) -> Self {
        Self::ApplySheetEdit(request)
    }

    /// Build a command that applies a row or column structure edit.
    pub fn apply_sheet_structure_edit(request: XlsxSheetStructureEditRequest) -> Self {
        Self::ApplySheetStructureEdit(request)
    }

    /// Build a command that applies a sheet edit with undo history.
    pub fn apply_undoable_sheet_edit(request: XlsxUndoableSheetEditRequest) -> Self {
        Self::ApplyUndoableSheetEdit(request)
    }

    /// Build a command that applies an undoable row or column structure edit.
    pub fn apply_undoable_sheet_structure_edit(
        request: XlsxUndoableSheetStructureEditRequest,
    ) -> Self {
        Self::ApplyUndoableSheetStructureEdit(request)
    }

    /// Build a command that applies a multi-cell range edit.
    pub fn apply_range_edit(request: XlsxSheetRangeEditRequest) -> Self {
        Self::ApplyRangeEdit(request)
    }

    /// Build a command that clears a sheet range.
    pub fn clear_range(request: XlsxClearRangeRequest) -> Self {
        Self::ClearRange(request)
    }

    /// Build a command that applies a format patch to a sheet range.
    pub fn format_range(request: XlsxFormatRangeRequest) -> Self {
        Self::FormatRange(request)
    }

    /// Build a command that undoes sheet history.
    pub fn undo_sheet(request: XlsxSheetHistoryRequest) -> Self {
        Self::UndoSheet(request)
    }

    /// Build a command that redoes sheet history.
    pub fn redo_sheet(request: XlsxSheetHistoryRequest) -> Self {
        Self::RedoSheet(request)
    }
}

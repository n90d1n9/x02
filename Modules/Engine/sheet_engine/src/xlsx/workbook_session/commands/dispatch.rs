//! Command dispatch and command delta generation for workbook sessions.

mod delta;
mod lifecycle;

use super::super::XlsxWorkbookSession;
use crate::{XlsxWorkbookCommand, XlsxWorkbookCommandResult, XlsxWorkbookError};

impl XlsxWorkbookSession {
    /// Execute a product-facing workbook command and return a typed result.
    pub fn execute_command(
        &mut self,
        command: XlsxWorkbookCommand,
    ) -> Result<XlsxWorkbookCommandResult, XlsxWorkbookError> {
        match command {
            XlsxWorkbookCommand::SelectSheet { sheet_name } => {
                self.execute_select_sheet_command(sheet_name)
            }
            XlsxWorkbookCommand::AddSheet(request) => self.execute_add_sheet_command(request),
            XlsxWorkbookCommand::RenameSheet(request) => self.execute_rename_sheet_command(request),
            XlsxWorkbookCommand::RemoveSheet(request) => self.execute_remove_sheet_command(request),
            XlsxWorkbookCommand::MoveSheet(request) => self.execute_move_sheet_command(request),
            XlsxWorkbookCommand::ApplySheetEdit(request) => self
                .apply_sheet_edit(request)
                .map(XlsxWorkbookCommandResult::SheetEdit),
            XlsxWorkbookCommand::ApplySheetStructureEdit(request) => self
                .apply_sheet_structure_edit(request)
                .map(XlsxWorkbookCommandResult::SheetStructureEdit),
            XlsxWorkbookCommand::ApplyUndoableSheetEdit(request) => self
                .apply_undoable_sheet_edit(request)
                .map(XlsxWorkbookCommandResult::UndoableSheetEdit),
            XlsxWorkbookCommand::ApplyUndoableSheetStructureEdit(request) => self
                .apply_undoable_sheet_structure_edit(request)
                .map(XlsxWorkbookCommandResult::UndoableSheetStructureEdit),
            XlsxWorkbookCommand::CopyRange(request) => self
                .copy_range(request)
                .map(XlsxWorkbookCommandResult::ClipboardCopied),
            XlsxWorkbookCommand::CopyRangeAsText(request) => self
                .copy_range_as_text(request)
                .map(XlsxWorkbookCommandResult::ClipboardTextCopied),
            XlsxWorkbookCommand::PasteClipboard(request) => self
                .paste_clipboard(request)
                .map(XlsxWorkbookCommandResult::ClipboardPasted),
            XlsxWorkbookCommand::PasteClipboardText(request) => self
                .paste_clipboard_text(request)
                .map(XlsxWorkbookCommandResult::ClipboardTextPasted),
            XlsxWorkbookCommand::ApplyRangeEdit(request) => self
                .apply_range_edit(request)
                .map(XlsxWorkbookCommandResult::SheetRangeEdit),
            XlsxWorkbookCommand::ClearRange(request) => self
                .clear_range(request)
                .map(XlsxWorkbookCommandResult::RangeCleared),
            XlsxWorkbookCommand::FormatRange(request) => self
                .format_range(request)
                .map(XlsxWorkbookCommandResult::RangeFormatted),
            XlsxWorkbookCommand::UndoSheet(request) => self
                .undo_sheet(request)
                .map(XlsxWorkbookCommandResult::SheetHistory),
            XlsxWorkbookCommand::RedoSheet(request) => self
                .redo_sheet(request)
                .map(XlsxWorkbookCommandResult::SheetHistory),
        }
    }
}

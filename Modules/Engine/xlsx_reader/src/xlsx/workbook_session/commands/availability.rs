//! Availability decisions for product-facing workbook commands.

use super::super::XlsxWorkbookSession;
use crate::{
    XlsxWorkbookCommand, XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason,
};

mod clipboard;
mod edits;
mod history;
mod lifecycle;
mod ranges;

impl XlsxWorkbookSession {
    /// Return whether a product-facing command can currently be executed.
    pub fn command_availability(
        &self,
        command: &XlsxWorkbookCommand,
    ) -> XlsxWorkbookCommandAvailability {
        match command {
            XlsxWorkbookCommand::SelectSheet { sheet_name } => {
                self.availability_for_existing_sheet(sheet_name.trim())
            }
            XlsxWorkbookCommand::AddSheet(request) => self.availability_for_add_sheet(request),
            XlsxWorkbookCommand::RenameSheet(request) => {
                self.availability_for_rename_sheet(request)
            }
            XlsxWorkbookCommand::RemoveSheet(request) => {
                self.availability_for_remove_sheet(request)
            }
            XlsxWorkbookCommand::MoveSheet(request) => self.availability_for_move_sheet(request),
            XlsxWorkbookCommand::CopyRange(request) => self.availability_for_copy_range(request),
            XlsxWorkbookCommand::CopyRangeAsText(request) => {
                self.availability_for_copy_range_text(request)
            }
            XlsxWorkbookCommand::PasteClipboard(request) => {
                self.availability_for_paste_clipboard(request)
            }
            XlsxWorkbookCommand::PasteClipboardText(request) => {
                self.availability_for_paste_clipboard_text(request)
            }
            XlsxWorkbookCommand::ApplySheetEdit(request) => {
                self.availability_for_sheet_edit(request)
            }
            XlsxWorkbookCommand::ApplySheetStructureEdit(request) => {
                self.availability_for_sheet_structure_edit(request)
            }
            XlsxWorkbookCommand::ApplyUndoableSheetEdit(request) => {
                self.availability_for_undoable_sheet_edit(request)
            }
            XlsxWorkbookCommand::ApplyUndoableSheetStructureEdit(request) => {
                self.availability_for_undoable_sheet_structure_edit(request)
            }
            XlsxWorkbookCommand::ApplyRangeEdit(request) => {
                self.availability_for_range_edit(request)
            }
            XlsxWorkbookCommand::ClearRange(request) => self.availability_for_clear_range(request),
            XlsxWorkbookCommand::FormatRange(request) => {
                self.availability_for_format_range(request)
            }
            XlsxWorkbookCommand::UndoSheet(request) => self.availability_for_undo_sheet(request),
            XlsxWorkbookCommand::RedoSheet(request) => self.availability_for_redo_sheet(request),
        }
    }

    /// Return true when a product-facing command is currently available.
    pub fn can_execute_command(&self, command: &XlsxWorkbookCommand) -> bool {
        self.command_availability(command).is_enabled()
    }

    fn availability_for_existing_sheet(&self, sheet_name: &str) -> XlsxWorkbookCommandAvailability {
        if self.sheets.session_for_sheet(sheet_name).is_some() {
            XlsxWorkbookCommandAvailability::enabled()
        } else {
            XlsxWorkbookCommandAvailability::disabled(
                XlsxWorkbookCommandDisabledReason::MissingSheet {
                    sheet_name: sheet_name.to_owned(),
                },
            )
        }
    }
}

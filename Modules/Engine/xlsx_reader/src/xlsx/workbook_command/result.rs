//! Typed results emitted by workbook command execution.

use serde::{Deserialize, Serialize};
use waraq_core::DocumentId;

use crate::{
    XlsxClipboardTextResult, XlsxSheetClipboardPayload, XlsxSheetEditResult,
    XlsxSheetHistoryResult, XlsxSheetRangeEditResult, XlsxSheetStructureEditResult,
    XlsxUndoableSheetEditResult, XlsxUndoableSheetStructureEditResult,
};

/// Result returned after executing a product-facing XLSX workbook command.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload", rename_all = "snake_case")]
pub enum XlsxWorkbookCommandResult {
    /// A sheet was selected as the active workbook sheet.
    SheetSelected { sheet_name: String },
    /// A sheet was added and selected.
    SheetAdded {
        sheet_name: String,
        document_id: DocumentId,
        index: usize,
    },
    /// A sheet was renamed in place.
    SheetRenamed {
        sheet_name: String,
        new_sheet_name: String,
        index: usize,
    },
    /// A sheet was removed and the workbook selected a remaining sheet.
    SheetRemoved {
        sheet_name: String,
        document_id: DocumentId,
        index: usize,
        active_sheet_name: String,
    },
    /// A sheet was moved in workbook order.
    SheetMoved {
        sheet_name: String,
        from_index: usize,
        target_index: usize,
    },
    /// A sheet range was copied to a clipboard payload.
    ClipboardCopied(XlsxSheetClipboardPayload),
    /// A sheet range was copied as spreadsheet-compatible text.
    ClipboardTextCopied(XlsxClipboardTextResult),
    /// A clipboard payload was pasted as one undoable range transaction.
    ClipboardPasted(XlsxSheetRangeEditResult),
    /// Spreadsheet-compatible text was pasted as one undoable range transaction.
    ClipboardTextPasted(XlsxSheetRangeEditResult),
    /// A regular sheet edit was applied.
    SheetEdit(XlsxSheetEditResult),
    /// A row or column structure edit was applied.
    SheetStructureEdit(XlsxSheetStructureEditResult),
    /// An undoable sheet edit transaction was applied.
    UndoableSheetEdit(XlsxUndoableSheetEditResult),
    /// An undoable row or column structure transaction was applied.
    UndoableSheetStructureEdit(XlsxUndoableSheetStructureEditResult),
    /// A multi-cell range edit transaction was applied.
    SheetRangeEdit(XlsxSheetRangeEditResult),
    /// A sheet range was cleared as one undoable transaction.
    RangeCleared(XlsxSheetRangeEditResult),
    /// A sheet range was formatted as one undoable transaction.
    RangeFormatted(XlsxSheetRangeEditResult),
    /// A history action was applied to a sheet.
    SheetHistory(XlsxSheetHistoryResult),
}

impl XlsxWorkbookCommandResult {
    /// Return the sheet name most directly affected by this command.
    pub fn sheet_name(&self) -> &str {
        match self {
            Self::SheetSelected { sheet_name }
            | Self::SheetAdded { sheet_name, .. }
            | Self::SheetRenamed { sheet_name, .. }
            | Self::SheetRemoved { sheet_name, .. }
            | Self::SheetMoved { sheet_name, .. } => sheet_name,
            Self::ClipboardCopied(result) => &result.source_sheet_name,
            Self::ClipboardTextCopied(result) => &result.sheet_name,
            Self::ClipboardPasted(result) => &result.sheet_name,
            Self::ClipboardTextPasted(result) => &result.sheet_name,
            Self::SheetEdit(result) => &result.sheet_name,
            Self::SheetStructureEdit(result) => &result.sheet_name,
            Self::UndoableSheetEdit(result) => &result.edit.sheet_name,
            Self::UndoableSheetStructureEdit(result) => &result.edit.sheet_name,
            Self::SheetRangeEdit(result) => &result.sheet_name,
            Self::RangeCleared(result) => &result.sheet_name,
            Self::RangeFormatted(result) => &result.sheet_name,
            Self::SheetHistory(result) => &result.sheet_name,
        }
    }
}

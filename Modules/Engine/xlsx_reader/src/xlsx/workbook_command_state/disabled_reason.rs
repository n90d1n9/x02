use serde::{Deserialize, Serialize};

/// Structured reason explaining why a workbook command is currently unavailable.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "reason", content = "detail", rename_all = "snake_case")]
pub enum XlsxWorkbookCommandDisabledReason {
    /// The command references a sheet that is not present in the workbook.
    MissingSheet { sheet_name: String },
    /// The command needs a non-empty sheet name.
    EmptySheetName,
    /// The command would create a duplicate sheet name.
    DuplicateSheetName { sheet_name: String },
    /// The command references a sheet index outside the workbook order.
    SheetIndexOutOfRange { index: usize, sheet_count: usize },
    /// The command would remove the only remaining sheet.
    CannotRemoveLastSheet,
    /// The target sheet has no undoable history.
    NoUndoHistory { sheet_name: String },
    /// The target sheet has no redoable history.
    NoRedoHistory { sheet_name: String },
    /// The command would assign an empty document identity to a sheet.
    EmptyDocumentId { sheet_name: String },
    /// The command would reuse an existing document identity for another sheet.
    DuplicateDocumentId { sheet_name: String },
    /// The clipboard payload does not match its declared source range.
    ClipboardPayloadCellCountMismatch { expected: usize, actual: usize },
    /// The clipboard payload formats do not match its declared source range.
    ClipboardPayloadFormatCountMismatch { expected: usize, actual: usize },
    /// The clipboard paste target cannot be represented by sheet coordinates.
    ClipboardPasteTargetOverflow {
        start_col: u32,
        start_row: u32,
        width: usize,
        height: usize,
    },
    /// The text clipboard payload cannot be parsed as tabular data.
    ClipboardTextParseFailed {
        row: usize,
        col: usize,
        message: String,
    },
    /// The decoded text clipboard source range cannot be represented.
    ClipboardTextRangeOverflow {
        start_col: u32,
        start_row: u32,
        width: usize,
        height: usize,
    },
    /// The command has a range update count that does not match the target range.
    RangeEditCellCountMismatch {
        expected: usize,
        actual: usize,
        inverse_actual: usize,
    },
    /// The command does not include any format field changes.
    EmptyFormatPatch,
}

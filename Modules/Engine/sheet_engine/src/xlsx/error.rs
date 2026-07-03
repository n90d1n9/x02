//! Error contract for the sheet engine XLSX workbook facade.

use waraq_core::ValidationReport;

mod conversion;
mod display;

#[cfg(test)]
mod tests;

/// Error type for the sheet engine XLSX workbook facade.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum XlsxWorkbookError {
    /// Workbook identity is empty or only whitespace.
    EmptyWorkbookId,
    /// Workbook request does not contain any sheets.
    EmptyWorkbook,
    /// A sheet name is empty after trimming whitespace.
    EmptySheetName { index: usize },
    /// A sheet name appears more than once after trimming whitespace.
    DuplicateSheetName { name: String },
    /// A grid with the same sheet name appears more than once.
    DuplicateGridName { name: String },
    /// A requested sheet has no matching grid in the export set.
    MissingGridForSheet { name: String },
    /// A sheet session request does not provide an identity for a workbook sheet.
    MissingSheetDocumentId { sheet_name: String },
    /// A sheet session request provides an empty core document identity.
    EmptySheetDocumentId { sheet_name: String },
    /// A sheet session request defines the same sheet identity more than once.
    DuplicateSheetDocumentId { sheet_name: String },
    /// A sheet session request references a sheet that is not present in the workbook.
    UnknownSheetDocumentId { sheet_name: String },
    /// A workbook session requested a sheet that is not present in the session bundle.
    UnknownWorkbookSheet { sheet_name: String },
    /// A workbook session requested a sheet index outside the available sheet order.
    SheetIndexOutOfRange { index: usize, sheet_count: usize },
    /// A workbook session tried to remove the only remaining sheet.
    CannotRemoveLastSheet,
    /// A routed sheet edit failed while being applied to the target sheet.
    SheetEditFailed { sheet_name: String, message: String },
    /// A copied clipboard payload has a different value count than its source range.
    ClipboardPayloadCellCountMismatch { expected: usize, actual: usize },
    /// A copied clipboard payload has a different format count than its source range.
    ClipboardPayloadFormatCountMismatch { expected: usize, actual: usize },
    /// A clipboard paste target range cannot be represented by sheet coordinates.
    ClipboardPasteTargetOverflow {
        start_col: u32,
        start_row: u32,
        width: usize,
        height: usize,
    },
    /// A text clipboard payload contains malformed tabular text.
    ClipboardTextParseFailed {
        row: usize,
        col: usize,
        message: String,
    },
    /// A decoded text clipboard source range cannot be represented by sheet coordinates.
    ClipboardTextRangeOverflow {
        start_col: u32,
        start_row: u32,
        width: usize,
        height: usize,
    },
    /// A routed sheet range edit has a different number of updates than cells.
    RangeEditCellCountMismatch {
        expected: usize,
        actual: usize,
        inverse_actual: usize,
    },
    /// A format range request does not include any format field changes.
    EmptyFormatPatch,
    /// A routed sheet range edit failed while being applied to the target sheet.
    SheetRangeEditFailed { sheet_name: String, message: String },
    /// A routed sheet history action failed while being applied to the target sheet.
    SheetHistoryFailed {
        sheet_name: String,
        action: String,
        message: String,
    },
    /// A workbook session snapshot failed core or workbook-level validation.
    InvalidWorkbookSnapshot(ValidationReport),
    /// A sheet grid column cannot be represented by the lower-level XLSX writer.
    ColumnOutOfRange { sheet: String, col: u32 },
    /// The underlying XLSX reader failed.
    ReadFailed(String),
    /// The underlying XLSX writer failed.
    WriteFailed(String),
}

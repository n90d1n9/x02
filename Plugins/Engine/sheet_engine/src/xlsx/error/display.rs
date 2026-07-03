//! Display implementation for XLSX workbook facade errors.

use std::fmt;

use super::XlsxWorkbookError;

impl fmt::Display for XlsxWorkbookError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::EmptyWorkbookId => write!(f, "workbook id must not be empty"),
            Self::EmptyWorkbook => write!(f, "workbook must contain at least one sheet"),
            Self::EmptySheetName { index } => {
                write!(f, "sheet name at index {index} must not be empty")
            }
            Self::DuplicateSheetName { name } => write!(f, "duplicate sheet name `{name}`"),
            Self::DuplicateGridName { name } => write!(f, "duplicate grid name `{name}`"),
            Self::MissingGridForSheet { name } => {
                write!(f, "missing sheet grid for requested sheet `{name}`")
            }
            Self::MissingSheetDocumentId { sheet_name } => {
                write!(f, "missing document id for sheet `{sheet_name}`")
            }
            Self::EmptySheetDocumentId { sheet_name } => {
                write!(f, "document id for sheet `{sheet_name}` must not be empty")
            }
            Self::DuplicateSheetDocumentId { sheet_name } => {
                write!(f, "duplicate document id mapping for sheet `{sheet_name}`")
            }
            Self::UnknownSheetDocumentId { sheet_name } => {
                write!(
                    f,
                    "document id mapping references unknown sheet `{sheet_name}`"
                )
            }
            Self::UnknownWorkbookSheet { sheet_name } => {
                write!(f, "workbook session has no sheet named `{sheet_name}`")
            }
            Self::SheetIndexOutOfRange { index, sheet_count } => {
                write!(
                    f,
                    "sheet index {index} is out of range for {sheet_count} sheet(s)"
                )
            }
            Self::CannotRemoveLastSheet => {
                write!(f, "workbook session must keep at least one sheet")
            }
            Self::SheetEditFailed {
                sheet_name,
                message,
            } => {
                write!(f, "failed to apply edit to sheet `{sheet_name}`: {message}")
            }
            Self::ClipboardPayloadCellCountMismatch { expected, actual } => {
                write!(
                    f,
                    "clipboard payload expected {expected} value(s), got {actual}"
                )
            }
            Self::ClipboardPayloadFormatCountMismatch { expected, actual } => {
                write!(
                    f,
                    "clipboard payload expected {expected} format value(s), got {actual}"
                )
            }
            Self::ClipboardPasteTargetOverflow {
                start_col,
                start_row,
                width,
                height,
            } => {
                write!(
                    f,
                    "clipboard paste at column {start_col}, row {start_row} with size {width}x{height} exceeds supported sheet coordinates"
                )
            }
            Self::ClipboardTextParseFailed { row, col, message } => {
                write!(
                    f,
                    "failed to parse clipboard text at row {row}, column {col}: {message}"
                )
            }
            Self::ClipboardTextRangeOverflow {
                start_col,
                start_row,
                width,
                height,
            } => {
                write!(
                    f,
                    "clipboard text range at column {start_col}, row {start_row} with size {width}x{height} exceeds supported sheet coordinates"
                )
            }
            Self::RangeEditCellCountMismatch {
                expected,
                actual,
                inverse_actual,
            } => {
                write!(
                    f,
                    "range edit expected {expected} update(s), got {actual} forward and {inverse_actual} inverse update(s)"
                )
            }
            Self::EmptyFormatPatch => write!(f, "format range patch must not be empty"),
            Self::SheetRangeEditFailed {
                sheet_name,
                message,
            } => {
                write!(
                    f,
                    "failed to apply range edit to sheet `{sheet_name}`: {message}"
                )
            }
            Self::SheetHistoryFailed {
                sheet_name,
                action,
                message,
            } => {
                write!(
                    f,
                    "failed to {action} history for sheet `{sheet_name}`: {message}"
                )
            }
            Self::InvalidWorkbookSnapshot(report) => {
                write!(
                    f,
                    "invalid workbook snapshot with {} validation error(s)",
                    report.error_count()
                )
            }
            Self::ColumnOutOfRange { sheet, col } => {
                write!(
                    f,
                    "column {col} in sheet `{sheet}` is out of XLSX writer range"
                )
            }
            Self::ReadFailed(message) => write!(f, "failed to read XLSX workbook: {message}"),
            Self::WriteFailed(message) => write!(f, "failed to write XLSX workbook: {message}"),
        }
    }
}

impl std::error::Error for XlsxWorkbookError {}

//! XLSX-facing workbook facade built on top of the sheet engine grid/session APIs.
//!
//! The parser and writer responsibilities stay in `ky-of-xlsx`; this module owns the
//! user-facing workbook commands, session import/export, clipboard, and range APIs.

pub mod error;
pub mod export;
pub mod grid;
pub mod grid_workbook;
pub mod import;
pub mod session;
pub mod workbook;
pub mod workbook_clipboard;
pub mod workbook_clipboard_text;
pub mod workbook_command;
pub mod workbook_command_state;
pub mod workbook_edit;
pub mod workbook_history;
pub mod workbook_range_clear;
pub mod workbook_range_edit;
pub mod workbook_range_format;
pub mod workbook_session;
pub mod workbook_snapshot;
pub mod workbook_status;
pub mod workbook_structure;

pub use error::XlsxWorkbookError;
pub use export::{new_write_request, write_empty_workbook};
pub use grid::{
    grid_to_write_request, import_grids_from_workbook, import_grids_from_workbook_bytes,
    write_grids_to_workbook, xlsx_cell_to_sheet_cell,
};
pub use grid_workbook::{import_grid_workbook_bytes, write_grid_workbook, XlsxGridWorkbook};
pub use import::{summarize_workbook, summarize_workbook_bytes, XlsxImportOptions};
pub use session::{
    import_sheet_sessions_from_workbook_bytes, XlsxSheetSessionBundle, XlsxSheetSessionEntry,
};
pub use workbook::{XlsxSheetSummary, XlsxWorkbookRequest, XlsxWorkbookSummary};
pub use workbook_clipboard::{
    XlsxCopyRangeRequest, XlsxPasteClipboardRequest, XlsxSheetClipboardPayload,
};
pub use workbook_clipboard_text::{
    XlsxClipboardLineEnding, XlsxClipboardTextCodec, XlsxClipboardTextOptions,
    XlsxClipboardTextResult, XlsxCopyRangeTextRequest, XlsxPasteClipboardTextRequest,
};
pub use workbook_command::{
    XlsxAddSheetRequest, XlsxMoveSheetRequest, XlsxRemoveSheetRequest, XlsxRenameSheetRequest,
    XlsxWorkbookCommand, XlsxWorkbookCommandResult,
};
pub use workbook_command_state::{
    XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDelta, XlsxWorkbookCommandDisabledReason,
    XlsxWorkbookCommandState,
};
pub use workbook_edit::{
    XlsxSheetEditRequest, XlsxSheetEditResult, XlsxUndoableSheetEditRequest,
    XlsxUndoableSheetEditResult,
};
pub use workbook_history::{
    XlsxSheetHistoryAction, XlsxSheetHistoryRequest, XlsxSheetHistoryResult,
};
pub use workbook_range_clear::XlsxClearRangeRequest;
pub use workbook_range_edit::{
    XlsxRangeCellUpdate, XlsxSheetRange, XlsxSheetRangeEditRequest, XlsxSheetRangeEditResult,
};
pub use workbook_range_format::{
    XlsxCellFormatPatch, XlsxFormatRangeRequest, XlsxOptionalStringFormatPatch,
};
pub use workbook_session::{
    import_workbook_session_from_bytes, write_workbook_session, XlsxWorkbookSession,
};
pub use workbook_snapshot::{XlsxWorkbookSheetSnapshot, XlsxWorkbookSnapshot};
pub use workbook_status::{XlsxSheetSessionStatus, XlsxWorkbookSessionStatus};
pub use workbook_structure::{
    XlsxSheetStructureEditRequest, XlsxSheetStructureEditResult,
    XlsxUndoableSheetStructureEditRequest, XlsxUndoableSheetStructureEditResult,
};

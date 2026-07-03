use super::*;
use crate::{
    sheet_operation, Cell, CellFormat, CellPosition, CellValue, SheetEdit, SheetGrid,
    SheetStructureEdit, XlsxAddSheetRequest, XlsxCellFormatPatch, XlsxClearRangeRequest,
    XlsxClipboardTextOptions, XlsxCopyRangeRequest, XlsxCopyRangeTextRequest,
    XlsxFormatRangeRequest, XlsxGridWorkbook, XlsxImportOptions, XlsxMoveSheetRequest,
    XlsxPasteClipboardRequest, XlsxPasteClipboardTextRequest, XlsxRangeCellUpdate,
    XlsxRemoveSheetRequest, XlsxRenameSheetRequest, XlsxSheetClipboardPayload,
    XlsxSheetEditRequest, XlsxSheetHistoryAction, XlsxSheetHistoryRequest, XlsxSheetRange,
    XlsxSheetRangeEditRequest, XlsxSheetSessionBundle, XlsxSheetStructureEditRequest,
    XlsxUndoableSheetEditRequest, XlsxUndoableSheetStructureEditRequest, XlsxWorkbookCommand,
    XlsxWorkbookCommandAvailability, XlsxWorkbookCommandDisabledReason, XlsxWorkbookCommandResult,
    XlsxWorkbookError, XlsxWorkbookSnapshot,
};
use waraq_core::DocumentId;
use ky-of-xlsx::writer::{write_xlsx, CellValue as WriterCellValue, XlsxWriteRequest};

mod clipboard;
mod commands;
mod history;
mod persistence;
mod range_edits;
mod sheet_edits;
mod structure_edits;

fn grid_with_cell(name: &str, col: u32, row: u32, value: &str) -> SheetGrid {
    let mut grid = SheetGrid::new(name);
    grid.set_cell(
        CellPosition::new(col, row),
        Cell {
            raw_content: value.to_owned(),
            evaluated_value: CellValue::String(value.to_owned()),
            format: CellFormat::default(),
        },
    );
    grid
}

fn workbook_session() -> XlsxWorkbookSession {
    let workbook = XlsxGridWorkbook::new(
        "book",
        [
            grid_with_cell("Data", 0, 0, "Revenue"),
            grid_with_cell("Calc", 1, 0, "Total"),
        ],
    )
    .expect("workbook");
    let sheets = XlsxSheetSessionBundle::from_grid_workbook(workbook);
    XlsxWorkbookSession::from_sheet_sessions(sheets)
}

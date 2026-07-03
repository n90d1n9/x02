use waraq_core::DocumentId;

use crate::{
    sheet_operation, Cell, CellFormat, CellPosition, CellValue, SheetEdit, SheetGrid,
    XlsxAddSheetRequest, XlsxGridWorkbook, XlsxSheetSessionBundle, XlsxWorkbookSession,
    XlsxWorkbookSessionStatus,
};

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

#[test]
fn summarizes_workbook_session_status() {
    let mut session = workbook_session();
    session
        .add_sheet(XlsxAddSheetRequest::new("Summary"))
        .expect("add sheet");
    session.set_active_sheet("Calc").expect("activate calc");
    session
        .active_session_mut()
        .expect("active session")
        .apply_operation(sheet_operation(
            "op-1",
            "book/Calc",
            "actor-1",
            1,
            1_000,
            SheetEdit::SetCell {
                position: CellPosition::new(2, 0),
                raw_content: "42".to_owned(),
            },
        ))
        .expect("edit");

    let status = session.status();

    assert_eq!(status.workbook_id, "book");
    assert_eq!(status.active_sheet_name, "Calc");
    assert_eq!(status.sheet_count, 3);
    assert_eq!(status.total_cell_count, 3);
    assert_eq!(status.dirty_sheet_count, 1);
    assert_eq!(status.pending_operation_count, 1);
    assert_eq!(status.operation_log_count, 1);
    assert!(status.is_dirty());
    assert!(status.has_pending_operations());
    assert!(!status.can_undo);
    assert!(!status.can_redo);
    assert_eq!(status.dirty_sheet_names(), vec!["Calc"]);

    let active = status.active_sheet().expect("active sheet");
    assert!(active.is_active);
    assert_eq!(active.document_id, DocumentId::new("book/Calc"));
    assert_eq!(active.cell_count, 2);
    assert_eq!(active.sequence, 1);
    assert_eq!(active.dirty_sequence_range, Some((1, 1)));
    assert!(
        status
            .sheet_by_name(" Summary ")
            .expect("summary")
            .selection_is_empty
    );
}

#[test]
fn workbook_session_status_json_roundtrips() {
    let status = workbook_session().status();

    let json = serde_json::to_string(&status).expect("json");
    let restored: XlsxWorkbookSessionStatus = serde_json::from_str(&json).expect("restored");

    assert_eq!(restored, status);
    assert!(!restored.is_dirty());
    assert_eq!(
        restored.active_sheet().expect("active").document_id,
        DocumentId::new("book/Data"),
    );
}

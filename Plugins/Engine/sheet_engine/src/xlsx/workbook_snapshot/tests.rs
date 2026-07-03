use super::*;
use crate::{sheet_session, Cell, CellPosition, SheetGrid, XlsxWorkbookError};
use waraq_core::{DocumentId, Validatable};

fn sheet_snapshot(sheet_name: &str, document_id: &str) -> XlsxWorkbookSheetSnapshot {
    let mut grid = SheetGrid::new(sheet_name);
    grid.set_cell(CellPosition::new(0, 0), Cell::new("Revenue"));
    let session = sheet_session(document_id, grid);
    XlsxWorkbookSheetSnapshot::new(sheet_name, session.snapshot(1_000))
}

#[test]
fn validates_workbook_snapshot_shape() {
    let snapshot = XlsxWorkbookSnapshot::new("book", "Data", [sheet_snapshot("Data", "book/Data")])
        .expect("snapshot");

    assert_eq!(snapshot.workbook_id(), "book");
    assert_eq!(snapshot.active_sheet_name(), "Data");
    assert_eq!(snapshot.sheet_names(), vec!["Data"]);
    assert_eq!(
        snapshot
            .sheet_by_name(" Data ")
            .expect("sheet")
            .document_id(),
        &DocumentId::new("book/Data"),
    );
}

#[test]
fn rejects_invalid_workbook_snapshot_shape() {
    let error = XlsxWorkbookSnapshot::new(
        "book",
        "Missing",
        [
            sheet_snapshot("Data", "book/Data"),
            sheet_snapshot(" Data ", "book/Data-2"),
        ],
    )
    .expect_err("invalid snapshot");

    let XlsxWorkbookError::InvalidWorkbookSnapshot(report) = error else {
        panic!("expected invalid snapshot report");
    };

    assert_eq!(report.error_count(), 2);
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "xlsx.snapshot.sheet_name.duplicate"));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "xlsx.snapshot.active_sheet.unknown"));
}

#[test]
fn workbook_snapshot_json_roundtrips() {
    let snapshot = XlsxWorkbookSnapshot::new("book", "Data", [sheet_snapshot("Data", "book/Data")])
        .expect("snapshot");

    let json = snapshot.to_json().expect("json");
    let restored = XlsxWorkbookSnapshot::from_json(&json).expect("restored");

    assert_eq!(restored.workbook_id(), snapshot.workbook_id());
    assert_eq!(restored.active_sheet_name(), snapshot.active_sheet_name());
    assert_eq!(restored.sheet_names(), snapshot.sheet_names());
    assert_eq!(
        restored
            .sheet_by_name("Data")
            .expect("sheet")
            .snapshot()
            .state
            .cell_count(),
        1,
    );
    assert!(restored.validate_report().is_valid());
}

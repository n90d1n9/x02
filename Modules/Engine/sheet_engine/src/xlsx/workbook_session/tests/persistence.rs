use super::*;

#[test]
fn converts_runtime_sessions_back_to_grid_workbook() {
    let mut session = workbook_session();
    session.set_active_sheet("Calc").expect("activate calc");
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .name = "Temporary UI name".to_owned();
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .set_cell(CellPosition::new(2, 0), Cell::new("42"));

    let workbook = session.to_grid_workbook().expect("grid workbook");

    assert_eq!(workbook.workbook_id(), "book");
    assert_eq!(workbook.sheet_names(), vec!["Data", "Calc"]);
    assert_eq!(
        workbook
            .sheet_by_name("Calc")
            .expect("calc")
            .get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "42",
    );
}

#[test]
fn imports_and_exports_workbook_session_bytes() {
    let mut request = XlsxWriteRequest::new(["Data"]);
    request.add_cell("Data", "A1", WriterCellValue::String("Revenue".to_owned()));
    let bytes = write_xlsx(&request).expect("xlsx bytes");

    let session = import_workbook_session_from_bytes("book", &bytes, XlsxImportOptions::new())
        .expect("session");
    let exported = write_workbook_session(&session).expect("exported bytes");
    let imported = import_workbook_session_from_bytes("book", &exported, XlsxImportOptions::new())
        .expect("reimported session");

    assert_eq!(imported.active_sheet_name(), "Data");
    assert_eq!(
        imported
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Revenue",
    );
}

#[test]
fn snapshots_and_restores_workbook_runtime_state() {
    let mut session = workbook_session();
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

    let snapshot = session.snapshot(2_000).expect("snapshot");
    let json = snapshot.to_json().expect("snapshot json");
    let snapshot = XlsxWorkbookSnapshot::from_json(&json).expect("restored snapshot");
    let restored = XlsxWorkbookSession::from_snapshot(snapshot).expect("restored session");

    assert_eq!(restored.workbook_id(), "book");
    assert_eq!(restored.active_sheet_name(), "Calc");
    assert_eq!(restored.sheet_names(), vec!["Data", "Calc"]);
    assert_eq!(
        restored
            .active_session()
            .expect("active session")
            .operation_log()
            .len(),
        1,
    );
    assert_eq!(
        restored
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "42",
    );
}

use sheet_engine::prelude::*;

fn grid_with_cell(name: &str, col: u32, row: u32, raw_content: &str) -> SheetGrid {
    let mut grid = SheetGrid::new(name);
    grid.set_cell(CellPosition::new(col, row), Cell::new(raw_content));
    grid
}

fn workbook_session() -> XlsxWorkbookSession {
    let workbook =
        XlsxGridWorkbook::new("book", [grid_with_cell("Data", 0, 0, "Revenue")]).expect("workbook");
    let sheets = XlsxSheetSessionBundle::from_grid_workbook(workbook);
    XlsxWorkbookSession::from_sheet_sessions(sheets)
}

#[test]
fn prelude_drives_xlsx_workbook_session_without_parser_crate() {
    let mut session = workbook_session();

    let added = session
        .execute_command(XlsxWorkbookCommand::add_sheet(XlsxAddSheetRequest::new(
            " Summary ",
        )))
        .expect("add sheet through facade");

    assert_eq!(
        added,
        XlsxWorkbookCommandResult::SheetAdded {
            sheet_name: "Summary".to_owned(),
            document_id: "book/Summary".into(),
            index: 1,
        },
    );

    let paste_delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::paste_clipboard_text(
            XlsxPasteClipboardTextRequest::new(
                "tx-paste",
                "paste-op",
                "paste-op-inverse",
                "actor-1",
                1_000,
                CellPosition::new(0, 0),
                "Total\t42",
            ),
        ))
        .expect("paste clipboard text through facade");

    assert_eq!(paste_delta.result.sheet_name(), "Summary");
    assert!(paste_delta.dirty_state_changed());
    assert!(paste_delta.history_state_changed());

    let copied = session
        .execute_command(XlsxWorkbookCommand::copy_range_as_text(
            XlsxCopyRangeTextRequest::new(XlsxSheetRange::new(
                CellPosition::new(0, 0),
                CellPosition::new(1, 0),
            )),
        ))
        .expect("copy range text through facade");

    let XlsxWorkbookCommandResult::ClipboardTextCopied(copied) = copied else {
        panic!("expected copied text result");
    };
    assert_eq!(copied.sheet_name, "Summary");
    assert_eq!(copied.text, "Total\t42");

    let bytes = write_workbook_session(&session).expect("write workbook session");
    let restored =
        import_workbook_session_from_bytes("book-restored", &bytes, XlsxImportOptions::new())
            .expect("restore workbook session");

    assert_eq!(restored.sheet_count(), 2);
    assert_eq!(restored.sheet_names(), vec!["Data", "Summary"]);
}

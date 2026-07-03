use super::*;

#[test]
fn tracks_active_sheet_and_session_lookup() {
    let mut session = workbook_session();

    assert_eq!(session.workbook_id(), "book");
    assert_eq!(session.sheet_count(), 2);
    assert_eq!(session.sheet_names(), vec!["Data", "Calc"]);
    assert_eq!(session.active_sheet_name(), "Data");
    assert_eq!(
        session.sheet_document_id(" Calc "),
        Some(&DocumentId::new("book/Calc")),
    );

    session.set_active_sheet(" Calc ").expect("activate calc");

    assert_eq!(session.active_sheet_name(), "Calc");
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .document_id(),
        &DocumentId::new("book/Calc"),
    );

    assert_eq!(
        session
            .set_active_sheet("Missing")
            .expect_err("missing sheet"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

#[test]
fn executes_sheet_lifecycle_commands_with_typed_results() {
    let mut session = workbook_session();

    let added = session
        .execute_command(XlsxWorkbookCommand::add_sheet(
            XlsxAddSheetRequest::new(" Summary ").at_index(1),
        ))
        .expect("add sheet command");

    assert_eq!(
        added,
        XlsxWorkbookCommandResult::SheetAdded {
            sheet_name: "Summary".to_owned(),
            document_id: DocumentId::new("book/Summary"),
            index: 1,
        },
    );
    assert_eq!(added.sheet_name(), "Summary");
    assert_eq!(session.sheet_names(), vec!["Data", "Summary", "Calc"]);
    assert_eq!(session.active_sheet_name(), "Summary");

    let selected = session
        .execute_command(XlsxWorkbookCommand::select_sheet(" Calc "))
        .expect("select sheet command");

    assert_eq!(
        selected,
        XlsxWorkbookCommandResult::SheetSelected {
            sheet_name: "Calc".to_owned(),
        },
    );
    assert_eq!(session.active_sheet_name(), "Calc");

    let renamed = session
        .execute_command(XlsxWorkbookCommand::rename_sheet(
            XlsxRenameSheetRequest::new("Summary", "Forecast"),
        ))
        .expect("rename sheet command");

    assert_eq!(
        renamed,
        XlsxWorkbookCommandResult::SheetRenamed {
            sheet_name: "Summary".to_owned(),
            new_sheet_name: "Forecast".to_owned(),
            index: 1,
        },
    );

    let moved = session
        .execute_command(XlsxWorkbookCommand::move_sheet(XlsxMoveSheetRequest::new(
            "Forecast", 0,
        )))
        .expect("move sheet command");

    assert_eq!(
        moved,
        XlsxWorkbookCommandResult::SheetMoved {
            sheet_name: "Forecast".to_owned(),
            from_index: 1,
            target_index: 0,
        },
    );
    assert_eq!(session.sheet_names(), vec!["Forecast", "Data", "Calc"]);

    let removed = session
        .execute_command(XlsxWorkbookCommand::remove_sheet(
            XlsxRemoveSheetRequest::new("Forecast"),
        ))
        .expect("remove sheet command");

    assert_eq!(
        removed,
        XlsxWorkbookCommandResult::SheetRemoved {
            sheet_name: "Forecast".to_owned(),
            document_id: DocumentId::new("book/Summary"),
            index: 0,
            active_sheet_name: "Calc".to_owned(),
        },
    );
    assert_eq!(session.sheet_names(), vec!["Data", "Calc"]);
    assert_eq!(session.active_sheet_name(), "Calc");

    let json = serde_json::to_string(&removed).expect("command result json");
    let restored: XlsxWorkbookCommandResult =
        serde_json::from_str(&json).expect("restored command result");
    assert_eq!(restored, removed);
}

#[test]
fn reports_command_state_and_availability() {
    let session = workbook_session();

    let state = session.command_state();
    assert_eq!(state.active_sheet_name, "Data");
    assert_eq!(state.sheet_count, 2);
    assert!(state.can_remove_sheet);
    assert!(!state.can_undo);
    assert!(!state.can_redo);

    let undo = session.command_availability(&XlsxWorkbookCommand::undo_sheet(
        XlsxSheetHistoryRequest::new(2_000),
    ));
    assert_eq!(
        undo,
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::NoUndoHistory {
                sheet_name: "Data".to_owned(),
            },
        ),
    );
    assert!(
        !session.can_execute_command(&XlsxWorkbookCommand::undo_sheet(
            XlsxSheetHistoryRequest::new(2_000),
        ))
    );

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::add_sheet(XlsxAddSheetRequest::new(
            "Data"
        ),)),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::DuplicateSheetName {
                sheet_name: "Data".to_owned(),
            },
        ),
    );

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::move_sheet(XlsxMoveSheetRequest::new(
            "Calc", 4
        ),)),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::SheetIndexOutOfRange {
                index: 4,
                sheet_count: 2,
            },
        ),
    );
}

#[test]
fn execute_command_with_delta_reports_sheet_lifecycle_changes() {
    let mut session = workbook_session();

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::add_sheet(XlsxAddSheetRequest::new(
            "Summary",
        )))
        .expect("add sheet delta");

    assert_eq!(
        delta.result,
        XlsxWorkbookCommandResult::SheetAdded {
            sheet_name: "Summary".to_owned(),
            document_id: DocumentId::new("book/Summary"),
            index: 2,
        },
    );
    assert!(delta.availability_before.is_enabled());
    assert!(delta.active_sheet_changed());
    assert!(delta.sheet_count_changed());
    assert!(!delta.dirty_state_changed());
    assert_eq!(delta.state_before.active_sheet_name, "Data");
    assert_eq!(delta.state_after.active_sheet_name, "Summary");
    assert_eq!(delta.status_before.sheet_count, 2);
    assert_eq!(delta.status_after.sheet_count, 3);
}

#[test]
fn rejects_command_for_missing_selected_sheet() {
    let mut session = workbook_session();

    assert_eq!(
        session
            .execute_command(XlsxWorkbookCommand::select_sheet("Missing"))
            .expect_err("missing sheet command"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

#[test]
fn adds_sheet_at_requested_index_and_activates_it() {
    let mut session = workbook_session();

    let document_id = session
        .add_sheet(XlsxAddSheetRequest::new(" Summary ").at_index(1))
        .expect("add sheet");

    assert_eq!(document_id, DocumentId::new("book/Summary"));
    assert_eq!(session.sheet_names(), vec!["Data", "Summary", "Calc"]);
    assert_eq!(session.active_sheet_name(), "Summary");
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .name,
        "Summary",
    );
}

#[test]
fn rejects_invalid_added_sheet_names_and_document_ids() {
    let mut session = workbook_session();

    assert_eq!(
        session
            .add_sheet(XlsxAddSheetRequest::new("Data"))
            .expect_err("duplicate sheet"),
        XlsxWorkbookError::DuplicateSheetName {
            name: "Data".to_owned(),
        },
    );
    assert_eq!(
        session
            .add_sheet(XlsxAddSheetRequest::new(" ").at_index(2))
            .expect_err("empty sheet"),
        XlsxWorkbookError::EmptySheetName { index: 2 },
    );
    assert_eq!(
        session
            .add_sheet(XlsxAddSheetRequest::new("Summary").at_index(5))
            .expect_err("bad index"),
        XlsxWorkbookError::SheetIndexOutOfRange {
            index: 5,
            sheet_count: 2,
        },
    );
    assert_eq!(
        session
            .add_sheet(
                XlsxAddSheetRequest::new("Summary").with_document_id(DocumentId::new("book/Data")),
            )
            .expect_err("duplicate document id"),
        XlsxWorkbookError::DuplicateSheetDocumentId {
            sheet_name: "Summary".to_owned(),
        },
    );
}

#[test]
fn renames_active_sheet_without_losing_session_state() {
    let mut session = workbook_session();
    session.set_active_sheet("Calc").expect("activate calc");
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .set_cell(CellPosition::new(2, 0), Cell::new("42"));

    session
        .rename_sheet(XlsxRenameSheetRequest::new(" Calc ", "Totals"))
        .expect("rename sheet");

    assert_eq!(session.active_sheet_name(), "Totals");
    assert_eq!(session.sheet_names(), vec!["Data", "Totals"]);
    assert_eq!(
        session.sheet_document_id("Totals"),
        Some(&DocumentId::new("book/Calc")),
    );
    assert_eq!(
        session
            .sheet_session("Totals")
            .expect("renamed session")
            .state()
            .get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "42",
    );
    assert_eq!(
        session
            .rename_sheet(XlsxRenameSheetRequest::new("Totals", "Data"))
            .expect_err("duplicate rename"),
        XlsxWorkbookError::DuplicateSheetName {
            name: "Data".to_owned(),
        },
    );
}

#[test]
fn removes_active_sheet_and_selects_neighbor() {
    let mut session = workbook_session();
    session
        .add_sheet(XlsxAddSheetRequest::new("Summary"))
        .expect("add sheet");
    session.set_active_sheet("Calc").expect("activate calc");

    let removed = session
        .remove_sheet(XlsxRemoveSheetRequest::new(" Calc "))
        .expect("remove calc");

    assert_eq!(removed.sheet_name(), "Calc");
    assert_eq!(session.sheet_names(), vec!["Data", "Summary"]);
    assert_eq!(session.active_sheet_name(), "Summary");

    session
        .remove_sheet(XlsxRemoveSheetRequest::new("Summary"))
        .expect("remove summary");
    assert_eq!(
        session
            .remove_sheet(XlsxRemoveSheetRequest::new("Data"))
            .expect_err("last sheet"),
        XlsxWorkbookError::CannotRemoveLastSheet,
    );
}

#[test]
fn moves_sheet_without_changing_active_sheet() {
    let mut session = workbook_session();
    session
        .add_sheet(XlsxAddSheetRequest::new("Summary"))
        .expect("add sheet");

    session
        .move_sheet(XlsxMoveSheetRequest::new("Summary", 0))
        .expect("move sheet");

    assert_eq!(session.sheet_names(), vec!["Summary", "Data", "Calc"]);
    assert_eq!(session.active_sheet_name(), "Summary");
    assert_eq!(
        session
            .move_sheet(XlsxMoveSheetRequest::new("Data", 8))
            .expect_err("bad target"),
        XlsxWorkbookError::SheetIndexOutOfRange {
            index: 8,
            sheet_count: 3,
        },
    );
}

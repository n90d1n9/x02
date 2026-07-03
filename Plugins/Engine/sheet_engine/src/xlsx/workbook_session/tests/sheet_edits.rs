use super::*;

#[test]
fn executes_edit_and_history_commands() {
    let mut session = workbook_session();

    let applied = session
        .execute_command(XlsxWorkbookCommand::apply_undoable_sheet_edit(
            XlsxUndoableSheetEditRequest::new(
                "tx-1",
                "op-1",
                "op-1-inverse",
                "actor-1",
                1_000,
                SheetEdit::SetCell {
                    position: CellPosition::new(0, 0),
                    raw_content: "Updated".to_owned(),
                },
                SheetEdit::SetCell {
                    position: CellPosition::new(0, 0),
                    raw_content: "Revenue".to_owned(),
                },
            ),
        ))
        .expect("undoable edit command");

    let XlsxWorkbookCommandResult::UndoableSheetEdit(applied) = applied else {
        panic!("expected undoable edit result");
    };
    assert_eq!(applied.edit.sheet_name, "Data");
    assert_eq!(applied.edit.sequence, 1);

    let undone = session
        .execute_command(XlsxWorkbookCommand::undo_sheet(
            XlsxSheetHistoryRequest::new(2_000),
        ))
        .expect("undo command");

    let XlsxWorkbookCommandResult::SheetHistory(undone) = undone else {
        panic!("expected undo history result");
    };
    assert_eq!(undone.action, XlsxSheetHistoryAction::Undo);
    assert_eq!(undone.sheet_name, "Data");
    assert_eq!(undone.sequence, 2);
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Revenue",
    );

    let redone = session
        .execute_command(XlsxWorkbookCommand::redo_sheet(
            XlsxSheetHistoryRequest::new(3_000),
        ))
        .expect("redo command");

    let XlsxWorkbookCommandResult::SheetHistory(redone) = redone else {
        panic!("expected redo history result");
    };
    assert_eq!(redone.action, XlsxSheetHistoryAction::Redo);
    assert_eq!(redone.sheet_name, "Data");
    assert_eq!(redone.sequence, 3);
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Updated",
    );
}

#[test]
fn execute_command_with_delta_reports_edit_history_changes() {
    let mut session = workbook_session();

    let edit_delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::apply_undoable_sheet_edit(
            XlsxUndoableSheetEditRequest::new(
                "tx-1",
                "op-1",
                "op-1-inverse",
                "actor-1",
                1_000,
                SheetEdit::SetCell {
                    position: CellPosition::new(0, 0),
                    raw_content: "Updated".to_owned(),
                },
                SheetEdit::SetCell {
                    position: CellPosition::new(0, 0),
                    raw_content: "Revenue".to_owned(),
                },
            ),
        ))
        .expect("undoable edit delta");

    assert!(edit_delta.availability_before.is_enabled());
    assert!(!edit_delta.active_sheet_changed());
    assert!(!edit_delta.sheet_count_changed());
    assert!(edit_delta.dirty_state_changed());
    assert!(edit_delta.history_state_changed());
    assert!(!edit_delta.state_before.can_undo);
    assert!(edit_delta.state_after.can_undo);

    let undo_delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::undo_sheet(
            XlsxSheetHistoryRequest::new(2_000),
        ))
        .expect("undo delta");

    assert!(undo_delta.availability_before.is_enabled());
    assert!(undo_delta.history_state_changed());
    assert!(undo_delta.state_before.can_undo);
    assert!(!undo_delta.state_before.can_redo);
    assert!(!undo_delta.state_after.can_undo);
    assert!(undo_delta.state_after.can_redo);
}

#[test]
fn applies_edit_to_active_sheet_with_generated_sequence() {
    let mut session = workbook_session();

    let result = session
        .apply_active_sheet_edit(XlsxSheetEditRequest::new(
            "op-1",
            "actor-1",
            1_000,
            SheetEdit::SetCell {
                position: CellPosition::new(1, 0),
                raw_content: "120".to_owned(),
            },
        ))
        .expect("active edit");

    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.document_id, DocumentId::new("book/Data"));
    assert_eq!(result.sequence, 1);
    assert_eq!(result.timestamp_ms, 1_000);
    assert_eq!(result.outcome.changed_cells, vec![CellPosition::new(1, 0)]);
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .raw_content,
        "120",
    );
    assert_eq!(session.status().dirty_sheet_names(), vec!["Data"]);
    assert_eq!(session.status().pending_operation_count, 1);
}

#[test]
fn routes_edit_to_named_sheet_without_changing_active_sheet() {
    let mut session = workbook_session();

    let result = session
        .apply_sheet_edit(
            XlsxSheetEditRequest::new(
                "op-1",
                "actor-1",
                1_000,
                SheetEdit::SetCell {
                    position: CellPosition::new(2, 0),
                    raw_content: "42".to_owned(),
                },
            )
            .for_sheet(" Calc "),
        )
        .expect("named edit");

    assert_eq!(result.sheet_name, "Calc");
    assert_eq!(result.document_id, DocumentId::new("book/Calc"));
    assert_eq!(session.active_sheet_name(), "Data");
    assert_eq!(
        session
            .sheet_session("Calc")
            .expect("calc session")
            .state()
            .get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "42",
    );
    assert_eq!(session.status().dirty_sheet_names(), vec!["Calc"]);
}

#[test]
fn applies_undoable_edit_to_active_sheet_and_populates_history() {
    let mut session = workbook_session();

    let result = session
        .apply_active_undoable_sheet_edit(XlsxUndoableSheetEditRequest::new(
            "tx-1",
            "op-1",
            "op-1-inverse",
            "actor-1",
            1_000,
            SheetEdit::SetCell {
                position: CellPosition::new(0, 0),
                raw_content: "Updated".to_owned(),
            },
            SheetEdit::SetCell {
                position: CellPosition::new(0, 0),
                raw_content: "Revenue".to_owned(),
            },
        ))
        .expect("undoable edit");

    assert_eq!(result.transaction_id, "tx-1");
    assert_eq!(result.edit.sheet_name, "Data");
    assert_eq!(result.edit.sequence, 1);
    assert!(session.status().can_undo);
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Updated",
    );

    session
        .active_session_mut()
        .expect("active session")
        .undo(2_000)
        .expect("undo");
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Revenue",
    );
    assert!(session.status().can_redo);

    session
        .active_session_mut()
        .expect("active session")
        .redo(3_000)
        .expect("redo");
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Updated",
    );
}

#[test]
fn routes_undoable_edit_to_named_sheet_without_changing_active_sheet() {
    let mut session = workbook_session();

    let result = session
        .apply_undoable_sheet_edit(
            XlsxUndoableSheetEditRequest::new(
                "tx-1",
                "op-1",
                "op-1-inverse",
                "actor-1",
                1_000,
                SheetEdit::SetCell {
                    position: CellPosition::new(2, 0),
                    raw_content: "42".to_owned(),
                },
                SheetEdit::ClearCell {
                    position: CellPosition::new(2, 0),
                },
            )
            .for_sheet(" Calc "),
        )
        .expect("undoable named edit");

    assert_eq!(result.edit.sheet_name, "Calc");
    assert_eq!(session.active_sheet_name(), "Data");
    assert!(session
        .sheet_session("Calc")
        .expect("calc session")
        .can_undo());
    assert_eq!(session.status().dirty_sheet_names(), vec!["Calc"]);
}

#[test]
fn rejects_routed_edit_for_missing_sheet() {
    let mut session = workbook_session();

    assert_eq!(
        session
            .apply_sheet_edit(
                XlsxSheetEditRequest::new("op-1", "actor-1", 1_000, SheetEdit::Recalculate,)
                    .for_sheet("Missing"),
            )
            .expect_err("missing sheet"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

#[test]
fn reports_sheet_edit_apply_failure() {
    let mut session = workbook_session();

    let error = session
        .apply_active_sheet_edit(XlsxSheetEditRequest::new(
            "op-1",
            "actor-1",
            1_000,
            SheetEdit::SetCell {
                position: CellPosition::new(0, 0),
                raw_content: "=A1".to_owned(),
            },
        ))
        .expect_err("circular reference");

    let XlsxWorkbookError::SheetEditFailed {
        sheet_name,
        message,
    } = error
    else {
        panic!("expected sheet edit failure");
    };
    assert_eq!(sheet_name, "Data");
    assert!(message.contains("CircularReference"));
}

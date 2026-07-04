use super::*;

#[test]
fn undoes_and_redoes_active_sheet_at_workbook_level() {
    let mut session = workbook_session();

    session
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

    let undo = session.undo_active_sheet(2_000).expect("undo");

    assert_eq!(undo.action, XlsxSheetHistoryAction::Undo);
    assert_eq!(undo.sheet_name, "Data");
    assert_eq!(undo.document_id, DocumentId::new("book/Data"));
    assert_eq!(undo.sequence, 2);
    assert_eq!(undo.timestamp_ms, 2_000);
    assert_eq!(undo.outcome_count(), 1);
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

    let redo = session.redo_active_sheet(3_000).expect("redo");

    assert_eq!(redo.action, XlsxSheetHistoryAction::Redo);
    assert_eq!(redo.sheet_name, "Data");
    assert_eq!(redo.sequence, 3);
    assert_eq!(redo.timestamp_ms, 3_000);
    assert_eq!(redo.outcome_count(), 1);
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
fn routes_history_to_named_sheet_without_changing_active_sheet() {
    let mut session = workbook_session();

    session
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
            .for_sheet("Calc"),
        )
        .expect("undoable named edit");

    let undo = session
        .undo_sheet(XlsxSheetHistoryRequest::new(2_000).for_sheet(" Calc "))
        .expect("undo named sheet");

    assert_eq!(undo.action, XlsxSheetHistoryAction::Undo);
    assert_eq!(undo.sheet_name, "Calc");
    assert_eq!(undo.document_id, DocumentId::new("book/Calc"));
    assert_eq!(undo.sequence, 2);
    assert_eq!(undo.outcome_count(), 1);
    assert_eq!(session.active_sheet_name(), "Data");
    assert!(session
        .sheet_session("Calc")
        .expect("calc session")
        .state()
        .get_cell(&CellPosition::new(2, 0))
        .is_none());
}

#[test]
fn history_request_without_history_returns_empty_result() {
    let mut session = workbook_session();

    let result = session.undo_active_sheet(1_000).expect("empty undo");

    assert_eq!(result.action, XlsxSheetHistoryAction::Undo);
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.document_id, DocumentId::new("book/Data"));
    assert_eq!(result.sequence, 0);
    assert_eq!(result.timestamp_ms, 1_000);
    assert!(result.is_empty());
    assert!(!session.status().can_redo);
}

#[test]
fn rejects_history_for_missing_sheet() {
    let mut session = workbook_session();

    assert_eq!(
        session
            .undo_sheet(XlsxSheetHistoryRequest::new(1_000).for_sheet("Missing"))
            .expect_err("missing sheet"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

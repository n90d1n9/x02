use super::*;

#[test]
fn executes_structure_edit_through_workbook_command() {
    let mut session = workbook_session();
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(CellPosition::new(0, 0), Cell::new("10"));
        grid.set_cell(CellPosition::new(1, 0), Cell::new("=A1+5"));
    }

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::apply_sheet_edit(
            XlsxSheetEditRequest::new(
                "op-structure",
                "actor-1",
                1_000,
                SheetEdit::ApplyStructure {
                    edit: SheetStructureEdit::insert_columns(0, 1),
                },
            ),
        ))
        .expect("structure command");

    let XlsxWorkbookCommandResult::SheetEdit(result) = &delta.result else {
        panic!("expected sheet edit result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.sequence, 1);
    assert!(result.outcome.recalculated);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .raw_content,
        "10",
    );
    let formula = session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(2, 0))
        .expect("C1");
    assert_eq!(formula.raw_content, "=B1+5");
    assert_eq!(formula.evaluated_value, CellValue::Number(15.0));
}

#[test]
fn executes_dedicated_structure_edit_command_with_delta() {
    let mut session = workbook_session();
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(CellPosition::new(0, 0), Cell::new("10"));
        grid.set_cell(CellPosition::new(1, 0), Cell::new("=A1+5"));
    }

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::apply_sheet_structure_edit(
            XlsxSheetStructureEditRequest::new(
                "op-structure",
                "actor-1",
                1_000,
                SheetStructureEdit::insert_columns(0, 1),
            ),
        ))
        .expect("dedicated structure command");

    let XlsxWorkbookCommandResult::SheetStructureEdit(result) = &delta.result else {
        panic!("expected structure edit result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.document_id, DocumentId::new("book/Data"));
    assert_eq!(result.sequence, 1);
    assert_eq!(result.timestamp_ms, 1_000);
    assert_eq!(result.edit, SheetStructureEdit::insert_columns(0, 1));
    assert_eq!(result.changed_cell_count(), 3);
    assert_eq!(
        result.changed_cells(),
        &[
            CellPosition::new(0, 0),
            CellPosition::new(1, 0),
            CellPosition::new(2, 0),
        ],
    );
    assert!(result.outcome.recalculated);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert!(!delta.history_state_changed());
    assert_eq!(delta.result.sheet_name(), "Data");
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .raw_content,
        "10",
    );
    let formula = session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(2, 0))
        .expect("C1");
    assert_eq!(formula.raw_content, "=B1+5");
    assert_eq!(formula.evaluated_value, CellValue::Number(15.0));
}

#[test]
fn rejects_dedicated_structure_edit_command_for_missing_sheet() {
    let mut session = workbook_session();
    let request = XlsxSheetStructureEditRequest::new(
        "op-structure",
        "actor-1",
        1_000,
        SheetStructureEdit::insert_rows(0, 1),
    )
    .for_sheet(" Missing ");

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::apply_sheet_structure_edit(
            request.clone(),
        )),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::MissingSheet {
                sheet_name: "Missing".to_owned(),
            },
        ),
    );
    assert_eq!(
        session
            .apply_sheet_structure_edit(request)
            .expect_err("missing sheet"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

#[test]
fn undoable_structure_edit_restores_deleted_cells_formats_and_formulas() {
    let mut session = workbook_session();
    let mut deleted_format = CellFormat::default();
    deleted_format.bold = true;
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(CellPosition::new(0, 0), Cell::new("=A2"));
        grid.set_cell(CellPosition::new(0, 1), Cell::new("Deleted"));
        grid.get_cell_mut(&CellPosition::new(0, 1))
            .expect("A2")
            .format = deleted_format.clone();
        grid.set_cell(CellPosition::new(0, 2), Cell::new("Kept"));
    }

    let result = session
        .apply_active_undoable_sheet_structure_edit(XlsxUndoableSheetStructureEditRequest::new(
            "tx-structure",
            "op-structure",
            "undo-structure",
            "actor-1",
            1_000,
            SheetStructureEdit::delete_rows(1, 1),
        ))
        .expect("undoable structure edit");

    assert_eq!(result.transaction_id, "tx-structure");
    assert_eq!(result.edit.sheet_name, "Data");
    assert_eq!(result.inverse_operation_count, 2);
    assert_eq!(result.changed_cell_count(), 3);
    assert!(session.status().can_undo);
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "=#REF!",
    );
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 1))
            .expect("A2")
            .raw_content,
        "Kept",
    );

    let undo = session.undo_active_sheet(2_000).expect("undo structure");

    assert_eq!(undo.outcome_count(), 2);
    let grid = session.active_session().expect("active session").state();
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "=A2",
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .evaluated_value,
        CellValue::String("Deleted".to_owned()),
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 1))
            .expect("A2")
            .raw_content,
        "Deleted",
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 1)).expect("A2").format,
        deleted_format,
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 2))
            .expect("A3")
            .raw_content,
        "Kept",
    );
    assert!(session.status().can_redo);

    session.redo_active_sheet(3_000).expect("redo structure");
    let grid = session.active_session().expect("active session").state();
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "=#REF!",
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 1))
            .expect("A2")
            .raw_content,
        "Kept",
    );
    assert!(grid.get_cell(&CellPosition::new(0, 2)).is_none());
}

#[test]
fn executes_undoable_structure_edit_command_with_delta() {
    let mut session = workbook_session();
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(CellPosition::new(0, 0), Cell::new("10"));
        grid.set_cell(CellPosition::new(1, 0), Cell::new("=A1+5"));
    }

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::apply_undoable_sheet_structure_edit(
            XlsxUndoableSheetStructureEditRequest::new(
                "tx-structure",
                "op-structure",
                "undo-structure",
                "actor-1",
                1_000,
                SheetStructureEdit::insert_columns(0, 1),
            ),
        ))
        .expect("undoable structure command delta");

    let XlsxWorkbookCommandResult::UndoableSheetStructureEdit(result) = &delta.result else {
        panic!("expected undoable structure result");
    };
    assert_eq!(result.transaction_id, "tx-structure");
    assert_eq!(result.edit.sheet_name, "Data");
    assert_eq!(result.edit.edit, SheetStructureEdit::insert_columns(0, 1));
    assert_eq!(result.inverse_operation_count, 2);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert!(delta.history_state_changed());
    assert!(delta.state_after.can_undo);
    assert_eq!(delta.result.sheet_name(), "Data");
}

#[test]
fn rejects_undoable_structure_edit_command_for_missing_sheet() {
    let mut session = workbook_session();
    let request = XlsxUndoableSheetStructureEditRequest::new(
        "tx-structure",
        "op-structure",
        "undo-structure",
        "actor-1",
        1_000,
        SheetStructureEdit::insert_columns(0, 1),
    )
    .for_sheet(" Missing ");

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::apply_undoable_sheet_structure_edit(
            request.clone(),
        )),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::MissingSheet {
                sheet_name: "Missing".to_owned(),
            },
        ),
    );
    assert_eq!(
        session
            .apply_undoable_sheet_structure_edit(request)
            .expect_err("missing sheet"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

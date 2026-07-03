use super::*;

#[test]
fn applies_range_edit_as_single_undoable_transaction() {
    let mut session = workbook_session();
    let range = XlsxSheetRange::new(CellPosition::new(1, 0), CellPosition::new(2, 0));

    let result = session
        .apply_active_range_edit(XlsxSheetRangeEditRequest::new(
            "tx-range",
            "range-op",
            "range-op-inverse",
            "actor-1",
            1_000,
            range,
            vec![
                XlsxRangeCellUpdate::set("100"),
                XlsxRangeCellUpdate::set("200"),
            ],
            vec![XlsxRangeCellUpdate::clear(), XlsxRangeCellUpdate::clear()],
        ))
        .expect("range edit");

    assert_eq!(result.transaction_id, "tx-range");
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.start_sequence, 1);
    assert_eq!(result.end_sequence, 2);
    assert_eq!(result.operation_count(), 2);
    assert_eq!(
        result.changed_cells(),
        vec![CellPosition::new(1, 0), CellPosition::new(2, 0)],
    );
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .raw_content,
        "100",
    );
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "200",
    );
    assert!(session.status().can_undo);

    let undo = session.undo_active_sheet(2_000).expect("undo range");

    assert_eq!(undo.outcome_count(), 2);
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 0))
        .is_none());
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(2, 0))
        .is_none());
    assert!(session.status().can_redo);

    session.redo_active_sheet(3_000).expect("redo range");
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "200",
    );
}

#[test]
fn executes_range_edit_command_with_delta() {
    let mut session = workbook_session();
    let range = XlsxSheetRange::new(CellPosition::new(0, 1), CellPosition::new(1, 1));

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::apply_range_edit(
            XlsxSheetRangeEditRequest::new(
                "tx-range",
                "range-op",
                "range-op-inverse",
                "actor-1",
                1_000,
                range,
                vec![
                    XlsxRangeCellUpdate::set("North"),
                    XlsxRangeCellUpdate::set("South"),
                ],
                vec![XlsxRangeCellUpdate::clear(), XlsxRangeCellUpdate::clear()],
            ),
        ))
        .expect("range command delta");

    let XlsxWorkbookCommandResult::SheetRangeEdit(result) = &delta.result else {
        panic!("expected range edit result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.operation_count(), 2);
    assert_eq!(result.end_sequence, 2);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert!(delta.history_state_changed());
    assert!(delta.state_after.can_undo);
    assert_eq!(delta.result.sheet_name(), "Data");
}

#[test]
fn clears_range_as_undoable_transaction_and_restores_cells_on_undo() {
    let mut session = workbook_session();
    let mut format = CellFormat::default();
    format.bold = true;
    format.background_color = Some("#ffeeaa".to_owned());
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(CellPosition::new(1, 0), Cell::new("10"));
        grid.get_cell_mut(&CellPosition::new(1, 0))
            .expect("B1")
            .format = format.clone();
        grid.set_cell(CellPosition::new(2, 0), Cell::new("=B1+5"));
    }
    let range = XlsxSheetRange::new(CellPosition::new(1, 0), CellPosition::new(2, 0));

    let result = session
        .clear_active_range(XlsxClearRangeRequest::new(
            "tx-clear",
            "clear-op",
            "clear-op-inverse",
            "actor-1",
            1_000,
            range,
        ))
        .expect("clear range");

    assert_eq!(result.transaction_id, "tx-clear");
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.start_sequence, 1);
    assert_eq!(result.end_sequence, 2);
    assert_eq!(result.operation_count(), 2);
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 0))
        .is_none());
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(2, 0))
        .is_none());
    assert!(session.status().can_undo);

    let undo = session.undo_active_sheet(2_000).expect("undo clear");

    assert_eq!(undo.outcome_count(), 2);
    let grid = session.active_session().expect("active session").state();
    let restored_value = grid.get_cell(&CellPosition::new(1, 0)).expect("B1");
    assert_eq!(restored_value.raw_content, "10");
    assert_eq!(restored_value.format, format);
    let restored_formula = grid.get_cell(&CellPosition::new(2, 0)).expect("C1");
    assert_eq!(restored_formula.raw_content, "=B1+5");
    assert_eq!(restored_formula.evaluated_value, CellValue::Number(15.0));
    assert!(session.status().can_redo);

    session.redo_active_sheet(3_000).expect("redo clear");
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 0))
        .is_none());
}

#[test]
fn executes_clear_range_command_with_delta() {
    let mut session = workbook_session();
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .set_cell(CellPosition::new(1, 0), Cell::new("Clear me"));

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::clear_range(
            XlsxClearRangeRequest::new(
                "tx-clear",
                "clear-op",
                "clear-op-inverse",
                "actor-1",
                1_000,
                XlsxSheetRange::single(CellPosition::new(1, 0)),
            ),
        ))
        .expect("clear command delta");

    let XlsxWorkbookCommandResult::RangeCleared(result) = &delta.result else {
        panic!("expected range cleared result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.operation_count(), 1);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert!(delta.history_state_changed());
    assert!(delta.state_after.can_undo);
    assert_eq!(delta.result.sheet_name(), "Data");
}

#[test]
fn rejects_clear_range_command_for_missing_sheet() {
    let mut session = workbook_session();
    let request = XlsxClearRangeRequest::new(
        "tx-clear",
        "clear-op",
        "clear-op-inverse",
        "actor-1",
        1_000,
        XlsxSheetRange::single(CellPosition::new(1, 0)),
    )
    .for_sheet(" Missing ");

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::clear_range(request.clone())),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::MissingSheet {
                sheet_name: "Missing".to_owned(),
            },
        ),
    );
    assert_eq!(
        session.clear_range(request).expect_err("missing sheet"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

#[test]
fn formats_range_as_undoable_transaction_and_restores_formats_on_undo() {
    let mut session = workbook_session();
    let mut original_format = CellFormat::default();
    original_format.italic = true;
    original_format.number_format = Some("0.00".to_owned());
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(CellPosition::new(1, 0), Cell::new("10"));
        grid.get_cell_mut(&CellPosition::new(1, 0))
            .expect("B1")
            .format = original_format.clone();
        grid.set_cell(CellPosition::new(2, 0), Cell::new("=B1+5"));
    }
    let patch = XlsxCellFormatPatch::new()
        .bold(true)
        .background_color("#ffeeaa")
        .text_color("#111111");
    let range = XlsxSheetRange::new(CellPosition::new(1, 0), CellPosition::new(3, 0));

    let result = session
        .format_active_range(XlsxFormatRangeRequest::new(
            "tx-format",
            "format-op",
            "format-op-inverse",
            "actor-1",
            1_000,
            range,
            patch,
        ))
        .expect("format range");

    assert_eq!(result.transaction_id, "tx-format");
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.operation_count(), 3);
    assert_eq!(result.start_sequence, 1);
    assert_eq!(result.end_sequence, 3);
    let grid = session.active_session().expect("active session").state();
    let formatted_value = grid.get_cell(&CellPosition::new(1, 0)).expect("B1");
    assert_eq!(formatted_value.raw_content, "10");
    assert!(formatted_value.format.bold);
    assert!(formatted_value.format.italic);
    assert_eq!(
        formatted_value.format.background_color.as_deref(),
        Some("#ffeeaa"),
    );
    assert_eq!(
        formatted_value.format.number_format.as_deref(),
        Some("0.00"),
    );
    let formatted_formula = grid.get_cell(&CellPosition::new(2, 0)).expect("C1");
    assert_eq!(formatted_formula.raw_content, "=B1+5");
    assert!(formatted_formula.format.bold);
    assert!(grid.get_cell(&CellPosition::new(3, 0)).is_some());
    assert!(session.status().can_undo);

    let undo = session.undo_active_sheet(2_000).expect("undo format");

    assert_eq!(undo.outcome_count(), 3);
    let grid = session.active_session().expect("active session").state();
    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 0)).expect("B1").format,
        original_format,
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(2, 0)).expect("C1").format,
        CellFormat::default(),
    );
    assert!(grid.get_cell(&CellPosition::new(3, 0)).is_none());
    assert!(session.status().can_redo);

    session.redo_active_sheet(3_000).expect("redo format");
    assert!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .format
            .bold
    );
}

#[test]
fn executes_format_range_command_with_delta() {
    let mut session = workbook_session();
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .set_cell(CellPosition::new(1, 0), Cell::new("Format me"));

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::format_range(
            XlsxFormatRangeRequest::new(
                "tx-format",
                "format-op",
                "format-op-inverse",
                "actor-1",
                1_000,
                XlsxSheetRange::single(CellPosition::new(1, 0)),
                XlsxCellFormatPatch::new().bold(true),
            ),
        ))
        .expect("format command delta");

    let XlsxWorkbookCommandResult::RangeFormatted(result) = &delta.result else {
        panic!("expected range formatted result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.operation_count(), 1);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert!(delta.history_state_changed());
    assert!(delta.state_after.can_undo);
    assert_eq!(delta.result.sheet_name(), "Data");
}

#[test]
fn rejects_format_range_with_empty_patch() {
    let mut session = workbook_session();
    let request = XlsxFormatRangeRequest::new(
        "tx-format",
        "format-op",
        "format-op-inverse",
        "actor-1",
        1_000,
        XlsxSheetRange::single(CellPosition::new(1, 0)),
        XlsxCellFormatPatch::new(),
    );

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::format_range(request.clone())),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::EmptyFormatPatch,
        ),
    );
    assert_eq!(
        session.format_range(request).expect_err("empty patch"),
        XlsxWorkbookError::EmptyFormatPatch,
    );
}

#[test]
fn rejects_format_range_command_for_missing_sheet() {
    let mut session = workbook_session();
    let request = XlsxFormatRangeRequest::new(
        "tx-format",
        "format-op",
        "format-op-inverse",
        "actor-1",
        1_000,
        XlsxSheetRange::single(CellPosition::new(1, 0)),
        XlsxCellFormatPatch::new().italic(true),
    )
    .for_sheet(" Missing ");

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::format_range(request.clone())),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::MissingSheet {
                sheet_name: "Missing".to_owned(),
            },
        ),
    );
    assert_eq!(
        session.format_range(request).expect_err("missing sheet"),
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Missing".to_owned(),
        },
    );
}

#[test]
fn rejects_range_edit_with_mismatched_cell_counts() {
    let mut session = workbook_session();
    let range = XlsxSheetRange::new(CellPosition::new(0, 0), CellPosition::new(1, 0));
    let request = XlsxSheetRangeEditRequest::new(
        "tx-range",
        "range-op",
        "range-op-inverse",
        "actor-1",
        1_000,
        range,
        vec![XlsxRangeCellUpdate::set("Only one")],
        vec![XlsxRangeCellUpdate::clear(), XlsxRangeCellUpdate::clear()],
    );

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::apply_range_edit(request.clone())),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::RangeEditCellCountMismatch {
                expected: 2,
                actual: 1,
                inverse_actual: 2,
            },
        ),
    );
    assert_eq!(
        session
            .apply_range_edit(request)
            .expect_err("mismatched range edit"),
        XlsxWorkbookError::RangeEditCellCountMismatch {
            expected: 2,
            actual: 1,
            inverse_actual: 2,
        },
    );
}

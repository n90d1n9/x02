use super::*;

#[test]
fn copies_range_payload_in_row_major_order() {
    let mut session = workbook_session();
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .set_cell(CellPosition::new(1, 0), Cell::new("120"));

    let payload = session
        .copy_active_range(XlsxSheetRange::new(
            CellPosition::new(0, 0),
            CellPosition::new(1, 0),
        ))
        .expect("copy range");

    assert_eq!(payload.source_sheet_name, "Data");
    assert_eq!(payload.source_range.start(), CellPosition::new(0, 0));
    assert_eq!(payload.source_range.end(), CellPosition::new(1, 0));
    assert_eq!(payload.width(), 2);
    assert_eq!(payload.height(), 1);
    assert_eq!(
        payload.raw_values(),
        &[Some("Revenue".to_owned()), Some("120".to_owned())],
    );
    assert!(!payload.is_empty());
}

#[test]
fn pastes_clipboard_as_undoable_range_transaction() {
    let mut session = workbook_session();
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .set_cell(CellPosition::new(1, 0), Cell::new("120"));
    let payload = session
        .copy_active_range(XlsxSheetRange::new(
            CellPosition::new(0, 0),
            CellPosition::new(1, 0),
        ))
        .expect("copy range");

    let result = session
        .paste_clipboard(XlsxPasteClipboardRequest::new(
            "tx-paste",
            "paste-op",
            "paste-op-inverse",
            "actor-1",
            1_000,
            CellPosition::new(0, 1),
            payload,
        ))
        .expect("paste clipboard");

    assert_eq!(result.transaction_id, "tx-paste");
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.range.start(), CellPosition::new(0, 1));
    assert_eq!(result.range.end(), CellPosition::new(1, 1));
    assert_eq!(result.operation_count(), 2);
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(0, 1))
            .expect("A2")
            .raw_content,
        "Revenue",
    );
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(1, 1))
            .expect("B2")
            .raw_content,
        "120",
    );

    let undo = session.undo_active_sheet(2_000).expect("undo paste");

    assert_eq!(undo.outcome_count(), 2);
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(0, 1))
        .is_none());
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 1))
        .is_none());
}

#[test]
fn pastes_structured_clipboard_with_translated_formula_references() {
    let mut session = workbook_session();
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(CellPosition::new(0, 0), Cell::new("10"));
        grid.set_cell(CellPosition::new(1, 0), Cell::new("20"));
        grid.set_cell(CellPosition::new(2, 0), Cell::new("=A1+B1"));
        grid.set_cell(CellPosition::new(0, 1), Cell::new("100"));
        grid.set_cell(CellPosition::new(1, 1), Cell::new("200"));
    }
    let payload = session
        .copy_active_range(XlsxSheetRange::single(CellPosition::new(2, 0)))
        .expect("copy formula");

    session
        .paste_clipboard(XlsxPasteClipboardRequest::new(
            "tx-paste-formula",
            "paste-formula-op",
            "paste-formula-op-inverse",
            "actor-1",
            1_000,
            CellPosition::new(2, 1),
            payload,
        ))
        .expect("paste formula");

    let pasted = session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(2, 1))
        .expect("C2");
    assert_eq!(pasted.raw_content, "=A2+B2");
    assert_eq!(pasted.evaluated_value, CellValue::Number(300.0));
}

#[test]
fn pastes_structured_clipboard_with_cell_formats_and_restores_target_on_undo() {
    let mut session = workbook_session();
    let mut source_format = CellFormat::default();
    source_format.bold = true;
    source_format.background_color = Some("#ffeeaa".to_owned());
    let mut target_format = CellFormat::default();
    target_format.italic = true;
    target_format.text_color = Some("#334455".to_owned());
    {
        let grid = session
            .active_session_mut()
            .expect("active session")
            .state_mut();
        grid.set_cell(
            CellPosition::new(0, 0),
            Cell {
                raw_content: "Styled".to_owned(),
                evaluated_value: CellValue::String("Styled".to_owned()),
                format: source_format.clone(),
            },
        );
        grid.set_cell(
            CellPosition::new(1, 1),
            Cell {
                raw_content: "Target".to_owned(),
                evaluated_value: CellValue::String("Target".to_owned()),
                format: target_format.clone(),
            },
        );
    }
    let payload = session
        .copy_active_range(XlsxSheetRange::single(CellPosition::new(0, 0)))
        .expect("copy styled cell");

    assert_eq!(payload.formats(), &[Some(source_format.clone())]);

    session
        .paste_clipboard(XlsxPasteClipboardRequest::new(
            "tx-paste-format",
            "paste-format-op",
            "paste-format-op-inverse",
            "actor-1",
            1_000,
            CellPosition::new(1, 1),
            payload,
        ))
        .expect("paste styled cell");

    let pasted = session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 1))
        .expect("B2");
    assert_eq!(pasted.raw_content, "Styled");
    assert_eq!(pasted.format, source_format);

    session.undo_active_sheet(2_000).expect("undo styled paste");
    let restored = session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 1))
        .expect("B2 restored");
    assert_eq!(restored.raw_content, "Target");
    assert_eq!(restored.format, target_format);
}

#[test]
fn executes_clipboard_commands_with_delta() {
    let mut session = workbook_session();
    let copied = session
        .execute_command(XlsxWorkbookCommand::copy_range(XlsxCopyRangeRequest::new(
            XlsxSheetRange::single(CellPosition::new(0, 0)),
        )))
        .expect("copy command");
    let XlsxWorkbookCommandResult::ClipboardCopied(payload) = copied else {
        panic!("expected clipboard payload");
    };

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::paste_clipboard(
            XlsxPasteClipboardRequest::new(
                "tx-paste",
                "paste-op",
                "paste-op-inverse",
                "actor-1",
                1_000,
                CellPosition::new(1, 1),
                payload,
            ),
        ))
        .expect("paste command delta");

    let XlsxWorkbookCommandResult::ClipboardPasted(result) = &delta.result else {
        panic!("expected clipboard paste result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.operation_count(), 1);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert!(delta.history_state_changed());
    assert_eq!(delta.result.sheet_name(), "Data");
}

#[test]
fn rejects_paste_payload_with_mismatched_cell_count() {
    let mut session = workbook_session();
    let payload = XlsxSheetClipboardPayload::new(
        "Data",
        XlsxSheetRange::new(CellPosition::new(0, 0), CellPosition::new(1, 0)),
        vec![Some("Only one".to_owned())],
    );
    let request = XlsxPasteClipboardRequest::new(
        "tx-paste",
        "paste-op",
        "paste-op-inverse",
        "actor-1",
        1_000,
        CellPosition::new(0, 1),
        payload,
    );

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::paste_clipboard(request.clone())),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::ClipboardPayloadCellCountMismatch {
                expected: 2,
                actual: 1,
            },
        ),
    );
    assert_eq!(
        session
            .paste_clipboard(request)
            .expect_err("mismatched clipboard payload"),
        XlsxWorkbookError::ClipboardPayloadCellCountMismatch {
            expected: 2,
            actual: 1,
        },
    );
}

#[test]
fn rejects_paste_payload_with_mismatched_format_count() {
    let mut session = workbook_session();
    let payload = XlsxSheetClipboardPayload::new_with_formats(
        "Data",
        XlsxSheetRange::new(CellPosition::new(0, 0), CellPosition::new(1, 0)),
        vec![Some("One".to_owned()), Some("Two".to_owned())],
        vec![Some(CellFormat::default())],
    );
    let request = XlsxPasteClipboardRequest::new(
        "tx-paste",
        "paste-op",
        "paste-op-inverse",
        "actor-1",
        1_000,
        CellPosition::new(0, 1),
        payload,
    );

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::paste_clipboard(request.clone())),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::ClipboardPayloadFormatCountMismatch {
                expected: 2,
                actual: 1,
            },
        ),
    );
    assert_eq!(
        session
            .paste_clipboard(request)
            .expect_err("mismatched clipboard formats"),
        XlsxWorkbookError::ClipboardPayloadFormatCountMismatch {
            expected: 2,
            actual: 1,
        },
    );
}

#[test]
fn executes_copy_range_as_text_command() {
    let mut session = workbook_session();
    session
        .active_session_mut()
        .expect("active session")
        .state_mut()
        .set_cell(CellPosition::new(1, 0), Cell::new("North\tQ1"));

    let copied = session
        .execute_command(XlsxWorkbookCommand::copy_range_as_text(
            XlsxCopyRangeTextRequest::new(XlsxSheetRange::new(
                CellPosition::new(0, 0),
                CellPosition::new(1, 0),
            ))
            .with_options(XlsxClipboardTextOptions::new().with_trailing_newline()),
        ))
        .expect("copy text command");

    let XlsxWorkbookCommandResult::ClipboardTextCopied(result) = copied else {
        panic!("expected clipboard text result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.text, "Revenue\t\"North\tQ1\"\n");
}

#[test]
fn executes_paste_clipboard_text_command_with_delta() {
    let mut session = workbook_session();

    let delta = session
        .execute_command_with_delta(XlsxWorkbookCommand::paste_clipboard_text(
            XlsxPasteClipboardTextRequest::new(
                "tx-paste-text",
                "paste-text-op",
                "paste-text-op-inverse",
                "actor-1",
                1_000,
                CellPosition::new(0, 1),
                "North\tSouth\n100\t200",
            ),
        ))
        .expect("paste text command");

    let XlsxWorkbookCommandResult::ClipboardTextPasted(result) = &delta.result else {
        panic!("expected clipboard text paste result");
    };
    assert_eq!(result.sheet_name, "Data");
    assert_eq!(result.range.start(), CellPosition::new(0, 1));
    assert_eq!(result.range.end(), CellPosition::new(1, 2));
    assert_eq!(result.operation_count(), 4);
    assert!(delta.availability_before.is_enabled());
    assert!(delta.dirty_state_changed());
    assert!(delta.history_state_changed());
    assert_eq!(delta.result.sheet_name(), "Data");
    assert_eq!(
        session
            .active_session()
            .expect("active session")
            .state()
            .get_cell(&CellPosition::new(1, 2))
            .expect("B3")
            .raw_content,
        "200",
    );

    let undo = session.undo_active_sheet(2_000).expect("undo text paste");
    assert_eq!(undo.outcome_count(), 4);
    assert!(session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 2))
        .is_none());
}

#[test]
fn paste_clipboard_text_keeps_formula_references_literal() {
    let mut session = workbook_session();

    session
        .paste_clipboard_text(XlsxPasteClipboardTextRequest::new(
            "tx-paste-text-formula",
            "paste-text-formula-op",
            "paste-text-formula-op-inverse",
            "actor-1",
            1_000,
            CellPosition::new(1, 1),
            "=A1",
        ))
        .expect("paste text formula");

    let pasted = session
        .active_session()
        .expect("active session")
        .state()
        .get_cell(&CellPosition::new(1, 1))
        .expect("B2");
    assert_eq!(pasted.raw_content, "=A1");
    assert_eq!(
        pasted.evaluated_value,
        CellValue::String("Revenue".to_owned())
    );
}

#[test]
fn rejects_paste_clipboard_text_with_malformed_tsv() {
    let mut session = workbook_session();
    let request = XlsxPasteClipboardTextRequest::new(
        "tx-paste-text",
        "paste-text-op",
        "paste-text-op-inverse",
        "actor-1",
        1_000,
        CellPosition::new(0, 1),
        "\"A\"B",
    );

    assert_eq!(
        session.command_availability(&XlsxWorkbookCommand::paste_clipboard_text(request.clone(),)),
        XlsxWorkbookCommandAvailability::disabled(
            XlsxWorkbookCommandDisabledReason::ClipboardTextParseFailed {
                row: 1,
                col: 1,
                message: "unexpected character after closing quote".to_owned(),
            },
        ),
    );
    assert_eq!(
        session
            .paste_clipboard_text(request)
            .expect_err("malformed text clipboard"),
        XlsxWorkbookError::ClipboardTextParseFailed {
            row: 1,
            col: 1,
            message: "unexpected character after closing quote".to_owned(),
        },
    );
}

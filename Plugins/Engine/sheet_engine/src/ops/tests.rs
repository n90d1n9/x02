use crate::{
    sheet_operation, sheet_snapshot, Cell, CellFormat, CellPosition, CellValue, SheetEdit,
    SheetGrid, SheetOperation, SheetOperationLog, SheetSnapshot, SheetStructureEdit,
    SheetTransaction, SHEET_ENGINE_ID,
};
use waraq_core::Validatable;

#[test]
fn set_cell_edit_recalculates_dependents() {
    let mut grid = SheetGrid::new("Sheet 1");
    grid.apply_edit(SheetEdit::SetCell {
        position: CellPosition::new(0, 0),
        raw_content: "10".into(),
    })
    .unwrap();
    grid.apply_edit(SheetEdit::SetCell {
        position: CellPosition::new(1, 0),
        raw_content: "=A1+5".into(),
    })
    .unwrap();

    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 0))
            .unwrap()
            .evaluated_value,
        CellValue::Number(15.0)
    );

    grid.apply_edit(SheetEdit::SetCell {
        position: CellPosition::new(0, 0),
        raw_content: "20".into(),
    })
    .unwrap();
    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 0))
            .unwrap()
            .evaluated_value,
        CellValue::Number(25.0)
    );
}

#[test]
fn format_edit_does_not_recalculate() {
    let mut grid = SheetGrid::new("Sheet 1");
    let mut format = CellFormat::default();
    format.bold = true;

    let outcome = grid
        .apply_edit(SheetEdit::SetCellFormat {
            position: CellPosition::new(2, 3),
            format,
        })
        .unwrap();

    assert!(!outcome.recalculated);
    assert!(grid.get_cell(&CellPosition::new(2, 3)).unwrap().format.bold);
}

#[test]
fn set_cell_with_format_recalculates_and_keeps_format() {
    let mut grid = SheetGrid::new("Sheet 1");
    let mut format = CellFormat::default();
    format.bold = true;
    format.background_color = Some("#ffeeaa".to_owned());

    let outcome = grid
        .apply_edit(SheetEdit::SetCellWithFormat {
            position: CellPosition::new(0, 0),
            raw_content: "=1+2".into(),
            format,
        })
        .unwrap();
    let cell = grid.get_cell(&CellPosition::new(0, 0)).unwrap();

    assert!(outcome.recalculated);
    assert_eq!(cell.evaluated_value, CellValue::Number(3.0));
    assert!(cell.format.bold);
    assert_eq!(cell.format.background_color.as_deref(), Some("#ffeeaa"));
}

#[test]
fn clear_cell_edit_recalculates_grid_bounds() {
    let mut grid = SheetGrid::new("Sheet 1");
    grid.apply_edit(SheetEdit::SetCell {
        position: CellPosition::new(3, 4),
        raw_content: "1".into(),
    })
    .unwrap();
    grid.apply_edit(SheetEdit::ClearCell {
        position: CellPosition::new(3, 4),
    })
    .unwrap();

    assert_eq!(grid.cell_count(), 0);
    assert_eq!(grid.max_col, 0);
    assert_eq!(grid.max_row, 0);
}

#[test]
fn restore_cells_replaces_content_and_recalculates_once() {
    let mut grid = SheetGrid::new("Sheet 1");
    grid.apply_edit(SheetEdit::SetCell {
        position: CellPosition::new(0, 0),
        raw_content: "5".into(),
    })
    .unwrap();
    grid.apply_edit(SheetEdit::SetCell {
        position: CellPosition::new(1, 0),
        raw_content: "=A1*2".into(),
    })
    .unwrap();
    let cells = grid.to_snapshot().cells;

    grid.apply_edit(SheetEdit::SetCell {
        position: CellPosition::new(0, 0),
        raw_content: "7".into(),
    })
    .unwrap();

    let outcome = grid.apply_edit(SheetEdit::RestoreCells { cells }).unwrap();

    assert_eq!(
        outcome.changed_cells,
        vec![CellPosition::new(0, 0), CellPosition::new(1, 0)],
    );
    assert!(outcome.recalculated);
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 0))
            .unwrap()
            .evaluated_value,
        CellValue::Number(5.0),
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 0))
            .unwrap()
            .evaluated_value,
        CellValue::Number(10.0),
    );
}

#[test]
fn structure_edit_moves_cells_and_recalculates() {
    let mut grid = SheetGrid::new("Sheet 1");
    grid.set_cell(CellPosition::new(0, 0), Cell::new("10"));
    grid.set_cell(CellPosition::new(1, 0), Cell::new("=A1+5"));

    let outcome = grid
        .apply_edit(SheetEdit::ApplyStructure {
            edit: SheetStructureEdit::insert_columns(0, 1),
        })
        .unwrap();

    assert!(outcome.recalculated);
    assert!(outcome.changed_cells.contains(&CellPosition::new(0, 0)));
    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .raw_content,
        "10",
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "=B1+5",
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .evaluated_value,
        CellValue::Number(15.0),
    );
}

#[test]
fn sheet_edit_json_roundtrip() {
    let edit = SheetEdit::SetCell {
        position: CellPosition::new(3, 2),
        raw_content: "=A1+1".into(),
    };

    let json = serde_json::to_string(&edit).unwrap();
    let restored: SheetEdit = serde_json::from_str(&json).unwrap();

    match restored {
        SheetEdit::SetCell {
            position,
            raw_content,
        } => {
            assert_eq!(position, CellPosition::new(3, 2));
            assert_eq!(raw_content, "=A1+1");
        }
        _ => panic!("expected set cell edit"),
    }
}

#[test]
fn sheet_operation_roundtrip_and_apply() {
    let operation = sheet_operation(
        "op-1",
        "sheet-1",
        "actor-1",
        1,
        10_000,
        SheetEdit::SetCell {
            position: CellPosition::new(0, 0),
            raw_content: "=1+2".into(),
        },
    )
    .with_metadata_text("source", "test");

    assert_eq!(operation.engine, SHEET_ENGINE_ID);

    let json = operation.to_json().unwrap();
    let restored = SheetOperation::from_json(&json).unwrap();

    let mut grid = SheetGrid::new("Sheet 1");
    let outcome = grid.apply_operation(restored).unwrap();

    assert_eq!(outcome.changed_cells, vec![CellPosition::new(0, 0)]);
    assert!(outcome.recalculated);
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 0))
            .unwrap()
            .evaluated_value,
        CellValue::Number(3.0)
    );
}

#[test]
fn sheet_transaction_applies_operations_in_order() {
    let transaction = SheetTransaction::new("tx-1")
        .with_operation(sheet_operation(
            "op-1",
            "sheet-1",
            "actor-1",
            1,
            10_000,
            SheetEdit::SetCell {
                position: CellPosition::new(0, 0),
                raw_content: "10".into(),
            },
        ))
        .with_operation(sheet_operation(
            "op-2",
            "sheet-1",
            "actor-1",
            2,
            10_001,
            SheetEdit::SetCell {
                position: CellPosition::new(1, 0),
                raw_content: "=A1+5".into(),
            },
        ));

    transaction.validate().unwrap();

    let mut grid = SheetGrid::new("Sheet 1");
    let outcomes = waraq_core::apply_transaction(&mut grid, &transaction).unwrap();

    assert_eq!(outcomes.len(), 2);
    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 0))
            .unwrap()
            .evaluated_value,
        CellValue::Number(15.0)
    );
    assert_eq!(transaction.operation_log().operations.len(), 2);
}

#[test]
fn sheet_snapshot_roundtrips_sparse_grid_and_operation_log() {
    let mut grid = SheetGrid::new("Sheet 1");
    grid.set_cell(CellPosition::new(0, 0), Cell::new("10"));

    let mut operation_log = SheetOperationLog::new();
    operation_log.push(sheet_operation(
        "op-1",
        "sheet-1",
        "actor-1",
        1,
        10_000,
        SheetEdit::SetCell {
            position: CellPosition::new(0, 0),
            raw_content: "10".into(),
        },
    ));

    let snapshot = sheet_snapshot("sheet-1", 1, 10_001, grid, operation_log)
        .with_metadata_text("checkpoint", "autosave");
    let json = snapshot.to_json().unwrap();
    let restored = SheetSnapshot::from_json(&json).unwrap();

    assert_eq!(restored.engine, SHEET_ENGINE_ID);
    assert_eq!(restored.document_id, "sheet-1");
    assert_eq!(restored.state.name, "Sheet 1");
    assert_eq!(
        restored
            .state
            .get_cell(&CellPosition::new(0, 0))
            .unwrap()
            .raw_content,
        "10"
    );
    assert_eq!(restored.operation_log.len(), 1);
    assert!(restored.validate_report().is_valid());
}

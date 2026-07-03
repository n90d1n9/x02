use super::*;
use crate::{Cell, CellFormat, CellPosition, SheetGrid};

#[test]
fn insert_rows_moves_cells_formats_and_formula_references() {
    let mut grid = SheetGrid::new("Sheet 1");
    let mut format = CellFormat::default();
    format.bold = true;
    grid.set_cell(CellPosition::new(0, 2), Cell::new("Moved"));
    grid.set_cell(CellPosition::new(1, 2), Cell::new("=A3"));
    grid.get_cell_mut(&CellPosition::new(0, 2))
        .expect("A3")
        .format = format.clone();

    let changed = apply_sheet_structure_edit(&mut grid, SheetStructureEdit::insert_rows(1, 1))
        .expect("insert row");

    assert!(grid.get_cell(&CellPosition::new(0, 2)).is_none());
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 3))
            .expect("A4")
            .raw_content,
        "Moved",
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 3)).expect("A4").format,
        format,
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 3))
            .expect("B4")
            .raw_content,
        "=A4",
    );
    assert_eq!(
        changed,
        vec![
            CellPosition::new(0, 2),
            CellPosition::new(1, 2),
            CellPosition::new(0, 3),
            CellPosition::new(1, 3),
        ],
    );
}

#[test]
fn structure_edit_inverse_returns_opposite_axis_operation() {
    assert_eq!(
        SheetStructureEdit::insert_rows(2, 3).inverse(),
        SheetStructureEdit::delete_rows(2, 3),
    );
    assert_eq!(
        SheetStructureEdit::delete_columns(1, 2).inverse(),
        SheetStructureEdit::insert_columns(1, 2),
    );
}

#[test]
fn delete_columns_removes_cells_and_shifts_formula_references() {
    let mut grid = SheetGrid::new("Sheet 1");
    grid.set_cell(CellPosition::new(0, 0), Cell::new("10"));
    grid.set_cell(CellPosition::new(2, 0), Cell::new("30"));
    grid.set_cell(CellPosition::new(3, 0), Cell::new("=C1+A1"));

    apply_sheet_structure_edit(&mut grid, SheetStructureEdit::delete_columns(1, 1))
        .expect("delete column");

    assert!(grid.get_cell(&CellPosition::new(2, 0)).is_some());
    assert_eq!(
        grid.get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .raw_content,
        "30",
    );
    assert_eq!(
        grid.get_cell(&CellPosition::new(2, 0))
            .expect("C1")
            .raw_content,
        "=B1+A1",
    );
}

#[test]
fn delete_rows_marks_deleted_formula_references() {
    let mut grid = SheetGrid::new("Sheet 1");
    grid.set_cell(CellPosition::new(0, 0), Cell::new("=A2"));
    grid.set_cell(CellPosition::new(0, 1), Cell::new("Deleted"));

    apply_sheet_structure_edit(&mut grid, SheetStructureEdit::delete_rows(1, 1))
        .expect("delete row");

    assert_eq!(
        grid.get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "=#REF!",
    );
}

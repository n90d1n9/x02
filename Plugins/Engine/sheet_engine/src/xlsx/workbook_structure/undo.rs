//! Undo helpers for structure edits that can remove or move existing cells.

use crate::{
    apply_sheet_structure_edit, CellPosition, EvalError, SheetCellSnapshot, SheetEdit, SheetGrid,
    SheetStructureEdit,
};

/// Build inverse edits for a structure edit without mutating the live sheet grid.
pub(crate) fn inverse_edits_for_structure_undo(
    grid: &SheetGrid,
    edit: SheetStructureEdit,
) -> Result<Vec<SheetEdit>, EvalError> {
    let mut probe = grid.clone();
    let changed_positions = apply_sheet_structure_edit(&mut probe, edit)?;
    let restore_cells = restore_cells_for_positions(grid, &changed_positions);
    let mut inverse_edits = vec![SheetEdit::ApplyStructure {
        edit: edit.inverse(),
    }];

    if !restore_cells.is_empty() {
        inverse_edits.push(SheetEdit::RestoreCells {
            cells: restore_cells,
        });
    }

    Ok(inverse_edits)
}

fn restore_cells_for_positions(
    grid: &SheetGrid,
    positions: &[CellPosition],
) -> Vec<SheetCellSnapshot> {
    positions
        .iter()
        .filter_map(|position| {
            grid.get_cell(position).map(|cell| SheetCellSnapshot {
                position: *position,
                cell: cell.clone(),
            })
        })
        .collect()
}

//! Sparse grid application logic for sheet structure edits.

use crate::{
    shift_formula_references_for_structure, CellPosition, EvalError, SheetGrid, SheetStructureEdit,
};

use super::position::shifted_position;

/// Apply a structural edit to the sparse grid and return affected cells.
pub fn apply_sheet_structure_edit(
    grid: &mut SheetGrid,
    edit: SheetStructureEdit,
) -> Result<Vec<CellPosition>, EvalError> {
    if edit.is_noop() {
        return Ok(Vec::new());
    }

    let snapshot = grid.to_snapshot();
    let mut next = SheetGrid::new(snapshot.name);
    let mut changed_cells = Vec::new();

    for entry in snapshot.cells {
        let old_position = entry.position;
        let old_raw_content = entry.cell.raw_content.clone();
        let Some(new_position) = shifted_position(old_position, edit)? else {
            changed_cells.push(old_position);
            continue;
        };
        let mut cell = entry.cell;
        if cell.is_formula() {
            cell.raw_content =
                shift_formula_references_for_structure(&cell.raw_content, edit.formula_edit());
        }

        if old_position != new_position || old_raw_content != cell.raw_content {
            changed_cells.push(old_position);
            changed_cells.push(new_position);
        }
        next.set_cell(new_position, cell);
    }

    sort_and_deduplicate_positions(&mut changed_cells);
    *grid = next;
    Ok(changed_cells)
}

fn sort_and_deduplicate_positions(positions: &mut Vec<CellPosition>) {
    positions.sort_by_key(|position| (position.row, position.col));
    positions.dedup();
}

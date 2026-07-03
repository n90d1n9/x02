//! Sheet edit application and integration with the core operation applier trait.

use crate::{
    apply_sheet_structure_edit, Cell, EvalError, FormulaEvaluator, SheetEdit, SheetEditOutcome,
    SheetGrid, SheetOperation,
};
use waraq_core::OperationApplier;

/// Apply a typed sheet edit directly to a mutable grid.
pub fn apply_sheet_edit(
    grid: &mut SheetGrid,
    edit: SheetEdit,
) -> Result<SheetEditOutcome, EvalError> {
    match edit {
        SheetEdit::SetCell {
            position,
            raw_content,
        } => {
            grid.set_cell(position, Cell::new(raw_content));
            FormulaEvaluator::new().evaluate_grid(grid)?;
            Ok(SheetEditOutcome::changed(position, true))
        }
        SheetEdit::SetCellWithFormat {
            position,
            raw_content,
            format,
        } => {
            let mut cell = Cell::new(raw_content);
            cell.format = format;
            grid.set_cell(position, cell);
            FormulaEvaluator::new().evaluate_grid(grid)?;
            Ok(SheetEditOutcome::changed(position, true))
        }
        SheetEdit::ClearCell { position } => {
            grid.remove_cell(&position);
            FormulaEvaluator::new().evaluate_grid(grid)?;
            Ok(SheetEditOutcome::changed(position, true))
        }
        SheetEdit::SetCellFormat { position, format } => {
            if let Some(cell) = grid.get_cell_mut(&position) {
                cell.format = format;
            } else {
                let mut cell = Cell::default();
                cell.format = format;
                grid.set_cell(position, cell);
            }
            Ok(SheetEditOutcome::changed(position, false))
        }
        SheetEdit::RestoreCells { cells } => {
            let changed_cells = cells.iter().map(|entry| entry.position).collect::<Vec<_>>();
            for entry in cells {
                grid.set_cell(entry.position, entry.cell);
            }
            FormulaEvaluator::new().evaluate_grid(grid)?;
            Ok(SheetEditOutcome {
                changed_cells,
                recalculated: true,
            })
        }
        SheetEdit::ApplyStructure { edit } => {
            let changed_cells = apply_sheet_structure_edit(grid, edit)?;
            FormulaEvaluator::new().evaluate_grid(grid)?;
            Ok(SheetEditOutcome {
                changed_cells,
                recalculated: true,
            })
        }
        SheetEdit::Recalculate => {
            FormulaEvaluator::new().evaluate_grid(grid)?;
            Ok(SheetEditOutcome {
                changed_cells: grid.iter().map(|(pos, _)| *pos).collect(),
                recalculated: true,
            })
        }
    }
}

/// Apply a sheet operation envelope by applying its contained edit.
pub fn apply_sheet_operation(
    grid: &mut SheetGrid,
    operation: SheetOperation,
) -> Result<SheetEditOutcome, EvalError> {
    apply_sheet_edit(grid, operation.edit)
}

impl OperationApplier<SheetEdit> for SheetGrid {
    type Outcome = SheetEditOutcome;
    type Error = EvalError;

    fn apply_operation(&mut self, operation: SheetOperation) -> Result<Self::Outcome, Self::Error> {
        apply_sheet_operation(self, operation)
    }
}

impl SheetGrid {
    /// Apply a sheet edit directly to this grid.
    pub fn apply_edit(&mut self, edit: SheetEdit) -> Result<SheetEditOutcome, EvalError> {
        apply_sheet_edit(self, edit)
    }

    /// Apply a sheet operation envelope to this grid.
    pub fn apply_operation(
        &mut self,
        operation: SheetOperation,
    ) -> Result<SheetEditOutcome, EvalError> {
        apply_sheet_operation(self, operation)
    }
}

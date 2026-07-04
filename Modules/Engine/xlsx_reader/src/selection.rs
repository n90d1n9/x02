use crate::CellPosition;
use waraq_core::{GridPosition, GridRange, GridSelection};

pub type SheetCellSelection = GridPosition;
pub type SheetRangeSelection = GridRange;
pub type SheetSelection = GridSelection;

pub fn grid_position(position: CellPosition) -> GridPosition {
    GridPosition::new(position.col, position.row)
}

pub fn cell_position(position: GridPosition) -> CellPosition {
    CellPosition::new(position.col, position.row)
}

impl From<GridPosition> for CellPosition {
    fn from(position: GridPosition) -> Self {
        cell_position(position)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sheet_selection_converts_cell_positions_to_core_grid_positions() {
        let cell = CellPosition::new(2, 3);
        let grid = grid_position(cell);
        let selection = SheetSelection::range(SheetRangeSelection::new(
            grid,
            SheetCellSelection::new(4, 5),
        ));

        assert_eq!(
            CellPosition::from(selection.active),
            CellPosition::new(4, 5)
        );
        assert!(selection.contains(SheetCellSelection::new(3, 4)));
    }
}

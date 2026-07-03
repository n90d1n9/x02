use crate::cell::Cell;
use rustc_hash::FxHashMap;
use serde::{Deserialize, Deserializer, Serialize, Serializer};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CellPosition {
    pub col: u32,
    pub row: u32,
}

impl CellPosition {
    pub fn new(col: u32, row: u32) -> Self {
        Self { col, row }
    }
}

/// A sparse matrix representation of a spreadsheet grid.
/// 
/// Uses a hash map to store only non-empty cells, making it memory-efficient
/// for large spreadsheets with sparse data.
#[derive(Debug, Default)]
pub struct SheetGrid {
    pub name: String,
    cells: FxHashMap<CellPosition, Cell>,
    pub max_col: u32,
    pub max_row: u32,
}

/// Snapshot of a single cell for serialization and state management.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SheetCellSnapshot {
    pub position: CellPosition,
    pub cell: Cell,
}

/// Complete snapshot of a sheet grid for persistence and transfer.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SheetGridSnapshot {
    pub name: String,
    pub max_col: u32,
    pub max_row: u32,
    pub cells: Vec<SheetCellSnapshot>,
}

impl SheetGrid {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            cells: FxHashMap::default(),
            max_col: 0,
            max_row: 0,
        }
    }

    pub fn set_cell(&mut self, pos: CellPosition, cell: Cell) {
        if pos.col > self.max_col {
            self.max_col = pos.col;
        }
        if pos.row > self.max_row {
            self.max_row = pos.row;
        }
        self.cells.insert(pos, cell);
    }

    pub fn remove_cell(&mut self, pos: &CellPosition) -> Option<Cell> {
        let removed = self.cells.remove(pos);
        if removed.is_some() && (pos.col == self.max_col || pos.row == self.max_row) {
            self.recalculate_bounds();
        }
        removed
    }

    pub fn get_cell(&self, pos: &CellPosition) -> Option<&Cell> {
        self.cells.get(pos)
    }

    pub fn get_cell_mut(&mut self, pos: &CellPosition) -> Option<&mut Cell> {
        self.cells.get_mut(pos)
    }

    pub fn iter(&self) -> impl Iterator<Item = (&CellPosition, &Cell)> {
        self.cells.iter()
    }

    pub fn cell_count(&self) -> usize {
        self.cells.len()
    }

    pub fn to_snapshot(&self) -> SheetGridSnapshot {
        let mut cells: Vec<_> = self
            .cells
            .iter()
            .map(|(position, cell)| SheetCellSnapshot {
                position: *position,
                cell: cell.clone(),
            })
            .collect();
        cells.sort_by_key(|entry| (entry.position.row, entry.position.col));

        SheetGridSnapshot {
            name: self.name.clone(),
            max_col: self.max_col,
            max_row: self.max_row,
            cells,
        }
    }

    pub fn from_snapshot(snapshot: SheetGridSnapshot) -> Self {
        let mut grid = SheetGrid::new(snapshot.name);
        for entry in snapshot.cells {
            grid.set_cell(entry.position, entry.cell);
        }
        grid
    }

    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string(self)
    }

    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }

    fn recalculate_bounds(&mut self) {
        self.max_col = self.cells.keys().map(|pos| pos.col).max().unwrap_or(0);
        self.max_row = self.cells.keys().map(|pos| pos.row).max().unwrap_or(0);
    }
}

impl Serialize for SheetGrid {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        self.to_snapshot().serialize(serializer)
    }
}

impl<'de> Deserialize<'de> for SheetGrid {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let snapshot = SheetGridSnapshot::deserialize(deserializer)?;
        Ok(SheetGrid::from_snapshot(snapshot))
    }
}

impl Clone for SheetGrid {
    fn clone(&self) -> Self {
        SheetGrid::from_snapshot(self.to_snapshot())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn remove_cell_recalculates_sparse_bounds() {
        let mut grid = SheetGrid::new("Sheet 1");
        grid.set_cell(CellPosition::new(1, 1), Cell::new("A"));
        grid.set_cell(CellPosition::new(4, 5), Cell::new("B"));

        assert_eq!(grid.max_col, 4);
        assert_eq!(grid.max_row, 5);

        let removed = grid.remove_cell(&CellPosition::new(4, 5));
        assert!(removed.is_some());
        assert_eq!(grid.max_col, 1);
        assert_eq!(grid.max_row, 1);
    }

    #[test]
    fn grid_json_roundtrip_uses_stable_sparse_snapshot() {
        let mut grid = SheetGrid::new("Sheet 1");
        grid.set_cell(CellPosition::new(2, 1), Cell::new("B"));
        grid.set_cell(CellPosition::new(0, 0), Cell::new("A"));

        let json = grid.to_json().unwrap();
        let restored = SheetGrid::from_json(&json).unwrap();

        assert_eq!(restored.name, "Sheet 1");
        assert_eq!(restored.max_col, 2);
        assert_eq!(restored.max_row, 1);
        assert_eq!(restored.cell_count(), 2);
        assert_eq!(
            restored
                .get_cell(&CellPosition::new(0, 0))
                .unwrap()
                .raw_content,
            "A"
        );
    }
}

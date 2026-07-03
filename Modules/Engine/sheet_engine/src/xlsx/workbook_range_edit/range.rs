//! Rectangular sheet range geometry helpers.

use serde::{Deserialize, Serialize};

use crate::CellPosition;

/// Rectangular cell range inside a workbook sheet.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetRange {
    start: CellPosition,
    end: CellPosition,
}

impl XlsxSheetRange {
    /// Create a normalized range from two cell corners.
    pub fn new(start: CellPosition, end: CellPosition) -> Self {
        Self {
            start: CellPosition::new(start.col.min(end.col), start.row.min(end.row)),
            end: CellPosition::new(start.col.max(end.col), start.row.max(end.row)),
        }
    }

    /// Create a single-cell range.
    pub fn single(position: CellPosition) -> Self {
        Self::new(position, position)
    }

    /// Return the normalized top-left cell.
    pub fn start(&self) -> CellPosition {
        self.start
    }

    /// Return the normalized bottom-right cell.
    pub fn end(&self) -> CellPosition {
        self.end
    }

    /// Return the number of columns covered by this range.
    pub fn width(&self) -> usize {
        (self.end.col - self.start.col + 1) as usize
    }

    /// Return the number of rows covered by this range.
    pub fn height(&self) -> usize {
        (self.end.row - self.start.row + 1) as usize
    }

    /// Return the number of cells covered by this range.
    pub fn cell_count(&self) -> usize {
        self.width() * self.height()
    }

    /// Return all positions in row-major order.
    pub fn positions(&self) -> Vec<CellPosition> {
        let mut positions = Vec::with_capacity(self.cell_count());
        for row in self.start.row..=self.end.row {
            for col in self.start.col..=self.end.col {
                positions.push(CellPosition::new(col, row));
            }
        }
        positions
    }
}

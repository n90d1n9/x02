//! Row abstraction.

use crate::cell::{Cell, CellValue};
use std::ops::Index;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

/// A single row of cells from a worksheet.
#[derive(Debug, Clone, Default)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Row {
    /// Zero-based row index.
    pub index: u32,
    /// Cells in this row (may be sparse — gaps are represented as `CellValue::Empty`).
    cells: Vec<Cell>,
}

impl Row {
    /// Construct a new `Row`.
    pub(crate) fn new(index: u32, cells: Vec<Cell>) -> Self {
        Self { index, cells }
    }

    /// Number of cells in this row.
    #[inline]
    pub fn len(&self) -> usize {
        self.cells.len()
    }

    /// Return `true` if every cell is empty.
    pub fn is_empty(&self) -> bool {
        self.cells.iter().all(|c| c.is_empty())
    }

    /// Iterate over the cells.
    #[inline]
    pub fn cells(&self) -> impl Iterator<Item = &Cell> {
        self.cells.iter()
    }

    /// Get a cell by zero-based column index, or `None` if out of range.
    #[inline]
    pub fn get(&self, col: usize) -> Option<&Cell> {
        self.cells.iter().find(|c| c.address.col as usize == col)
    }

    /// Collect cell display values into a `Vec<String>`.
    pub fn values(&self) -> Vec<String> {
        self.cells.iter().map(|c| c.display_value()).collect()
    }

    /// Collect raw `CellValue` references.
    pub fn raw_values(&self) -> Vec<&CellValue> {
        self.cells.iter().map(|c| &c.value).collect()
    }

    /// Return the highest column index present + 1 (i.e. the width of the row).
    pub fn width(&self) -> u16 {
        self.cells
            .iter()
            .map(|c| c.address.col + 1)
            .max()
            .unwrap_or(0)
    }
}

impl Index<usize> for Row {
    type Output = Cell;

    fn index(&self, col: usize) -> &Self::Output {
        self.get(col).expect("column index out of range")
    }
}

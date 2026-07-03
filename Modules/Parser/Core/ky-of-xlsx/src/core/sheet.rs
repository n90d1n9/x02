//! Worksheet types.

use crate::cell::{Cell, CellAddress, CellValue};
use crate::error::{Error, Result};
use crate::row::Row;
use indexmap::IndexMap;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

// ── SheetInfo ─────────────────────────────────────────────────────────────────

/// Lightweight descriptor of a sheet (available before loading its data).
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct SheetInfo {
    /// Sheet index (0-based) within the workbook.
    pub index: usize,
    /// Display name of the sheet tab.
    pub name: String,
    /// Whether the sheet is hidden.
    pub hidden: bool,
    /// Whether the sheet is very-hidden (cannot be unhidden via the UI).
    pub very_hidden: bool,
}

// ── SheetMeta ─────────────────────────────────────────────────────────────────

/// Metadata about a sheet's data extent.
#[derive(Debug, Clone, Default)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct SheetMeta {
    /// Total rows with at least one non-empty cell.
    pub row_count: u32,
    /// Maximum column count across all rows.
    pub col_count: u16,
    /// Number of non-empty cells.
    pub cell_count: usize,
    /// Zero-based index of the first populated row, if any.
    pub first_row: Option<u32>,
    /// Zero-based index of the last populated row, if any.
    pub last_row: Option<u32>,
    /// Zero-based index of the first populated column, if any.
    pub first_col: Option<u16>,
    /// Zero-based index of the last populated column, if any.
    pub last_col: Option<u16>,
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

/// A fully-loaded worksheet.
///
/// Rows are stored as an ordered map keyed by zero-based row index,
/// so sparse sheets remain memory-efficient.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Sheet {
    info: SheetInfo,
    meta: SheetMeta,
    /// Sparse row storage.
    rows: IndexMap<u32, Row>,
}

impl Sheet {
    /// Construct a `Sheet` from already-parsed rows.
    pub(crate) fn from_rows(info: SheetInfo, rows: Vec<Row>) -> Self {
        let mut cell_count = 0usize;
        let mut max_col = 0u16;
        let mut first_row = None;
        let mut last_row = None;
        let mut first_col = None;
        let mut last_col = None;

        let mut row_map: IndexMap<u32, Row> = IndexMap::new();

        for row in rows {
            if !row.is_empty() {
                let ri = row.index;
                first_row = Some(first_row.map_or(ri, |f: u32| f.min(ri)));
                last_row = Some(last_row.map_or(ri, |l: u32| l.max(ri)));

                for cell in row.cells() {
                    if !cell.is_empty() {
                        cell_count += 1;
                        let c = cell.address.col;
                        first_col = Some(first_col.map_or(c, |f: u16| f.min(c)));
                        last_col = Some(last_col.map_or(c, |l: u16| l.max(c)));
                        if c + 1 > max_col {
                            max_col = c + 1;
                        }
                    }
                }
                row_map.insert(ri, row);
            }
        }

        let meta = SheetMeta {
            row_count: row_map.len() as u32,
            col_count: max_col,
            cell_count,
            first_row,
            last_row,
            first_col,
            last_col,
        };

        Self {
            info,
            meta,
            rows: row_map,
        }
    }

    // ── Identity ──────────────────────────────────────────────────────────────

    /// Display name of the sheet tab.
    #[inline]
    pub fn name(&self) -> &str {
        &self.info.name
    }

    /// Zero-based index within the workbook.
    #[inline]
    pub fn index(&self) -> usize {
        self.info.index
    }

    /// Returns `true` if the sheet is hidden.
    #[inline]
    pub fn is_hidden(&self) -> bool {
        self.info.hidden
    }

    /// Returns the sheet's [`SheetInfo`].
    #[inline]
    pub fn info(&self) -> &SheetInfo {
        &self.info
    }

    /// Returns extent metadata.
    #[inline]
    pub fn meta(&self) -> &SheetMeta {
        &self.meta
    }

    // ── Row access ────────────────────────────────────────────────────────────

    /// Iterate over all non-empty rows in index order.
    pub fn rows(&self) -> impl Iterator<Item = &Row> {
        self.rows.values()
    }

    /// Get a row by zero-based index, or `None`.
    pub fn row(&self, index: u32) -> Option<&Row> {
        self.rows.get(&index)
    }

    /// Total number of non-empty rows.
    #[inline]
    pub fn row_count(&self) -> u32 {
        self.meta.row_count
    }

    // ── Cell access ───────────────────────────────────────────────────────────

    /// Get a cell by address, returning `None` for empty/missing cells.
    pub fn cell(&self, addr: CellAddress) -> Option<&Cell> {
        self.rows
            .get(&addr.row)
            .and_then(|r| r.get(addr.col as usize))
            .filter(|c| !c.is_empty())
    }

    /// Get a cell by A1 notation (e.g. `"B3"`).
    ///
    /// # Errors
    /// Returns [`Error::InvalidAddress`] if the address string is malformed.
    pub fn cell_at(&self, a1: &str) -> Result<Option<&Cell>> {
        let addr = CellAddress::from_a1(a1)?;
        Ok(self.cell(addr))
    }

    /// Get the `CellValue` at an A1 address; returns `CellValue::Empty` if absent.
    pub fn value_at(&self, a1: &str) -> Result<CellValue> {
        Ok(self
            .cell_at(a1)?
            .map(|c| c.value.clone())
            .unwrap_or(CellValue::Empty))
    }

    // ── Bulk extraction ───────────────────────────────────────────────────────

    /// Return all rows as a 2-D `Vec<Vec<String>>` (display values).
    ///
    /// Rows are ordered by index; columns are padded to the sheet's max width.
    pub fn to_table(&self) -> Vec<Vec<String>> {
        let width = self.meta.col_count as usize;
        let mut table: Vec<(u32, Vec<String>)> = self
            .rows
            .iter()
            .map(|(&ri, row)| {
                let mut cols = vec![String::new(); width];
                for cell in row.cells() {
                    let c = cell.address.col as usize;
                    if c < width {
                        cols[c] = cell.display_value();
                    }
                }
                (ri, cols)
            })
            .collect();
        table.sort_by_key(|(ri, _)| *ri);
        table.into_iter().map(|(_, row)| row).collect()
    }

    /// Return all non-empty cells as a flat `Vec<(CellAddress, CellValue)>`.
    pub fn cells_flat(&self) -> Vec<(CellAddress, CellValue)> {
        let mut out = Vec::with_capacity(self.meta.cell_count);
        let mut row_keys: Vec<u32> = self.rows.keys().copied().collect();
        row_keys.sort_unstable();
        for ri in row_keys {
            if let Some(row) = self.rows.get(&ri) {
                for cell in row.cells() {
                    if !cell.is_empty() {
                        out.push((cell.address, cell.value.clone()));
                    }
                }
            }
        }
        out
    }

    /// Extract a rectangular range, e.g. `("A1", "D10")`.
    ///
    /// Returns a `Vec<Row>` whose cells are within the bounding box.
    ///
    /// # Errors
    /// Returns [`Error::InvalidAddress`] if either address is malformed.
    pub fn range(&self, top_left: &str, bottom_right: &str) -> Result<Vec<Row>> {
        let tl = CellAddress::from_a1(top_left)?;
        let br = CellAddress::from_a1(bottom_right)?;

        if tl.row > br.row || tl.col > br.col {
            return Err(Error::InvalidAddress(format!(
                "Range {top_left}:{bottom_right} is inverted"
            )));
        }

        let mut result = Vec::new();
        for ri in tl.row..=br.row {
            if let Some(src_row) = self.rows.get(&ri) {
                let cells: Vec<Cell> = src_row
                    .cells()
                    .filter(|c| c.address.col >= tl.col && c.address.col <= br.col)
                    .cloned()
                    .collect();
                if !cells.is_empty() {
                    result.push(Row::new(ri, cells));
                }
            }
        }
        Ok(result)
    }

    // ── Convenience search ────────────────────────────────────────────────────

    /// Find the first cell whose display value matches the given text (exact).
    pub fn find_text(&self, text: &str) -> Option<CellAddress> {
        let mut keys: Vec<u32> = self.rows.keys().copied().collect();
        keys.sort_unstable();
        for ri in keys {
            if let Some(row) = self.rows.get(&ri) {
                for cell in row.cells() {
                    if cell.display_value() == text {
                        return Some(cell.address);
                    }
                }
            }
        }
        None
    }

    /// Find all cells whose display value contains the given substring.
    pub fn search(&self, query: &str) -> Vec<(CellAddress, String)> {
        let mut results = Vec::new();
        let mut keys: Vec<u32> = self.rows.keys().copied().collect();
        keys.sort_unstable();
        for ri in keys {
            if let Some(row) = self.rows.get(&ri) {
                for cell in row.cells() {
                    let v = cell.display_value();
                    if v.contains(query) {
                        results.push((cell.address, v));
                    }
                }
            }
        }
        results
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use crate::cell::CellValue;
    use crate::format::Style;

    fn make_cell(r: u32, c: u16, v: &str) -> Cell {
        Cell::new(
            CellAddress::new(r, c),
            CellValue::Text(v.into()),
            None::<Style>,
        )
    }

    fn make_sheet(name: &str, cells: Vec<Cell>) -> Sheet {
        let info = SheetInfo {
            index: 0,
            name: name.into(),
            hidden: false,
            very_hidden: false,
        };
        // Group into rows
        let mut row_map: std::collections::HashMap<u32, Vec<Cell>> = Default::default();
        for cell in cells {
            row_map.entry(cell.address.row).or_default().push(cell);
        }
        let rows: Vec<Row> = row_map
            .into_iter()
            .map(|(ri, cells)| Row::new(ri, cells))
            .collect();
        Sheet::from_rows(info, rows)
    }

    #[test]
    fn basic_lookup() {
        let sheet = make_sheet(
            "Test",
            vec![make_cell(0, 0, "Hello"), make_cell(1, 2, "World")],
        );
        assert_eq!(sheet.name(), "Test");
        assert_eq!(sheet.row_count(), 2);
        assert_eq!(
            sheet.cell_at("A1").unwrap().unwrap().display_value(),
            "Hello"
        );
        assert_eq!(
            sheet.cell_at("C2").unwrap().unwrap().display_value(),
            "World"
        );
    }

    #[test]
    fn find_and_search() {
        let sheet = make_sheet("S", vec![make_cell(0, 0, "Foo"), make_cell(1, 1, "FooBar")]);
        assert_eq!(sheet.find_text("Foo").unwrap(), CellAddress::new(0, 0));
        let results = sheet.search("Foo");
        assert_eq!(results.len(), 2);
    }
}

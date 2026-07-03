//! Workbook opening and parsing.
//!
//! The primary entry points are [`Workbook::open`] (path) and
//! [`Workbook::from_reader`] (any `Read + Seek` source).

use crate::cell::{Cell, CellAddress, CellValue};
use crate::error::{Error, Result};
use crate::row::Row;
use crate::sheet::{Sheet, SheetInfo};
use calamine::{open_workbook_auto, Reader, Sheets};
use std::collections::HashMap;
use std::io::{Read, Seek};
use std::path::Path;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

// ── WorkbookReader trait ──────────────────────────────────────────────────────

/// Trait implemented by `Workbook` providing the main read API.
pub trait WorkbookReader {
    /// List all sheet names in order.
    fn sheet_names(&self) -> Vec<&str>;

    /// Get a reference to a sheet by name.
    fn sheet_by_name(&self, name: &str) -> Result<&Sheet>;

    /// Get a reference to a sheet by zero-based index.
    fn sheet_by_index(&self, index: usize) -> Result<&Sheet>;

    /// Iterate over all sheets.
    fn sheets(&self) -> impl Iterator<Item = &Sheet>;

    /// Return `true` if a sheet with the given name exists.
    fn has_sheet(&self, name: &str) -> bool;
}

// ── OpenOptions ───────────────────────────────────────────────────────────────

/// Configuration for opening a workbook.
#[derive(Debug, Clone, Default)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct OpenOptions {
    /// Skip sheets whose names match this list.
    pub skip_sheets: Vec<String>,
    /// If non-empty, only load sheets whose names are in this list.
    pub only_sheets: Vec<String>,
    /// Maximum number of rows to load per sheet (0 = unlimited).
    pub max_rows: u32,
    /// Maximum number of columns to load per sheet (0 = unlimited).
    pub max_cols: u16,
    /// Include empty rows when building the row list.
    pub include_empty_rows: bool,
}

impl OpenOptions {
    /// Create a new default `OpenOptions`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Skip sheets with the given names.
    pub fn skip_sheets(mut self, names: impl IntoIterator<Item = impl Into<String>>) -> Self {
        self.skip_sheets = names.into_iter().map(Into::into).collect();
        self
    }

    /// Only load the named sheets.
    pub fn only_sheets(mut self, names: impl IntoIterator<Item = impl Into<String>>) -> Self {
        self.only_sheets = names.into_iter().map(Into::into).collect();
        self
    }

    /// Limit the rows loaded per sheet.
    pub fn max_rows(mut self, n: u32) -> Self {
        self.max_rows = n;
        self
    }

    /// Limit the columns loaded per sheet.
    pub fn max_cols(mut self, n: u16) -> Self {
        self.max_cols = n;
        self
    }

    fn should_load(&self, name: &str) -> bool {
        if !self.only_sheets.is_empty() && !self.only_sheets.iter().any(|n| n == name) {
            return false;
        }
        !self.skip_sheets.iter().any(|n| n == name)
    }
}

// ── Workbook ──────────────────────────────────────────────────────────────────

/// An opened XLS / XLSX / XLSB / ODS workbook.
///
/// All sheet data is loaded eagerly on open; for very large files consider
/// the streaming [`iter`](crate::iter) API instead.
pub struct Workbook {
    sheets: Vec<Sheet>,
    name_index: HashMap<String, usize>,
}

impl Workbook {
    // ── Constructors ──────────────────────────────────────────────────────────

    /// Open a workbook from a file path (auto-detects format from extension).
    ///
    /// # Errors
    /// Forwards I/O and parse errors from `calamine`.
    pub fn open(path: impl AsRef<Path>) -> Result<Self> {
        Self::open_with(path, &OpenOptions::default())
    }

    /// Open a workbook with explicit [`OpenOptions`].
    ///
    /// # Errors
    /// Forwards I/O and parse errors from `calamine`.
    pub fn open_with(path: impl AsRef<Path>, opts: &OpenOptions) -> Result<Self> {
        let path = path.as_ref();
        let mut wb: Sheets<_> = open_workbook_auto(path).map_err(Error::Calamine)?;
        Self::load_from_calamine(&mut wb, opts)
    }

    /// Open a workbook from any `Read + Seek` source.
    ///
    /// The `extension` hint (e.g. `"xlsx"`) is required to pick the right parser.
    ///
    /// # Errors
    /// Forwards parse errors.
    pub fn from_reader<R: Read + Seek + Send + Clone>(
        reader: R,
        extension: &str,
        opts: &OpenOptions,
    ) -> Result<Self> {
        use calamine::{open_workbook_auto_from_rs, Sheets};
        let mut wb: Sheets<R> = open_workbook_auto_from_rs(reader).map_err(Error::Calamine)?;
        let _ = extension; // calamine auto-detects from content
        Self::load_from_calamine(&mut wb, opts)
    }

    /// Open a workbook from raw bytes (e.g. a response body).
    ///
    /// # Errors
    /// Forwards parse errors.
    pub fn from_bytes(bytes: &[u8], extension: &str, opts: &OpenOptions) -> Result<Self> {
        use std::io::Cursor;
        Self::from_reader(Cursor::new(bytes), extension, opts)
    }

    // ── Internal loader ───────────────────────────────────────────────────────

    fn load_from_calamine<R: Read + Seek>(wb: &mut Sheets<R>, opts: &OpenOptions) -> Result<Self> {
        let all_names = wb.sheet_names().to_owned();
        let mut sheets = Vec::new();
        let mut name_index = HashMap::new();

        for (idx, name) in all_names.iter().enumerate() {
            if !opts.should_load(name) {
                continue;
            }

            let info = SheetInfo {
                index: idx,
                name: name.clone(),
                hidden: false, // calamine doesn't expose this yet
                very_hidden: false,
            };

            let range = wb
                .worksheet_range(name)
                .ok_or_else(|| Error::SheetNotFound(name.clone()))??;

            let rows = Self::range_to_rows(&range, opts);
            let sheet = Sheet::from_rows(info, rows);
            name_index.insert(name.clone(), sheets.len());
            sheets.push(sheet);
        }

        Ok(Self { sheets, name_index })
    }

    fn range_to_rows(range: &calamine::Range<calamine::DataType>, opts: &OpenOptions) -> Vec<Row> {
        let mut rows: Vec<Row> = Vec::new();
        let (start_row, start_col) = range.start().unwrap_or((0, 0));

        for (ri, row_iter) in range.rows().enumerate() {
            let abs_row = start_row + ri as u32;
            if opts.max_rows > 0 && ri as u32 >= opts.max_rows {
                break;
            }

            let cells: Vec<Cell> = row_iter
                .iter()
                .enumerate()
                .filter_map(|(ci, dt)| {
                    let abs_col = (start_col + ci as u32) as u16;
                    if opts.max_cols > 0 && abs_col >= opts.max_cols {
                        return None;
                    }
                    let value = CellValue::from(dt);
                    if matches!(value, CellValue::Empty) {
                        return None;
                    }
                    Some(Cell::new(CellAddress::new(abs_row, abs_col), value, None))
                })
                .collect();

            if !cells.is_empty() || opts.include_empty_rows {
                rows.push(Row::new(abs_row, cells));
            }
        }
        rows
    }

    // ── Info helpers ──────────────────────────────────────────────────────────

    /// Return the number of sheets loaded.
    #[inline]
    pub fn sheet_count(&self) -> usize {
        self.sheets.len()
    }
}

// ── WorkbookReader impl ───────────────────────────────────────────────────────

impl WorkbookReader for Workbook {
    fn sheet_names(&self) -> Vec<&str> {
        self.sheets.iter().map(|s| s.name()).collect()
    }

    fn sheet_by_name(&self, name: &str) -> Result<&Sheet> {
        let idx = self
            .name_index
            .get(name)
            .copied()
            .ok_or_else(|| Error::SheetNotFound(name.to_owned()))?;
        Ok(&self.sheets[idx])
    }

    fn sheet_by_index(&self, index: usize) -> Result<&Sheet> {
        self.sheets
            .get(index)
            .ok_or_else(|| Error::SheetNotFound(format!("index {index}")))
    }

    fn sheets(&self) -> impl Iterator<Item = &Sheet> {
        self.sheets.iter()
    }

    fn has_sheet(&self, name: &str) -> bool {
        self.name_index.contains_key(name)
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn open_options_filter() {
        let opts = OpenOptions::new().only_sheets(["Sheet1", "Summary"]);
        assert!(opts.should_load("Sheet1"));
        assert!(!opts.should_load("Sheet2"));

        let opts2 = OpenOptions::new().skip_sheets(["Hidden"]);
        assert!(opts2.should_load("Sheet1"));
        assert!(!opts2.should_load("Hidden"));
    }
}

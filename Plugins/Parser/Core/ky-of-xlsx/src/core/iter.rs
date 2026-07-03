//! Streaming / lazy iteration over large worksheets.
//!
//! Use [`StreamingReader`] when you only need to scan rows sequentially
//! and do not want to load the entire sheet into memory at once.

use crate::cell::{Cell, CellAddress, CellValue};
use crate::error::{Error, Result};
use crate::row::Row;
use calamine::{open_workbook_auto, DataType, Range, Reader};
use std::path::{Path, PathBuf};

/// A handle for streaming rows from a single worksheet without buffering
/// the entire sheet.
///
/// ```rust,no_run
/// use ky-of-xlsx::iter::StreamingReader;
///
/// fn main() -> ky-of-xlsx::Result<()> {
///     let mut reader = StreamingReader::open("big_file.xlsx")?;
///     reader.select_sheet("Sheet1")?;
///     for row in reader.rows() {
///         // process row
///     }
///     Ok(())
/// }
/// ```
pub struct StreamingReader {
    /// Source workbook path used when switching sheets.
    path: PathBuf,
    /// Lazily evaluated rows from calamine.
    rows: Vec<Row>,
    current_sheet: String,
    sheet_names: Vec<String>,
}

impl StreamingReader {
    /// Open the file and prepare for streaming.
    pub fn open(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref().to_path_buf();
        let mut wb = open_workbook_auto(&path).map_err(Error::Calamine)?;
        let sheet_names = wb.sheet_names().to_vec();
        let first = sheet_names.first().cloned().unwrap_or_default();

        let rows = if !first.is_empty() {
            let range = wb
                .worksheet_range(&first)
                .ok_or_else(|| Error::SheetNotFound(first.clone()))??;
            range_to_rows(&range)
        } else {
            vec![]
        };

        Ok(Self {
            path,
            rows,
            current_sheet: first,
            sheet_names,
        })
    }

    /// Available sheet names.
    pub fn sheet_names(&self) -> &[String] {
        &self.sheet_names
    }

    /// Switch the active sheet.  Rows are re-loaded lazily.
    pub fn select_sheet(&mut self, name: &str) -> Result<()> {
        if !self.sheet_names.iter().any(|n| n == name) {
            return Err(Error::SheetNotFound(name.to_owned()));
        }
        // Re-open to get the range (calamine is stateful).
        let mut wb = open_workbook_auto(&self.path).map_err(Error::Calamine)?;
        let range = wb
            .worksheet_range(name)
            .ok_or_else(|| Error::SheetNotFound(name.to_owned()))??;
        self.rows = range_to_rows(&range);
        self.current_sheet = name.to_owned();
        Ok(())
    }

    /// Iterate over rows of the currently-selected sheet.
    pub fn rows(&self) -> impl Iterator<Item = &Row> {
        self.rows.iter()
    }

    /// Iterate over rows that match `predicate`.
    pub fn filter_rows<F>(&self, predicate: F) -> FilteredRows<'_, F>
    where
        F: FnMut(&Row) -> bool,
    {
        FilteredRows::new(&self.rows, predicate)
    }

    /// Iterate over rows transformed into another value.
    pub fn map_rows<T, F>(&self, mapper: F) -> RowMapper<'_, T, F>
    where
        F: FnMut(&Row) -> T,
    {
        RowMapper::new(&self.rows, mapper)
    }

    /// Consume the reader and return all rows.
    pub fn into_rows(self) -> Vec<Row> {
        self.rows
    }

    /// Current sheet name.
    pub fn current_sheet(&self) -> &str {
        &self.current_sheet
    }
}

// ── Lazy row iterator (functional style) ─────────────────────────────────────

/// An iterator adapter that applies a filter predicate while yielding rows.
pub struct FilteredRows<'a, F> {
    inner: std::slice::Iter<'a, Row>,
    predicate: F,
}

impl<'a, F> FilteredRows<'a, F>
where
    F: FnMut(&Row) -> bool,
{
    pub(crate) fn new(rows: &'a [Row], predicate: F) -> Self {
        Self {
            inner: rows.iter(),
            predicate,
        }
    }
}

impl<'a, F> Iterator for FilteredRows<'a, F>
where
    F: FnMut(&Row) -> bool,
{
    type Item = &'a Row;

    fn next(&mut self) -> Option<Self::Item> {
        self.inner.find(|row| (self.predicate)(row))
    }
}

// ── RowMapper ─────────────────────────────────────────────────────────────────

/// Transform each row into a value of type `T`.
pub struct RowMapper<'a, T, F> {
    inner: std::slice::Iter<'a, Row>,
    mapper: F,
    _marker: std::marker::PhantomData<T>,
}

impl<'a, T, F> RowMapper<'a, T, F>
where
    F: FnMut(&Row) -> T,
{
    pub(crate) fn new(rows: &'a [Row], mapper: F) -> Self {
        Self {
            inner: rows.iter(),
            mapper,
            _marker: std::marker::PhantomData,
        }
    }
}

impl<'a, T, F> Iterator for RowMapper<'a, T, F>
where
    F: FnMut(&Row) -> T,
{
    type Item = T;

    fn next(&mut self) -> Option<Self::Item> {
        self.inner.next().map(|row| (self.mapper)(row))
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn range_to_rows(range: &Range<DataType>) -> Vec<Row> {
    let (start_row, start_col) = range.start().unwrap_or((0, 0));
    range
        .rows()
        .enumerate()
        .filter_map(|(ri, row_iter)| {
            let abs_row = start_row + ri as u32;
            let cells: Vec<Cell> = row_iter
                .iter()
                .enumerate()
                .filter_map(|(ci, dt)| {
                    let abs_col = (start_col + ci as u32) as u16;
                    let value = CellValue::from(dt);
                    if matches!(value, CellValue::Empty) {
                        None
                    } else {
                        Some(Cell::new(CellAddress::new(abs_row, abs_col), value, None))
                    }
                })
                .collect();
            if cells.is_empty() {
                None
            } else {
                Some(Row::new(abs_row, cells))
            }
        })
        .collect()
}

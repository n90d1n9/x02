//! XLSX workbook import conversion into sheet-engine sparse grids.

use crate::{CellPosition, SheetGrid, XlsxImportOptions, XlsxWorkbookError};
use ky-of-xlsx::{Workbook, WorkbookReader};

use super::xlsx_cell_to_sheet_cell;

/// Convert loaded XLSX workbook sheets into sheet-engine sparse grids.
pub fn import_grids_from_workbook(workbook: &Workbook) -> Vec<SheetGrid> {
    workbook.sheets().map(sheet_to_grid).collect()
}

/// Load workbook bytes and convert every sheet into a sheet-engine sparse grid.
pub fn import_grids_from_workbook_bytes(
    bytes: &[u8],
    options: XlsxImportOptions,
) -> Result<Vec<SheetGrid>, XlsxWorkbookError> {
    let open_options = options.to_open_options();
    let workbook = Workbook::from_bytes(bytes, &options.extension, &open_options)?;
    Ok(import_grids_from_workbook(&workbook))
}

fn sheet_to_grid(sheet: &ky-of-xlsx::Sheet) -> SheetGrid {
    let mut grid = SheetGrid::new(sheet.name());
    for row in sheet.rows() {
        for cell in row.cells() {
            if cell.is_empty() {
                continue;
            }
            grid.set_cell(
                CellPosition::new(cell.address.col as u32, cell.address.row),
                xlsx_cell_to_sheet_cell(cell),
            );
        }
    }
    grid
}

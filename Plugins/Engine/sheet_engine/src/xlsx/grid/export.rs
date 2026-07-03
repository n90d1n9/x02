//! Sheet-engine sparse grid export conversion into XLSX writer requests.

use std::collections::BTreeMap;

use crate::{new_write_request, CellPosition, SheetGrid, XlsxWorkbookError, XlsxWorkbookRequest};

use super::writer_conversion::sheet_cell_to_writer_value;

/// Build a writer request from named sparse grids.
pub fn grid_to_write_request(
    request: &XlsxWorkbookRequest,
    grids: &[SheetGrid],
) -> Result<ky-of-xlsx::writer::XlsxWriteRequest, XlsxWorkbookError> {
    let mut write_request = new_write_request(request)?;
    let grid_index = index_grids_by_name(grids)?;

    for sheet_name in request.normalized_sheet_names() {
        let grid = grid_index.get(sheet_name.as_str()).ok_or_else(|| {
            XlsxWorkbookError::MissingGridForSheet {
                name: sheet_name.clone(),
            }
        })?;
        append_grid_cells(&mut write_request, &sheet_name, grid)?;
    }

    Ok(write_request)
}

/// Write sparse grids into XLSX workbook bytes.
pub fn write_grids_to_workbook(
    request: &XlsxWorkbookRequest,
    grids: &[SheetGrid],
) -> Result<Vec<u8>, XlsxWorkbookError> {
    let write_request = grid_to_write_request(request, grids)?;
    ky-of-xlsx::writer::write_xlsx(&write_request)
        .map_err(|message| XlsxWorkbookError::WriteFailed(message.to_owned()))
}

fn index_grids_by_name(
    grids: &[SheetGrid],
) -> Result<BTreeMap<&str, &SheetGrid>, XlsxWorkbookError> {
    let mut index = BTreeMap::new();
    for grid in grids {
        let name = grid.name.trim();
        if index.insert(name, grid).is_some() {
            return Err(XlsxWorkbookError::DuplicateGridName {
                name: name.to_owned(),
            });
        }
    }
    Ok(index)
}

fn append_grid_cells(
    request: &mut ky-of-xlsx::writer::XlsxWriteRequest,
    sheet_name: &str,
    grid: &SheetGrid,
) -> Result<(), XlsxWorkbookError> {
    let mut cells: Vec<_> = grid.iter().collect();
    cells.sort_by_key(|(position, _)| (position.row, position.col));

    for (position, cell) in cells {
        let cell_ref = cell_position_to_a1(sheet_name, *position)?;
        if let Some(value) = sheet_cell_to_writer_value(cell) {
            request.add_cell(sheet_name.to_owned(), cell_ref, value);
        }
    }

    Ok(())
}

fn cell_position_to_a1(
    sheet_name: &str,
    position: CellPosition,
) -> Result<String, XlsxWorkbookError> {
    let col = u16::try_from(position.col).map_err(|_| XlsxWorkbookError::ColumnOutOfRange {
        sheet: sheet_name.to_owned(),
        col: position.col,
    })?;
    Ok(ky-of-xlsx::CellAddress::new(position.row, col).to_a1())
}

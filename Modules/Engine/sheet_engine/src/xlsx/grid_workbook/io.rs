//! XLSX byte IO helpers for owned sheet-grid workbooks.

use crate::{
    import_grids_from_workbook_bytes, write_grids_to_workbook, XlsxImportOptions, XlsxWorkbookError,
};

use super::XlsxGridWorkbook;

/// Import workbook bytes into a validated sheet-grid bundle.
pub fn import_grid_workbook_bytes(
    workbook_id: impl Into<String>,
    bytes: &[u8],
    options: XlsxImportOptions,
) -> Result<XlsxGridWorkbook, XlsxWorkbookError> {
    let sheets = import_grids_from_workbook_bytes(bytes, options)?;
    XlsxGridWorkbook::new(workbook_id, sheets)
}

/// Write a sheet-grid workbook bundle into XLSX bytes.
pub fn write_grid_workbook(workbook: &XlsxGridWorkbook) -> Result<Vec<u8>, XlsxWorkbookError> {
    let request = workbook.to_request()?;
    write_grids_to_workbook(&request, workbook.sheets())
}

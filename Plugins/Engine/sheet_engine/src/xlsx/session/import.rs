//! XLSX byte import entry points for editable sheet sessions.

use crate::{import_grid_workbook_bytes, XlsxImportOptions, XlsxWorkbookError};

use super::XlsxSheetSessionBundle;

/// Import workbook bytes into editable core sheet sessions.
pub fn import_sheet_sessions_from_workbook_bytes(
    workbook_id: impl Into<String>,
    bytes: &[u8],
    options: XlsxImportOptions,
) -> Result<XlsxSheetSessionBundle, XlsxWorkbookError> {
    let workbook = import_grid_workbook_bytes(workbook_id, bytes, options)?;
    Ok(XlsxSheetSessionBundle::from_grid_workbook(workbook))
}

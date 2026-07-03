use crate::{XlsxImportOptions, XlsxSheetSummary, XlsxWorkbookError, XlsxWorkbookSummary};
use ky-of-xlsx::{Workbook, WorkbookReader};

/// Summarize workbook bytes without exposing lower-level reader details.
pub fn summarize_workbook_bytes(
    workbook_id: impl Into<String>,
    bytes: &[u8],
    options: XlsxImportOptions,
) -> Result<XlsxWorkbookSummary, XlsxWorkbookError> {
    let workbook_id = workbook_id.into();
    if workbook_id.trim().is_empty() {
        return Err(XlsxWorkbookError::EmptyWorkbookId);
    }

    let open_options = options.to_open_options();
    let workbook = Workbook::from_bytes(bytes, &options.extension, &open_options)?;
    summarize_workbook(workbook_id, &workbook)
}

/// Summarize a loaded workbook into stable sheet metadata.
pub fn summarize_workbook(
    workbook_id: impl Into<String>,
    workbook: &Workbook,
) -> Result<XlsxWorkbookSummary, XlsxWorkbookError> {
    let workbook_id = workbook_id.into();
    if workbook_id.trim().is_empty() {
        return Err(XlsxWorkbookError::EmptyWorkbookId);
    }

    let sheets = workbook
        .sheets()
        .map(|sheet| {
            let meta = sheet.meta();
            XlsxSheetSummary {
                index: sheet.index(),
                name: sheet.name().to_owned(),
                row_count: meta.row_count,
                col_count: meta.col_count,
                cell_count: meta.cell_count,
            }
        })
        .collect();

    Ok(XlsxWorkbookSummary {
        workbook_id: workbook_id.trim().to_owned(),
        sheets,
    })
}

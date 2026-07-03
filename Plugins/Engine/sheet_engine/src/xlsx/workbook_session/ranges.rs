//! Workbook range modules for clipboard operations and multi-cell edits.

use super::XlsxWorkbookSession;
use crate::{XlsxRangeCellUpdate, XlsxSheetRange, XlsxWorkbookError};

mod clipboard;
mod range_edits;

fn inverse_updates_for_range(
    workbook: &XlsxWorkbookSession,
    sheet_name: &str,
    range: XlsxSheetRange,
) -> Result<Vec<XlsxRangeCellUpdate>, XlsxWorkbookError> {
    let session = workbook.sheet_session(sheet_name).ok_or_else(|| {
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: sheet_name.to_owned(),
        }
    })?;

    Ok(range
        .positions()
        .into_iter()
        .map(|position| {
            session
                .state()
                .get_cell(&position)
                .map(|cell| {
                    XlsxRangeCellUpdate::set_with_format(
                        cell.raw_content.clone(),
                        cell.format.clone(),
                    )
                })
                .unwrap_or_else(XlsxRangeCellUpdate::clear)
        })
        .collect())
}

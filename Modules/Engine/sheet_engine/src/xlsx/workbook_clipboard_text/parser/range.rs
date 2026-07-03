//! Range helpers for decoded clipboard text payloads.

use crate::{CellPosition, XlsxSheetRange, XlsxWorkbookError};

pub(in crate::xlsx::workbook_clipboard_text) fn checked_range(
    source_start: CellPosition,
    width: usize,
    height: usize,
) -> Result<XlsxSheetRange, XlsxWorkbookError> {
    let width_offset = u32::try_from(width.saturating_sub(1))
        .map_err(|_| clipboard_range_overflow(source_start, width, height))?;
    let height_offset = u32::try_from(height.saturating_sub(1))
        .map_err(|_| clipboard_range_overflow(source_start, width, height))?;
    let end_col = source_start
        .col
        .checked_add(width_offset)
        .ok_or_else(|| clipboard_range_overflow(source_start, width, height))?;
    let end_row = source_start
        .row
        .checked_add(height_offset)
        .ok_or_else(|| clipboard_range_overflow(source_start, width, height))?;

    Ok(XlsxSheetRange::new(
        source_start,
        CellPosition::new(end_col, end_row),
    ))
}

fn clipboard_range_overflow(
    source_start: CellPosition,
    width: usize,
    height: usize,
) -> XlsxWorkbookError {
    XlsxWorkbookError::ClipboardTextRangeOverflow {
        start_col: source_start.col,
        start_row: source_start.row,
        width,
        height,
    }
}

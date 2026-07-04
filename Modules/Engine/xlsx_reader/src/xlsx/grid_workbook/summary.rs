//! Metadata summary generation for owned sheet-grid workbooks.

use std::collections::BTreeSet;

use crate::{SheetGrid, XlsxSheetSummary, XlsxWorkbookError, XlsxWorkbookSummary};

use super::XlsxGridWorkbook;

impl XlsxGridWorkbook {
    /// Build a stable metadata summary from the owned sheet grids.
    pub fn summary(&self) -> Result<XlsxWorkbookSummary, XlsxWorkbookError> {
        let mut sheets = Vec::with_capacity(self.sheets().len());
        for (index, sheet) in self.sheets().iter().enumerate() {
            let row_count = count_non_empty_rows(sheet);
            let col_count = u16::try_from(sheet.max_col.saturating_add(1)).map_err(|_| {
                XlsxWorkbookError::ColumnOutOfRange {
                    sheet: sheet.name.clone(),
                    col: sheet.max_col,
                }
            })?;

            sheets.push(XlsxSheetSummary {
                index,
                name: sheet.name.clone(),
                row_count,
                col_count: if sheet.cell_count() == 0 {
                    0
                } else {
                    col_count
                },
                cell_count: sheet.cell_count(),
            });
        }

        Ok(XlsxWorkbookSummary {
            workbook_id: self.workbook_id().to_owned(),
            sheets,
        })
    }
}

fn count_non_empty_rows(sheet: &SheetGrid) -> u32 {
    sheet
        .iter()
        .map(|(position, _)| position.row)
        .collect::<BTreeSet<_>>()
        .len() as u32
}

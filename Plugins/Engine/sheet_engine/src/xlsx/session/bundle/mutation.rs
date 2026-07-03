//! Workbook sheet-session ordering mutations.

use crate::XlsxWorkbookError;

use super::{XlsxSheetSessionBundle, XlsxSheetSessionEntry};

impl XlsxSheetSessionBundle {
    pub(crate) fn insert_entry(
        &mut self,
        index: usize,
        entry: XlsxSheetSessionEntry,
    ) -> Result<(), XlsxWorkbookError> {
        if index > self.entries.len() {
            return Err(XlsxWorkbookError::SheetIndexOutOfRange {
                index,
                sheet_count: self.entries.len(),
            });
        }

        self.entries.insert(index, entry);
        self.validate()
    }

    pub(crate) fn remove_entry_at(
        &mut self,
        index: usize,
    ) -> Result<XlsxSheetSessionEntry, XlsxWorkbookError> {
        if index >= self.entries.len() {
            return Err(XlsxWorkbookError::SheetIndexOutOfRange {
                index,
                sheet_count: self.entries.len(),
            });
        }

        Ok(self.entries.remove(index))
    }

    pub(crate) fn move_entry(
        &mut self,
        from_index: usize,
        target_index: usize,
    ) -> Result<(), XlsxWorkbookError> {
        let sheet_count = self.entries.len();
        if from_index >= sheet_count {
            return Err(XlsxWorkbookError::SheetIndexOutOfRange {
                index: from_index,
                sheet_count,
            });
        }
        if target_index >= sheet_count {
            return Err(XlsxWorkbookError::SheetIndexOutOfRange {
                index: target_index,
                sheet_count,
            });
        }
        if from_index == target_index {
            return Ok(());
        }

        let entry = self.entries.remove(from_index);
        self.entries.insert(target_index, entry);
        Ok(())
    }
}

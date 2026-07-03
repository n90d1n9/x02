//! Owned sheet-grid workbook model and validation rules.

use std::collections::BTreeSet;

use crate::{SheetGrid, XlsxWorkbookError, XlsxWorkbookRequest};

/// Workbook bundle that owns sheet-engine grids in XLSX sheet order.
#[derive(Debug, Clone)]
pub struct XlsxGridWorkbook {
    workbook_id: String,
    sheets: Vec<SheetGrid>,
}

impl XlsxGridWorkbook {
    /// Create a validated workbook bundle from sparse sheet grids.
    pub fn new(
        workbook_id: impl Into<String>,
        sheets: impl IntoIterator<Item = SheetGrid>,
    ) -> Result<Self, XlsxWorkbookError> {
        let workbook = Self {
            workbook_id: workbook_id.into().trim().to_owned(),
            sheets: sheets.into_iter().collect(),
        };
        workbook.validate()?;
        Ok(workbook)
    }

    /// Return the stable workbook identity.
    pub fn workbook_id(&self) -> &str {
        &self.workbook_id
    }

    /// Return all sheet grids in workbook order.
    pub fn sheets(&self) -> &[SheetGrid] {
        &self.sheets
    }

    /// Consume the bundle and return its sheet grids.
    pub fn into_sheets(self) -> Vec<SheetGrid> {
        self.sheets
    }

    /// Return the number of sheets in this workbook.
    pub fn sheet_count(&self) -> usize {
        self.sheets.len()
    }

    /// Return the total non-empty cell count across every sheet grid.
    pub fn total_cell_count(&self) -> usize {
        self.sheets.iter().map(SheetGrid::cell_count).sum()
    }

    /// Return sheet names in workbook order.
    pub fn sheet_names(&self) -> Vec<&str> {
        self.sheets
            .iter()
            .map(|sheet| sheet.name.as_str())
            .collect()
    }

    /// Find a sheet grid by trimmed sheet name.
    pub fn sheet_by_name(&self, name: &str) -> Option<&SheetGrid> {
        let requested = name.trim();
        self.sheets
            .iter()
            .find(|sheet| sheet.name.trim() == requested)
    }

    /// Create a validated workbook request for export operations.
    pub fn to_request(&self) -> Result<XlsxWorkbookRequest, XlsxWorkbookError> {
        let request = XlsxWorkbookRequest::new(self.workbook_id.clone(), self.sheet_names());
        request.validate()?;
        Ok(request)
    }

    fn validate(&self) -> Result<(), XlsxWorkbookError> {
        if self.workbook_id.is_empty() {
            return Err(XlsxWorkbookError::EmptyWorkbookId);
        }
        if self.sheets.is_empty() {
            return Err(XlsxWorkbookError::EmptyWorkbook);
        }

        let mut seen = BTreeSet::new();
        for (index, sheet) in self.sheets.iter().enumerate() {
            let name = sheet.name.trim();
            if name.is_empty() {
                return Err(XlsxWorkbookError::EmptySheetName { index });
            }
            if !seen.insert(name.to_owned()) {
                return Err(XlsxWorkbookError::DuplicateGridName {
                    name: name.to_owned(),
                });
            }
        }

        Ok(())
    }
}

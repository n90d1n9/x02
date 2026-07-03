use std::collections::BTreeSet;

use crate::XlsxWorkbookError;

/// Request model for creating or preparing an XLSX workbook.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct XlsxWorkbookRequest {
    /// Stable workbook identity used by higher-level Office sessions.
    pub workbook_id: String,
    /// Ordered worksheet names to create or address.
    pub sheet_names: Vec<String>,
}

impl XlsxWorkbookRequest {
    /// Create a workbook request from a workbook id and ordered sheet names.
    pub fn new(
        workbook_id: impl Into<String>,
        sheet_names: impl IntoIterator<Item = impl Into<String>>,
    ) -> Self {
        Self {
            workbook_id: workbook_id.into(),
            sheet_names: sheet_names.into_iter().map(Into::into).collect(),
        }
    }

    /// Return the number of sheets named by this request.
    pub fn sheet_count(&self) -> usize {
        self.sheet_names.len()
    }

    /// Validate identity and sheet naming before creating workbook bytes.
    pub fn validate(&self) -> Result<(), XlsxWorkbookError> {
        if self.workbook_id.trim().is_empty() {
            return Err(XlsxWorkbookError::EmptyWorkbookId);
        }
        if self.sheet_names.is_empty() {
            return Err(XlsxWorkbookError::EmptyWorkbook);
        }

        let mut seen = BTreeSet::new();
        for (index, sheet_name) in self.sheet_names.iter().enumerate() {
            let normalized = sheet_name.trim();
            if normalized.is_empty() {
                return Err(XlsxWorkbookError::EmptySheetName { index });
            }
            if !seen.insert(normalized.to_owned()) {
                return Err(XlsxWorkbookError::DuplicateSheetName {
                    name: normalized.to_owned(),
                });
            }
        }

        Ok(())
    }

    /// Return sheet names trimmed for lower-level writer APIs.
    pub(crate) fn normalized_sheet_names(&self) -> Vec<String> {
        self.sheet_names
            .iter()
            .map(|sheet_name| sheet_name.trim().to_owned())
            .collect()
    }
}

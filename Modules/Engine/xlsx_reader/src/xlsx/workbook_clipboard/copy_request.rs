//! Copy-range request contract for workbook clipboard commands.

use serde::{Deserialize, Serialize};

use crate::XlsxSheetRange;

/// Request for copying a rectangular cell range from a workbook sheet.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxCopyRangeRequest {
    sheet_name: Option<String>,
    range: XlsxSheetRange,
}

impl XlsxCopyRangeRequest {
    /// Create a copy request targeting the active sheet.
    pub fn new(range: XlsxSheetRange) -> Self {
        Self {
            sheet_name: None,
            range,
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet copy.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the source range to copy.
    pub fn range(&self) -> XlsxSheetRange {
        self.range
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }
}

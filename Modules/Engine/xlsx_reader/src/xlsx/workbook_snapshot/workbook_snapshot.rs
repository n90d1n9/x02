//! Workbook-level snapshot container for XLSX runtime sessions.

use crate::{XlsxWorkbookError, XlsxWorkbookSheetSnapshot};
use serde::{Deserialize, Serialize};
use waraq_core::Validatable;

/// Workbook-level snapshot for restoring an XLSX runtime editing session.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XlsxWorkbookSnapshot {
    workbook_id: String,
    active_sheet_name: String,
    sheets: Vec<XlsxWorkbookSheetSnapshot>,
}

impl XlsxWorkbookSnapshot {
    /// Create a validated workbook snapshot.
    pub fn new(
        workbook_id: impl Into<String>,
        active_sheet_name: impl Into<String>,
        sheets: impl IntoIterator<Item = XlsxWorkbookSheetSnapshot>,
    ) -> Result<Self, XlsxWorkbookError> {
        let snapshot = Self {
            workbook_id: workbook_id.into().trim().to_owned(),
            active_sheet_name: active_sheet_name.into().trim().to_owned(),
            sheets: sheets.into_iter().collect(),
        };
        snapshot.validate()?;
        Ok(snapshot)
    }

    /// Return the stable workbook identity.
    pub fn workbook_id(&self) -> &str {
        &self.workbook_id
    }

    /// Return the active sheet name captured with this snapshot.
    pub fn active_sheet_name(&self) -> &str {
        &self.active_sheet_name
    }

    /// Return sheet snapshots in workbook order.
    pub fn sheets(&self) -> &[XlsxWorkbookSheetSnapshot] {
        &self.sheets
    }

    /// Return the number of sheet snapshots.
    pub fn sheet_count(&self) -> usize {
        self.sheets.len()
    }

    /// Return sheet names in workbook order.
    pub fn sheet_names(&self) -> Vec<&str> {
        self.sheets
            .iter()
            .map(XlsxWorkbookSheetSnapshot::sheet_name)
            .collect()
    }

    /// Find a sheet snapshot by trimmed sheet name.
    pub fn sheet_by_name(&self, sheet_name: &str) -> Option<&XlsxWorkbookSheetSnapshot> {
        let requested = sheet_name.trim();
        self.sheets
            .iter()
            .find(|sheet| sheet.sheet_name() == requested)
    }

    /// Validate this workbook snapshot and return an adapter error on failure.
    pub fn validate(&self) -> Result<(), XlsxWorkbookError> {
        self.validate_report()
            .require_valid()
            .map_err(XlsxWorkbookError::InvalidWorkbookSnapshot)
    }

    /// Serialize this workbook snapshot to JSON.
    pub fn to_json(&self) -> serde_json::Result<String> {
        serde_json::to_string(self)
    }

    /// Deserialize this workbook snapshot from JSON.
    pub fn from_json(json: &str) -> serde_json::Result<Self> {
        serde_json::from_str(json)
    }

    /// Consume the snapshot and return sheet snapshots in workbook order.
    pub fn into_sheets(self) -> Vec<XlsxWorkbookSheetSnapshot> {
        self.sheets
    }
}

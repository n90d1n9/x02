//! Read-only and mutable lookup helpers for sheet-session bundles.

use super::{XlsxSheetSessionBundle, XlsxSheetSessionEntry};

impl XlsxSheetSessionBundle {
    /// Return the stable workbook identity.
    pub fn workbook_id(&self) -> &str {
        &self.workbook_id
    }

    /// Return all sheet session entries in workbook order.
    pub fn entries(&self) -> &[XlsxSheetSessionEntry] {
        &self.entries
    }

    /// Return all mutable sheet session entries in workbook order.
    pub fn entries_mut(&mut self) -> &mut [XlsxSheetSessionEntry] {
        &mut self.entries
    }

    /// Return the number of sheet sessions in this bundle.
    pub fn sheet_count(&self) -> usize {
        self.entries.len()
    }

    /// Return sheet names in workbook order.
    pub fn sheet_names(&self) -> Vec<&str> {
        self.entries
            .iter()
            .map(|entry| entry.sheet_name())
            .collect()
    }

    /// Find a sheet session entry by trimmed sheet name.
    pub fn session_for_sheet(&self, sheet_name: &str) -> Option<&XlsxSheetSessionEntry> {
        let requested = sheet_name.trim();
        self.entries
            .iter()
            .find(|entry| entry.sheet_name() == requested)
    }

    /// Find a mutable sheet session entry by trimmed sheet name.
    pub fn session_for_sheet_mut(
        &mut self,
        sheet_name: &str,
    ) -> Option<&mut XlsxSheetSessionEntry> {
        let requested = sheet_name.trim();
        self.entries
            .iter_mut()
            .find(|entry| entry.sheet_name() == requested)
    }

    pub(crate) fn entry_index(&self, sheet_name: &str) -> Option<usize> {
        let requested = sheet_name.trim();
        self.entries
            .iter()
            .position(|entry| entry.sheet_name() == requested)
    }

    /// Consume the bundle and return sheet session entries in workbook order.
    pub fn into_entries(self) -> Vec<XlsxSheetSessionEntry> {
        self.entries
    }
}

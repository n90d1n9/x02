//! Workbook session persistence, snapshot, and XLSX import/export behavior.

use super::XlsxWorkbookSession;
use crate::{
    import_sheet_sessions_from_workbook_bytes, write_grid_workbook, SheetSession, SheetSnapshot,
    XlsxGridWorkbook, XlsxImportOptions, XlsxSheetSessionBundle, XlsxSheetSessionEntry,
    XlsxWorkbookError, XlsxWorkbookSheetSnapshot, XlsxWorkbookSnapshot,
};
use waraq_core::Validatable;

impl XlsxWorkbookSession {
    /// Convert editable sessions back into an exportable grid workbook.
    pub fn to_grid_workbook(&self) -> Result<XlsxGridWorkbook, XlsxWorkbookError> {
        let sheets = self
            .sheets
            .entries()
            .iter()
            .map(|entry| {
                let mut grid = entry.session().state().clone();
                grid.name = entry.sheet_name().to_owned();
                grid
            })
            .collect::<Vec<_>>();

        XlsxGridWorkbook::new(self.workbook_id(), sheets)
    }

    /// Capture a validated workbook-level runtime snapshot.
    pub fn snapshot(&self, timestamp_ms: u64) -> Result<XlsxWorkbookSnapshot, XlsxWorkbookError> {
        let sheets = self
            .sheets
            .entries()
            .iter()
            .map(|entry| {
                let mut snapshot = entry.session().snapshot(timestamp_ms);
                snapshot.state.name = entry.sheet_name().to_owned();
                XlsxWorkbookSheetSnapshot::new(entry.sheet_name(), snapshot)
            })
            .collect::<Vec<_>>();

        XlsxWorkbookSnapshot::new(self.workbook_id(), self.active_sheet_name(), sheets)
    }

    /// Restore a workbook-level runtime session from a validated snapshot.
    pub fn from_snapshot(snapshot: XlsxWorkbookSnapshot) -> Result<Self, XlsxWorkbookError> {
        snapshot.validate()?;

        let workbook_id = snapshot.workbook_id().to_owned();
        let active_sheet_name = snapshot.active_sheet_name().to_owned();
        let entries = snapshot
            .into_sheets()
            .into_iter()
            .map(sheet_session_entry_from_snapshot)
            .collect::<Result<Vec<_>, XlsxWorkbookError>>()?;
        let sheets = XlsxSheetSessionBundle::from_entries(workbook_id, entries)?;

        Self::from_sheet_sessions_with_active_sheet(sheets, active_sheet_name)
    }
}

/// Import XLSX bytes into a workbook-level editing session.
pub fn import_workbook_session_from_bytes(
    workbook_id: impl Into<String>,
    bytes: &[u8],
    options: XlsxImportOptions,
) -> Result<XlsxWorkbookSession, XlsxWorkbookError> {
    let sheets = import_sheet_sessions_from_workbook_bytes(workbook_id, bytes, options)?;
    Ok(XlsxWorkbookSession::from_sheet_sessions(sheets))
}

/// Write a workbook-level editing session into XLSX bytes.
pub fn write_workbook_session(session: &XlsxWorkbookSession) -> Result<Vec<u8>, XlsxWorkbookError> {
    let workbook = session.to_grid_workbook()?;
    write_grid_workbook(&workbook)
}

fn sheet_session_entry_from_snapshot(
    sheet: XlsxWorkbookSheetSnapshot,
) -> Result<XlsxSheetSessionEntry, XlsxWorkbookError> {
    let sheet_name = sheet.sheet_name().to_owned();
    let mut snapshot: SheetSnapshot = sheet.into_snapshot();
    snapshot.state.name = sheet_name.clone();
    snapshot
        .validate_report()
        .require_valid()
        .map_err(XlsxWorkbookError::InvalidWorkbookSnapshot)?;
    let session = SheetSession::try_from_snapshot(snapshot)
        .map_err(XlsxWorkbookError::InvalidWorkbookSnapshot)?;

    Ok(XlsxSheetSessionEntry::from_session(sheet_name, session))
}

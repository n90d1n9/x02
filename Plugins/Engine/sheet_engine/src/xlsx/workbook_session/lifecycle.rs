use crate::{XlsxSheetSessionBundle, XlsxWorkbookError};

use super::XlsxWorkbookSession;

impl XlsxWorkbookSession {
    /// Create a workbook session and select the first sheet as active.
    pub fn from_sheet_sessions(sheets: XlsxSheetSessionBundle) -> Self {
        let active_sheet_name = sheets
            .sheet_names()
            .into_iter()
            .next()
            .unwrap_or_default()
            .to_owned();

        Self {
            active_sheet_name,
            sheets,
        }
    }

    /// Create a workbook session with a caller-selected active sheet.
    pub fn from_sheet_sessions_with_active_sheet(
        sheets: XlsxSheetSessionBundle,
        active_sheet_name: impl AsRef<str>,
    ) -> Result<Self, XlsxWorkbookError> {
        let mut session = Self::from_sheet_sessions(sheets);
        session.set_active_sheet(active_sheet_name)?;
        Ok(session)
    }

    /// Select a sheet by name for future active-sheet operations.
    pub fn set_active_sheet(
        &mut self,
        active_sheet_name: impl AsRef<str>,
    ) -> Result<(), XlsxWorkbookError> {
        let active_sheet_name = active_sheet_name.as_ref().trim();
        if self.sheets.session_for_sheet(active_sheet_name).is_none() {
            return Err(XlsxWorkbookError::UnknownWorkbookSheet {
                sheet_name: active_sheet_name.to_owned(),
            });
        }

        self.active_sheet_name = active_sheet_name.to_owned();
        Ok(())
    }

    /// Consume the workbook session and return the owned sheet session bundle.
    pub fn into_sheet_sessions(self) -> XlsxSheetSessionBundle {
        self.sheets
    }
}

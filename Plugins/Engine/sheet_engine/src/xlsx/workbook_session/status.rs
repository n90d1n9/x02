use crate::{XlsxWorkbookCommandState, XlsxWorkbookSessionStatus};

use super::XlsxWorkbookSession;

impl XlsxWorkbookSession {
    /// Build a compact status summary for UI, save, and sync surfaces.
    pub fn status(&self) -> XlsxWorkbookSessionStatus {
        XlsxWorkbookSessionStatus::from_session(self)
    }

    /// Build a compact command state for toolbar and sidebar controls.
    pub fn command_state(&self) -> XlsxWorkbookCommandState {
        XlsxWorkbookCommandState::from_status(&self.status())
    }
}

use serde::{Deserialize, Serialize};

use crate::{XlsxWorkbookCommandResult, XlsxWorkbookSessionStatus};

use super::{XlsxWorkbookCommandAvailability, XlsxWorkbookCommandState};

/// Before-and-after summary returned after executing a workbook command.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxWorkbookCommandDelta {
    pub result: XlsxWorkbookCommandResult,
    pub availability_before: XlsxWorkbookCommandAvailability,
    pub state_before: XlsxWorkbookCommandState,
    pub state_after: XlsxWorkbookCommandState,
    pub status_before: XlsxWorkbookSessionStatus,
    pub status_after: XlsxWorkbookSessionStatus,
}

impl XlsxWorkbookCommandDelta {
    /// Build a command delta from the command result and surrounding statuses.
    pub fn new(
        result: XlsxWorkbookCommandResult,
        availability_before: XlsxWorkbookCommandAvailability,
        status_before: XlsxWorkbookSessionStatus,
        status_after: XlsxWorkbookSessionStatus,
    ) -> Self {
        let state_before = XlsxWorkbookCommandState::from_status(&status_before);
        let state_after = XlsxWorkbookCommandState::from_status(&status_after);

        Self {
            result,
            availability_before,
            state_before,
            state_after,
            status_before,
            status_after,
        }
    }

    /// Return true when the active sheet changed during command execution.
    pub fn active_sheet_changed(&self) -> bool {
        self.state_before.active_sheet_name != self.state_after.active_sheet_name
    }

    /// Return true when the workbook sheet count changed during command execution.
    pub fn sheet_count_changed(&self) -> bool {
        self.state_before.sheet_count != self.state_after.sheet_count
    }

    /// Return true when dirty status changed during command execution.
    pub fn dirty_state_changed(&self) -> bool {
        self.state_before.is_dirty != self.state_after.is_dirty
    }

    /// Return true when undo or redo availability changed during command execution.
    pub fn history_state_changed(&self) -> bool {
        self.state_before.can_undo != self.state_after.can_undo
            || self.state_before.can_redo != self.state_after.can_redo
    }
}

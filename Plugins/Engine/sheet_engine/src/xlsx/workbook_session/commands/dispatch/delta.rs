//! Command delta generation for UI and integration surfaces.

use super::super::super::XlsxWorkbookSession;
use crate::{XlsxWorkbookCommand, XlsxWorkbookCommandDelta, XlsxWorkbookError};

impl XlsxWorkbookSession {
    /// Execute a command and return before-and-after state for UI updates.
    pub fn execute_command_with_delta(
        &mut self,
        command: XlsxWorkbookCommand,
    ) -> Result<XlsxWorkbookCommandDelta, XlsxWorkbookError> {
        let status_before = self.status();
        let availability_before = self.command_availability(&command);
        let result = self.execute_command(command)?;
        let status_after = self.status();

        Ok(XlsxWorkbookCommandDelta::new(
            result,
            availability_before,
            status_before,
            status_after,
        ))
    }
}

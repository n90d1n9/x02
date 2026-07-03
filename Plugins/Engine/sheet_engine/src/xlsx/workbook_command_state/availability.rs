use serde::{Deserialize, Serialize};

use super::XlsxWorkbookCommandDisabledReason;

/// Availability decision for a single product-facing workbook command.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxWorkbookCommandAvailability {
    pub enabled: bool,
    pub disabled_reason: Option<XlsxWorkbookCommandDisabledReason>,
}

impl XlsxWorkbookCommandAvailability {
    /// Build an enabled command availability decision.
    pub fn enabled() -> Self {
        Self {
            enabled: true,
            disabled_reason: None,
        }
    }

    /// Build a disabled command availability decision.
    pub fn disabled(reason: XlsxWorkbookCommandDisabledReason) -> Self {
        Self {
            enabled: false,
            disabled_reason: Some(reason),
        }
    }

    /// Return true when this command can be executed by a product surface.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
}

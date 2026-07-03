//! Optional string field patch primitive used by cell format updates.

use serde::{Deserialize, Serialize};

/// Optional string field update used by a cell format patch.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", content = "value", rename_all = "snake_case")]
pub enum XlsxOptionalStringFormatPatch {
    /// Set the format field to a concrete string value.
    Set(String),
    /// Clear the format field back to none.
    Clear,
}

impl XlsxOptionalStringFormatPatch {
    pub(super) fn apply_to(&self, value: &mut Option<String>) {
        match self {
            Self::Set(next) => *value = Some(next.clone()),
            Self::Clear => *value = None,
        }
    }
}

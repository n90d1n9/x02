//! Direct sheet edit result contract.

use serde::{Deserialize, Serialize};
use waraq_core::DocumentId;

use crate::SheetEditOutcome;

/// Result returned after routing a sheet edit through an XLSX workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetEditResult {
    pub sheet_name: String,
    pub document_id: DocumentId,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub outcome: SheetEditOutcome,
}

impl XlsxSheetEditResult {
    /// Create an edit result with the resolved sheet and operation metadata.
    pub fn new(
        sheet_name: impl Into<String>,
        document_id: DocumentId,
        sequence: u64,
        timestamp_ms: u64,
        outcome: SheetEditOutcome,
    ) -> Self {
        Self {
            sheet_name: sheet_name.into(),
            document_id,
            sequence,
            timestamp_ms,
            outcome,
        }
    }
}

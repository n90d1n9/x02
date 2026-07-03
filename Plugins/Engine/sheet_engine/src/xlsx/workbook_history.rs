use crate::SheetEditOutcome;
use serde::{Deserialize, Serialize};
use waraq_core::DocumentId;

/// Workbook-level history action routed to a sheet session.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum XlsxSheetHistoryAction {
    Undo,
    Redo,
}

impl XlsxSheetHistoryAction {
    /// Return a stable action label for logging and diagnostics.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Undo => "undo",
            Self::Redo => "redo",
        }
    }
}

/// Request for applying undo or redo to a sheet in an XLSX workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetHistoryRequest {
    sheet_name: Option<String>,
    timestamp_ms: u64,
}

impl XlsxSheetHistoryRequest {
    /// Create a history request targeting the active sheet.
    pub fn new(timestamp_ms: u64) -> Self {
        Self {
            sheet_name: None,
            timestamp_ms,
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet request.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the history action timestamp.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }
}

/// Result returned after routing undo or redo through an XLSX workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetHistoryResult {
    pub action: XlsxSheetHistoryAction,
    pub sheet_name: String,
    pub document_id: DocumentId,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub outcomes: Vec<SheetEditOutcome>,
}

impl XlsxSheetHistoryResult {
    /// Create a history result with resolved sheet and sequence metadata.
    pub fn new(
        action: XlsxSheetHistoryAction,
        sheet_name: impl Into<String>,
        document_id: DocumentId,
        sequence: u64,
        timestamp_ms: u64,
        outcomes: Vec<SheetEditOutcome>,
    ) -> Self {
        Self {
            action,
            sheet_name: sheet_name.into(),
            document_id,
            sequence,
            timestamp_ms,
            outcomes,
        }
    }

    /// Return the number of operations applied by the history action.
    pub fn outcome_count(&self) -> usize {
        self.outcomes.len()
    }

    /// Return true when the history action had nothing to apply.
    pub fn is_empty(&self) -> bool {
        self.outcomes.is_empty()
    }
}

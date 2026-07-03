//! Result metadata emitted after applying a range edit transaction.

use serde::{Deserialize, Serialize};
use waraq_core::{DocumentId, TransactionId};

use crate::{CellPosition, SheetEditOutcome};

use super::XlsxSheetRange;

/// Result returned after applying a sheet range edit transaction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetRangeEditResult {
    pub transaction_id: TransactionId,
    pub sheet_name: String,
    pub document_id: DocumentId,
    pub start_sequence: u64,
    pub end_sequence: u64,
    pub timestamp_ms: u64,
    pub range: XlsxSheetRange,
    pub outcomes: Vec<SheetEditOutcome>,
}

impl XlsxSheetRangeEditResult {
    /// Create a range edit result with resolved sheet and sequence metadata.
    pub fn new(
        transaction_id: TransactionId,
        sheet_name: impl Into<String>,
        document_id: DocumentId,
        start_sequence: u64,
        end_sequence: u64,
        timestamp_ms: u64,
        range: XlsxSheetRange,
        outcomes: Vec<SheetEditOutcome>,
    ) -> Self {
        Self {
            transaction_id,
            sheet_name: sheet_name.into(),
            document_id,
            start_sequence,
            end_sequence,
            timestamp_ms,
            range,
            outcomes,
        }
    }

    /// Return the number of operations applied by this range edit.
    pub fn operation_count(&self) -> usize {
        self.outcomes.len()
    }

    /// Return all changed cells reported by operation outcomes.
    pub fn changed_cells(&self) -> Vec<CellPosition> {
        self.outcomes
            .iter()
            .flat_map(|outcome| outcome.changed_cells.iter().copied())
            .collect()
    }
}

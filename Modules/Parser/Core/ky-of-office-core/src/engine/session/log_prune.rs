//! Operation-log prune reporting and retained-log floor helpers.

use crate::{DocumentId, OperationLog};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionLogPruneReport {
    pub document_id: DocumentId,
    pub requested_sequence: u64,
    pub pruned_through_sequence: u64,
    pub original_operation_count: usize,
    pub retained_operation_count: usize,
    pub pruned_operation_count: usize,
    pub retained_sequence_range: Option<(u64, u64)>,
}

impl OfficeSessionLogPruneReport {
    pub fn pruned_operations(&self) -> bool {
        self.pruned_operation_count > 0
    }
}

pub(super) fn retained_log_floor_for_snapshot<Edit>(
    snapshot_sequence: u64,
    operation_log: &OperationLog<Edit>,
) -> u64 {
    operation_log
        .operations
        .first()
        .map(|operation| operation.sequence.saturating_sub(1))
        .unwrap_or(snapshot_sequence)
}

pub(super) fn retained_log_floor_for_operation_log<Edit>(
    operation_log: &OperationLog<Edit>,
) -> u64 {
    operation_log
        .operations
        .first()
        .map(|operation| operation.sequence.saturating_sub(1))
        .unwrap_or(0)
}

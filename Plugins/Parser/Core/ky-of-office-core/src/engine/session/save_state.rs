//! Dirty-state tracking, autosave decisions, checkpoints, and saved-log pruning.

use super::super::{
    OfficeAutosaveContext, OfficeAutosaveDecision, OfficeAutosavePolicy, OfficeSessionCheckpoint,
    OfficeSessionEventKind,
};
use super::{OfficeDocumentSession, OfficeSessionLogPruneReport};

impl<State, Edit> OfficeDocumentSession<State, Edit> {
    pub fn sequence(&self) -> u64 {
        self.sequence
    }

    pub fn last_timestamp_ms(&self) -> u64 {
        self.last_timestamp_ms
    }

    pub fn save_checkpoint(&self) -> &OfficeSessionCheckpoint {
        &self.save_checkpoint
    }

    pub fn is_dirty(&self) -> bool {
        self.save_checkpoint.is_dirty(self.sequence)
    }

    pub fn dirty_sequence_range(&self) -> Option<(u64, u64)> {
        if !self.is_dirty() {
            return None;
        }

        Some((self.save_checkpoint.sequence + 1, self.sequence))
    }

    pub fn pending_operation_count(&self) -> usize {
        self.operation_log
            .operations
            .iter()
            .filter(|operation| operation.sequence > self.save_checkpoint.sequence)
            .count()
    }

    pub fn autosave_context(&self, now_timestamp_ms: u64) -> OfficeAutosaveContext {
        OfficeAutosaveContext::new(
            self.save_checkpoint.clone(),
            self.sequence,
            self.pending_operation_count(),
            self.last_timestamp_ms,
            now_timestamp_ms,
        )
    }

    pub fn autosave_decision(
        &self,
        policy: &OfficeAutosavePolicy,
        now_timestamp_ms: u64,
    ) -> OfficeAutosaveDecision {
        policy.evaluate(&self.autosave_context(now_timestamp_ms))
    }

    pub fn should_autosave(&self, policy: &OfficeAutosavePolicy, now_timestamp_ms: u64) -> bool {
        self.autosave_decision(policy, now_timestamp_ms)
            .should_save()
    }

    pub fn mark_saved(&mut self, timestamp_ms: u64) {
        let checkpoint = OfficeSessionCheckpoint::new(self.sequence, timestamp_ms);
        if self.save_checkpoint == checkpoint {
            return;
        }

        self.save_checkpoint = checkpoint;
        self.record_event(
            OfficeSessionEventKind::CheckpointSaved {
                sequence: self.save_checkpoint.sequence,
                timestamp_ms: self.save_checkpoint.timestamp_ms,
            },
            timestamp_ms,
        );
    }

    pub fn prune_saved_operations_to_checkpoint(&mut self) -> OfficeSessionLogPruneReport {
        self.prune_saved_operations_through(self.save_checkpoint.sequence)
    }

    pub fn prune_saved_operations_through(&mut self, sequence: u64) -> OfficeSessionLogPruneReport {
        let original_operation_count = self.operation_log.len();
        let pruned_through_sequence = sequence.min(self.save_checkpoint.sequence);

        self.operation_log
            .operations
            .retain(|operation| operation.sequence > pruned_through_sequence);
        self.operation_log_pruned_through_sequence = self
            .operation_log_pruned_through_sequence
            .max(pruned_through_sequence);

        let retained_operation_count = self.operation_log.len();
        let retained_sequence_range = self
            .operation_log
            .operations
            .first()
            .zip(self.operation_log.operations.last())
            .map(|(first, last)| (first.sequence, last.sequence));

        let report = OfficeSessionLogPruneReport {
            document_id: self.document_id.clone(),
            requested_sequence: sequence,
            pruned_through_sequence,
            original_operation_count,
            retained_operation_count,
            pruned_operation_count: original_operation_count
                .saturating_sub(retained_operation_count),
            retained_sequence_range,
        };

        if report.pruned_operations() {
            self.record_event(
                OfficeSessionEventKind::OperationLogPruned {
                    pruned_through_sequence: report.pruned_through_sequence,
                    pruned_operation_count: report.pruned_operation_count,
                    retained_operation_count: report.retained_operation_count,
                    retained_sequence_range: report.retained_sequence_range,
                },
                self.save_checkpoint.timestamp_ms,
            );
        }

        report
    }
}

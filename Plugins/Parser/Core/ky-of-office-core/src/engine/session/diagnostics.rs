//! Session diagnostics projection for status and command-state surfaces.

use super::super::OfficeSessionDiagnostics;
use super::OfficeDocumentSession;

impl<State, Edit> OfficeDocumentSession<State, Edit> {
    pub fn diagnostics(&self) -> OfficeSessionDiagnostics {
        let operation_log_retained_sequence_range = self
            .operation_log
            .operations
            .first()
            .zip(self.operation_log.operations.last())
            .map(|(first, last)| (first.sequence, last.sequence));
        let event_retained_range = self
            .events
            .first()
            .zip(self.events.last())
            .map(|(first, last)| (first.event_index, last.event_index));

        OfficeSessionDiagnostics {
            engine: self.engine.clone(),
            document_id: self.document_id.clone(),
            sequence: self.sequence,
            last_timestamp_ms: self.last_timestamp_ms,
            save_checkpoint: self.save_checkpoint.clone(),
            is_dirty: self.is_dirty(),
            dirty_sequence_range: self.dirty_sequence_range(),
            pending_operation_count: self.pending_operation_count(),
            operation_log_count: self.operation_log.len(),
            operation_log_pruned_through_sequence: self.operation_log_pruned_through_sequence,
            operation_log_retained_sequence_range,
            event_cursor: self.event_cursor(),
            event_queue_count: self.events.len(),
            event_pruned_through_index: self.event_pruned_through_index,
            event_retained_range,
            selection_kind: (&self.selection).into(),
            selection_is_empty: self.selection.is_empty(),
            can_undo: self.can_undo(),
            can_redo: self.can_redo(),
        }
    }
}

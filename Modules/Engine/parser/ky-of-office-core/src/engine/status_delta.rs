use super::{OfficeSessionCommandDelta, OfficeSessionStatusSnapshot, OfficeSessionStatusUpdate};
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// Identifies a product-facing status area that changed between two snapshots.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeSessionStatusField {
    Sequence,
    LastActivity,
    SaveState,
    PendingOperations,
    OperationLog,
    Events,
    Selection,
    History,
    Signal,
    Commands,
}

/// Describes how a session status snapshot changed since a previous snapshot.
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct OfficeSessionStatusDelta {
    #[serde(default)]
    pub changed: BTreeSet<OfficeSessionStatusField>,
    #[serde(default)]
    pub command_delta: OfficeSessionCommandDelta,
}

impl OfficeSessionStatusDelta {
    /// Compares two status snapshots and groups changes by reusable product-facing areas.
    pub fn between(
        previous: &OfficeSessionStatusSnapshot,
        current: &OfficeSessionStatusSnapshot,
    ) -> Self {
        let mut delta = Self {
            command_delta: current.commands.diff_from(&previous.commands),
            ..Self::default()
        };
        let previous_diagnostics = &previous.diagnostics;
        let current_diagnostics = &current.diagnostics;

        if previous_diagnostics.sequence != current_diagnostics.sequence {
            delta.mark(OfficeSessionStatusField::Sequence);
        }

        if previous_diagnostics.last_timestamp_ms != current_diagnostics.last_timestamp_ms {
            delta.mark(OfficeSessionStatusField::LastActivity);
        }

        if previous_diagnostics.save_checkpoint != current_diagnostics.save_checkpoint
            || previous_diagnostics.is_dirty != current_diagnostics.is_dirty
            || previous_diagnostics.dirty_sequence_range != current_diagnostics.dirty_sequence_range
        {
            delta.mark(OfficeSessionStatusField::SaveState);
        }

        if previous_diagnostics.pending_operation_count
            != current_diagnostics.pending_operation_count
        {
            delta.mark(OfficeSessionStatusField::PendingOperations);
        }

        if previous_diagnostics.operation_log_count != current_diagnostics.operation_log_count
            || previous_diagnostics.operation_log_pruned_through_sequence
                != current_diagnostics.operation_log_pruned_through_sequence
            || previous_diagnostics.operation_log_retained_sequence_range
                != current_diagnostics.operation_log_retained_sequence_range
        {
            delta.mark(OfficeSessionStatusField::OperationLog);
        }

        if previous_diagnostics.event_cursor != current_diagnostics.event_cursor
            || previous_diagnostics.event_queue_count != current_diagnostics.event_queue_count
            || previous_diagnostics.event_pruned_through_index
                != current_diagnostics.event_pruned_through_index
            || previous_diagnostics.event_retained_range != current_diagnostics.event_retained_range
        {
            delta.mark(OfficeSessionStatusField::Events);
        }

        if previous_diagnostics.selection_kind != current_diagnostics.selection_kind
            || previous_diagnostics.selection_is_empty != current_diagnostics.selection_is_empty
        {
            delta.mark(OfficeSessionStatusField::Selection);
        }

        if previous_diagnostics.can_undo != current_diagnostics.can_undo
            || previous_diagnostics.can_redo != current_diagnostics.can_redo
        {
            delta.mark(OfficeSessionStatusField::History);
        }

        if previous.signal != current.signal {
            delta.mark(OfficeSessionStatusField::Signal);
        }

        if !delta.command_delta.is_empty() {
            delta.mark(OfficeSessionStatusField::Commands);
        }

        delta
    }

    /// Returns the changed status fields in stable order.
    pub fn changed_fields(&self) -> &BTreeSet<OfficeSessionStatusField> {
        &self.changed
    }

    /// Returns whether a status field changed.
    pub fn has_changed(&self, field: OfficeSessionStatusField) -> bool {
        self.changed.contains(&field)
    }

    /// Returns whether no status fields or command availability changed.
    pub fn is_empty(&self) -> bool {
        self.changed.is_empty() && self.command_delta.is_empty()
    }

    /// Returns whether command availability changed.
    pub fn command_state_changed(&self) -> bool {
        self.has_changed(OfficeSessionStatusField::Commands)
    }

    /// Returns whether status severity or diagnostic flags changed.
    pub fn status_signal_changed(&self) -> bool {
        self.has_changed(OfficeSessionStatusField::Signal)
    }

    /// Returns whether the active selection family or emptiness changed.
    pub fn selection_changed(&self) -> bool {
        self.has_changed(OfficeSessionStatusField::Selection)
    }

    /// Returns whether retained session events changed.
    pub fn event_queue_changed(&self) -> bool {
        self.has_changed(OfficeSessionStatusField::Events)
    }

    fn mark(&mut self, field: OfficeSessionStatusField) {
        self.changed.insert(field);
    }
}

impl OfficeSessionStatusSnapshot {
    /// Compares this snapshot against an earlier snapshot.
    pub fn diff_from(&self, previous: &Self) -> OfficeSessionStatusDelta {
        OfficeSessionStatusDelta::between(previous, self)
    }
}

impl OfficeSessionStatusUpdate {
    /// Compares this update snapshot against an earlier snapshot.
    pub fn diff_from(&self, previous: &OfficeSessionStatusSnapshot) -> OfficeSessionStatusDelta {
        self.snapshot.diff_from(previous)
    }
}

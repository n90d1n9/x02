use super::{OfficeSessionCheckpoint, OfficeSessionEventCursor};
use crate::{DocumentId, EngineId, OfficeSelection};
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// Identifies the active selection family without exposing product-specific selection details.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeSelectionKind {
    None,
    Text,
    Grid,
    Objects,
    Pages,
}

impl From<&OfficeSelection> for OfficeSelectionKind {
    fn from(selection: &OfficeSelection) -> Self {
        match selection {
            OfficeSelection::None => Self::None,
            OfficeSelection::Text(_) => Self::Text,
            OfficeSelection::Grid(_) => Self::Grid,
            OfficeSelection::Objects(_) => Self::Objects,
            OfficeSelection::Pages(_) => Self::Pages,
        }
    }
}

/// Captures a compact, serializable summary of an Office document session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionDiagnostics {
    pub engine: EngineId,
    pub document_id: DocumentId,
    pub sequence: u64,
    pub last_timestamp_ms: u64,
    pub save_checkpoint: OfficeSessionCheckpoint,
    pub is_dirty: bool,
    pub dirty_sequence_range: Option<(u64, u64)>,
    pub pending_operation_count: usize,
    pub operation_log_count: usize,
    pub operation_log_pruned_through_sequence: u64,
    pub operation_log_retained_sequence_range: Option<(u64, u64)>,
    pub event_cursor: OfficeSessionEventCursor,
    pub event_queue_count: usize,
    pub event_pruned_through_index: u64,
    pub event_retained_range: Option<(u64, u64)>,
    pub selection_kind: OfficeSelectionKind,
    pub selection_is_empty: bool,
    pub can_undo: bool,
    pub can_redo: bool,
}

impl OfficeSessionDiagnostics {
    pub fn operation_log_was_pruned(&self) -> bool {
        self.operation_log_pruned_through_sequence > 0
    }

    pub fn event_queue_was_pruned(&self) -> bool {
        self.event_pruned_through_index > 0
    }

    pub fn evaluate(
        &self,
        policy: &OfficeSessionDiagnosticsPolicy,
    ) -> OfficeSessionDiagnosticsSignal {
        let mut signal = OfficeSessionDiagnosticsSignal::healthy();

        if policy.flag_dirty_sessions && self.is_dirty {
            signal.add_flag(
                OfficeSessionDiagnosticFlag::Dirty,
                OfficeSessionDiagnosticSeverity::Notice,
            );
        }

        if policy
            .pending_operation_warning_threshold
            .is_some_and(|threshold| self.pending_operation_count >= threshold)
        {
            signal.add_flag(
                OfficeSessionDiagnosticFlag::PendingOperationsHigh,
                OfficeSessionDiagnosticSeverity::Warning,
            );
        }

        if policy
            .operation_log_warning_threshold
            .is_some_and(|threshold| self.operation_log_count >= threshold)
        {
            signal.add_flag(
                OfficeSessionDiagnosticFlag::OperationLogHigh,
                OfficeSessionDiagnosticSeverity::Warning,
            );
        }

        if policy
            .event_queue_warning_threshold
            .is_some_and(|threshold| self.event_queue_count >= threshold)
        {
            signal.add_flag(
                OfficeSessionDiagnosticFlag::EventQueueHigh,
                OfficeSessionDiagnosticSeverity::Warning,
            );
        }

        if self.operation_log_was_pruned() {
            signal.add_flag(
                OfficeSessionDiagnosticFlag::OperationLogPruned,
                OfficeSessionDiagnosticSeverity::Notice,
            );
        }

        if self.event_queue_was_pruned() {
            signal.add_flag(
                OfficeSessionDiagnosticFlag::EventQueuePruned,
                OfficeSessionDiagnosticSeverity::Notice,
            );
        }

        signal
    }
}

/// Configures how diagnostics are converted into product-facing status signals.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionDiagnosticsPolicy {
    pub flag_dirty_sessions: bool,
    pub pending_operation_warning_threshold: Option<usize>,
    pub operation_log_warning_threshold: Option<usize>,
    pub event_queue_warning_threshold: Option<usize>,
}

impl Default for OfficeSessionDiagnosticsPolicy {
    fn default() -> Self {
        Self::interactive_editor()
    }
}

impl OfficeSessionDiagnosticsPolicy {
    pub fn interactive_editor() -> Self {
        Self {
            flag_dirty_sessions: true,
            pending_operation_warning_threshold: Some(25),
            operation_log_warning_threshold: Some(1_000),
            event_queue_warning_threshold: Some(500),
        }
    }

    pub fn quiet() -> Self {
        Self {
            flag_dirty_sessions: false,
            pending_operation_warning_threshold: None,
            operation_log_warning_threshold: None,
            event_queue_warning_threshold: None,
        }
    }

    pub fn with_flag_dirty_sessions(mut self, flag_dirty_sessions: bool) -> Self {
        self.flag_dirty_sessions = flag_dirty_sessions;
        self
    }

    pub fn with_pending_operation_warning_threshold(mut self, threshold: Option<usize>) -> Self {
        self.pending_operation_warning_threshold = threshold;
        self
    }

    pub fn with_operation_log_warning_threshold(mut self, threshold: Option<usize>) -> Self {
        self.operation_log_warning_threshold = threshold;
        self
    }

    pub fn with_event_queue_warning_threshold(mut self, threshold: Option<usize>) -> Self {
        self.event_queue_warning_threshold = threshold;
        self
    }
}

/// Describes the highest product-facing severity derived from a diagnostics snapshot.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeSessionDiagnosticSeverity {
    Healthy,
    Notice,
    Warning,
}

/// Identifies a specific condition surfaced by diagnostics evaluation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeSessionDiagnosticFlag {
    Dirty,
    PendingOperationsHigh,
    OperationLogHigh,
    EventQueueHigh,
    OperationLogPruned,
    EventQueuePruned,
}

/// Captures product-facing session health flags derived from diagnostics.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionDiagnosticsSignal {
    pub severity: OfficeSessionDiagnosticSeverity,
    pub flags: BTreeSet<OfficeSessionDiagnosticFlag>,
}

impl OfficeSessionDiagnosticsSignal {
    pub fn healthy() -> Self {
        Self {
            severity: OfficeSessionDiagnosticSeverity::Healthy,
            flags: BTreeSet::new(),
        }
    }

    pub fn is_healthy(&self) -> bool {
        self.severity == OfficeSessionDiagnosticSeverity::Healthy
    }

    pub fn has_flag(&self, flag: OfficeSessionDiagnosticFlag) -> bool {
        self.flags.contains(&flag)
    }

    fn add_flag(
        &mut self,
        flag: OfficeSessionDiagnosticFlag,
        severity: OfficeSessionDiagnosticSeverity,
    ) {
        self.flags.insert(flag);
        self.severity = self.severity.max(severity);
    }
}

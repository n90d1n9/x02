use super::OfficeSessionCheckpoint;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeAutosavePolicy {
    pub enabled: bool,
    pub idle_after_ms: u64,
    pub min_interval_ms: u64,
    pub max_pending_operations: usize,
}

impl Default for OfficeAutosavePolicy {
    fn default() -> Self {
        Self {
            enabled: true,
            idle_after_ms: 2_000,
            min_interval_ms: 15_000,
            max_pending_operations: 25,
        }
    }
}

impl OfficeAutosavePolicy {
    pub fn disabled() -> Self {
        Self {
            enabled: false,
            ..Self::default()
        }
    }

    pub fn immediate() -> Self {
        Self {
            enabled: true,
            idle_after_ms: 0,
            min_interval_ms: 0,
            max_pending_operations: 1,
        }
    }

    pub fn with_enabled(mut self, enabled: bool) -> Self {
        self.enabled = enabled;
        self
    }

    pub fn with_idle_after_ms(mut self, idle_after_ms: u64) -> Self {
        self.idle_after_ms = idle_after_ms;
        self
    }

    pub fn with_min_interval_ms(mut self, min_interval_ms: u64) -> Self {
        self.min_interval_ms = min_interval_ms;
        self
    }

    pub fn with_max_pending_operations(mut self, max_pending_operations: usize) -> Self {
        self.max_pending_operations = max_pending_operations;
        self
    }

    pub fn evaluate(&self, context: &OfficeAutosaveContext) -> OfficeAutosaveDecision {
        if !self.enabled {
            return OfficeAutosaveDecision::Skip(OfficeAutosaveSkipReason::Disabled);
        }

        let Some(dirty_sequence_range) = context.dirty_sequence_range() else {
            return OfficeAutosaveDecision::Skip(OfficeAutosaveSkipReason::Clean);
        };

        let elapsed_since_save_ms = context.elapsed_since_save_ms();
        let elapsed_since_edit_ms = context.elapsed_since_edit_ms();
        let pending_limit_reached = self.max_pending_operations > 0
            && context.pending_operation_count >= self.max_pending_operations;

        if pending_limit_reached {
            return OfficeAutosaveDecision::Save(OfficeAutosaveRequest {
                reason: OfficeAutosaveReason::PendingOperationLimit,
                dirty_sequence_range,
                pending_operation_count: context.pending_operation_count,
                elapsed_since_save_ms,
                elapsed_since_edit_ms,
            });
        }

        if elapsed_since_save_ms < self.min_interval_ms {
            return OfficeAutosaveDecision::Skip(
                OfficeAutosaveSkipReason::WaitingForSaveInterval {
                    elapsed_ms: elapsed_since_save_ms,
                    required_ms: self.min_interval_ms,
                },
            );
        }

        if elapsed_since_edit_ms < self.idle_after_ms {
            return OfficeAutosaveDecision::Skip(OfficeAutosaveSkipReason::WaitingForIdle {
                elapsed_ms: elapsed_since_edit_ms,
                required_ms: self.idle_after_ms,
            });
        }

        OfficeAutosaveDecision::Save(OfficeAutosaveRequest {
            reason: OfficeAutosaveReason::Idle,
            dirty_sequence_range,
            pending_operation_count: context.pending_operation_count,
            elapsed_since_save_ms,
            elapsed_since_edit_ms,
        })
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeAutosaveContext {
    pub checkpoint: OfficeSessionCheckpoint,
    pub current_sequence: u64,
    pub pending_operation_count: usize,
    pub last_edit_timestamp_ms: u64,
    pub now_timestamp_ms: u64,
}

impl OfficeAutosaveContext {
    pub fn new(
        checkpoint: OfficeSessionCheckpoint,
        current_sequence: u64,
        pending_operation_count: usize,
        last_edit_timestamp_ms: u64,
        now_timestamp_ms: u64,
    ) -> Self {
        Self {
            checkpoint,
            current_sequence,
            pending_operation_count,
            last_edit_timestamp_ms,
            now_timestamp_ms,
        }
    }

    pub fn is_dirty(&self) -> bool {
        self.checkpoint.is_dirty(self.current_sequence)
    }

    pub fn dirty_sequence_range(&self) -> Option<(u64, u64)> {
        if !self.is_dirty() {
            return None;
        }

        Some((self.checkpoint.sequence + 1, self.current_sequence))
    }

    pub fn elapsed_since_save_ms(&self) -> u64 {
        self.now_timestamp_ms
            .saturating_sub(self.checkpoint.timestamp_ms)
    }

    pub fn elapsed_since_edit_ms(&self) -> u64 {
        self.now_timestamp_ms
            .saturating_sub(self.last_edit_timestamp_ms)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeAutosaveDecision {
    Save(OfficeAutosaveRequest),
    Skip(OfficeAutosaveSkipReason),
}

impl OfficeAutosaveDecision {
    pub fn should_save(&self) -> bool {
        matches!(self, Self::Save(_))
    }

    pub fn save_request(&self) -> Option<&OfficeAutosaveRequest> {
        match self {
            Self::Save(request) => Some(request),
            Self::Skip(_) => None,
        }
    }

    pub fn skip_reason(&self) -> Option<&OfficeAutosaveSkipReason> {
        match self {
            Self::Save(_) => None,
            Self::Skip(reason) => Some(reason),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeAutosaveRequest {
    pub reason: OfficeAutosaveReason,
    pub dirty_sequence_range: (u64, u64),
    pub pending_operation_count: usize,
    pub elapsed_since_save_ms: u64,
    pub elapsed_since_edit_ms: u64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeAutosaveReason {
    Idle,
    PendingOperationLimit,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeAutosaveSkipReason {
    Disabled,
    Clean,
    WaitingForSaveInterval { elapsed_ms: u64, required_ms: u64 },
    WaitingForIdle { elapsed_ms: u64, required_ms: u64 },
}

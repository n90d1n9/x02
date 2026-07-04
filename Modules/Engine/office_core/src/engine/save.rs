use super::{
    OfficeAutosavePolicy, OfficeAutosaveReason, OfficeAutosaveSkipReason, OfficeDocumentSession,
};
use crate::OfficeDocumentStore;
use serde::{Deserialize, Serialize};

/// Describes the current persistence status of an Office document session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum OfficeSaveState {
    /// Indicates the session has no unsaved local edits.
    Clean { sequence: u64, timestamp_ms: u64 },
    /// Indicates the session has local edits that have not been persisted.
    Dirty {
        sequence: u64,
        pending_operation_count: usize,
    },
    /// Indicates a save operation is currently in progress.
    Saving {
        sequence: u64,
        pending_operation_count: usize,
    },
    /// Indicates the most recent save completed successfully.
    Saved { sequence: u64, timestamp_ms: u64 },
    /// Indicates the most recent save attempt failed while edits remain dirty.
    Failed {
        sequence: u64,
        pending_operation_count: usize,
    },
}

impl OfficeSaveState {
    /// Derives save status from the current session checkpoint and dirty range.
    pub fn from_session<State, Edit>(session: &OfficeDocumentSession<State, Edit>) -> Self {
        if session.is_dirty() {
            Self::Dirty {
                sequence: session.sequence(),
                pending_operation_count: session.pending_operation_count(),
            }
        } else {
            Self::Clean {
                sequence: session.sequence(),
                timestamp_ms: session.save_checkpoint().timestamp_ms,
            }
        }
    }

    /// Returns whether this status represents a persisted document state.
    pub fn is_clean(&self) -> bool {
        matches!(self, Self::Clean { .. } | Self::Saved { .. })
    }

    /// Returns whether this status represents local edits that still need persistence.
    pub fn is_dirty(&self) -> bool {
        matches!(self, Self::Dirty { .. } | Self::Failed { .. })
    }

    /// Returns whether a save operation is currently being attempted.
    pub fn is_saving(&self) -> bool {
        matches!(self, Self::Saving { .. })
    }

    /// Returns whether the most recent save attempt failed.
    pub fn is_failed(&self) -> bool {
        matches!(self, Self::Failed { .. })
    }
}

/// Identifies what initiated a save attempt.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeSaveTrigger {
    Manual,
    Autosave(OfficeAutosaveReason),
}

/// Explains why a save attempt was skipped.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeSaveSkipReason {
    Clean,
    Autosave(OfficeAutosaveSkipReason),
}

/// Reports the persisted range and trigger for a successful save.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSaveReceipt {
    pub trigger: OfficeSaveTrigger,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub dirty_sequence_range: Option<(u64, u64)>,
    pub pending_operation_count: usize,
}

/// Reports the dirty range and store error for a failed save attempt.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(bound(
    serialize = "Error: Serialize",
    deserialize = "Error: Deserialize<'de>"
))]
pub struct OfficeSaveFailure<Error> {
    pub trigger: OfficeSaveTrigger,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub dirty_sequence_range: Option<(u64, u64)>,
    pub pending_operation_count: usize,
    pub error: Error,
}

/// Reports a save attempt that was intentionally skipped.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSaveSkip {
    pub trigger: Option<OfficeSaveTrigger>,
    pub reason: OfficeSaveSkipReason,
    pub sequence: u64,
    pub timestamp_ms: u64,
}

/// Describes the result of a manual save or autosave attempt.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "outcome", content = "details", rename_all = "snake_case")]
#[serde(bound(
    serialize = "Error: Serialize",
    deserialize = "Error: Deserialize<'de>"
))]
pub enum OfficeSaveOutcome<Error> {
    Saved(OfficeSaveReceipt),
    Skipped(OfficeSaveSkip),
    Failed(OfficeSaveFailure<Error>),
}

impl<Error> OfficeSaveOutcome<Error> {
    /// Returns whether the save attempt persisted the document.
    pub fn is_saved(&self) -> bool {
        matches!(self, Self::Saved(_))
    }

    /// Returns whether the save attempt was skipped without persistence.
    pub fn is_skipped(&self) -> bool {
        matches!(self, Self::Skipped(_))
    }

    /// Returns whether the save attempt reached the store and failed.
    pub fn is_failed(&self) -> bool {
        matches!(self, Self::Failed(_))
    }

    /// Returns the successful save receipt when this outcome saved the document.
    pub fn receipt(&self) -> Option<&OfficeSaveReceipt> {
        match self {
            Self::Saved(receipt) => Some(receipt),
            Self::Skipped(_) | Self::Failed(_) => None,
        }
    }

    /// Returns skip details when this outcome skipped persistence.
    pub fn skip(&self) -> Option<&OfficeSaveSkip> {
        match self {
            Self::Skipped(skip) => Some(skip),
            Self::Saved(_) | Self::Failed(_) => None,
        }
    }

    /// Returns failure details when this outcome failed during persistence.
    pub fn failure(&self) -> Option<&OfficeSaveFailure<Error>> {
        match self {
            Self::Failed(failure) => Some(failure),
            Self::Saved(_) | Self::Skipped(_) => None,
        }
    }
}

/// Coordinates save state transitions around a reusable Office document session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSaveCoordinator {
    status: OfficeSaveState,
}

impl Default for OfficeSaveCoordinator {
    fn default() -> Self {
        Self::new()
    }
}

impl OfficeSaveCoordinator {
    /// Builds a save coordinator at the initial clean document state.
    pub fn new() -> Self {
        Self {
            status: OfficeSaveState::Clean {
                sequence: 0,
                timestamp_ms: 0,
            },
        }
    }

    /// Builds a save coordinator using the current status of an existing session.
    pub fn for_session<State, Edit>(session: &OfficeDocumentSession<State, Edit>) -> Self {
        Self {
            status: OfficeSaveState::from_session(session),
        }
    }

    /// Returns the last tracked save status.
    pub fn status(&self) -> &OfficeSaveState {
        &self.status
    }

    /// Refreshes the coordinator status from the current session checkpoint and dirty range.
    pub fn refresh_from_session<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
    ) -> &OfficeSaveState {
        self.status = OfficeSaveState::from_session(session);
        &self.status
    }

    /// Marks the current save attempt as failed while preserving dirty-session context.
    pub fn mark_failed(
        &mut self,
        sequence: u64,
        pending_operation_count: usize,
    ) -> &OfficeSaveState {
        self.status = OfficeSaveState::Failed {
            sequence,
            pending_operation_count,
        };
        &self.status
    }

    /// Attempts an immediate manual save through the provided document store.
    pub fn save_now<State, Edit, Store>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        timestamp_ms: u64,
    ) -> OfficeSaveOutcome<Store::Error>
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        self.save_with_trigger(session, store, timestamp_ms, OfficeSaveTrigger::Manual)
    }

    /// Runs autosave when the policy requests it, otherwise records a skipped save event.
    pub fn autosave_if_needed<State, Edit, Store>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        policy: &OfficeAutosavePolicy,
        timestamp_ms: u64,
    ) -> OfficeSaveOutcome<Store::Error>
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        match session.autosave_decision(policy, timestamp_ms) {
            super::OfficeAutosaveDecision::Save(request) => self.save_with_trigger(
                session,
                store,
                timestamp_ms,
                OfficeSaveTrigger::Autosave(request.reason),
            ),
            super::OfficeAutosaveDecision::Skip(reason) => {
                self.status = OfficeSaveState::from_session(session);
                let skip_reason = OfficeSaveSkipReason::Autosave(reason);
                session.record_save_skipped(None, skip_reason.clone(), timestamp_ms);
                OfficeSaveOutcome::Skipped(OfficeSaveSkip {
                    trigger: None,
                    reason: skip_reason,
                    sequence: session.sequence(),
                    timestamp_ms,
                })
            }
        }
    }

    fn save_with_trigger<State, Edit, Store>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        timestamp_ms: u64,
        trigger: OfficeSaveTrigger,
    ) -> OfficeSaveOutcome<Store::Error>
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        let sequence = session.sequence();
        let dirty_sequence_range = session.dirty_sequence_range();
        let pending_operation_count = session.pending_operation_count();

        if dirty_sequence_range.is_none() {
            self.status = OfficeSaveState::from_session(session);
            session.record_save_skipped(
                Some(trigger.clone()),
                OfficeSaveSkipReason::Clean,
                timestamp_ms,
            );
            return OfficeSaveOutcome::Skipped(OfficeSaveSkip {
                trigger: Some(trigger),
                reason: OfficeSaveSkipReason::Clean,
                sequence,
                timestamp_ms,
            });
        }

        self.status = OfficeSaveState::Saving {
            sequence,
            pending_operation_count,
        };

        match session.persist_and_mark_saved_with_receipt_to(store, timestamp_ms) {
            Ok(_receipt) => {
                self.status = OfficeSaveState::Saved {
                    sequence: session.sequence(),
                    timestamp_ms,
                };
                OfficeSaveOutcome::Saved(OfficeSaveReceipt {
                    trigger,
                    sequence: session.sequence(),
                    timestamp_ms,
                    dirty_sequence_range,
                    pending_operation_count,
                })
            }
            Err(error) => {
                self.mark_failed(sequence, pending_operation_count);
                OfficeSaveOutcome::Failed(OfficeSaveFailure {
                    trigger,
                    sequence,
                    timestamp_ms,
                    dirty_sequence_range,
                    pending_operation_count,
                    error,
                })
            }
        }
    }
}

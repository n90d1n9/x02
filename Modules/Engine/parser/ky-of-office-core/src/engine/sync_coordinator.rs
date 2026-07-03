use super::OfficeDocumentSession;
use crate::{OfficeOperationBatch, OfficeSyncCursor, OfficeSyncError};
use serde::{Deserialize, Serialize};

/// Tracks outgoing operation-batch sync state for one Office document session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSyncCoordinator {
    acknowledged_cursor: OfficeSyncCursor,
    status: OfficeSyncState,
}

impl OfficeSyncCoordinator {
    /// Builds a sync coordinator from the last cursor acknowledged by a product sync service.
    pub fn new(acknowledged_cursor: OfficeSyncCursor) -> Self {
        Self {
            acknowledged_cursor,
            status: OfficeSyncState::Idle,
        }
    }

    /// Builds a sync coordinator at the start of a document operation stream.
    pub fn document_start(
        engine: impl Into<crate::EngineId>,
        document_id: impl Into<crate::DocumentId>,
    ) -> Self {
        Self::new(OfficeSyncCursor::document_start(engine, document_id))
    }

    /// Builds a sync coordinator that treats the current session cursor as acknowledged.
    pub fn for_session<State, Edit>(session: &OfficeDocumentSession<State, Edit>) -> Self {
        Self::new(session.sync_cursor())
    }

    /// Returns the last cursor acknowledged by a product sync service.
    pub fn acknowledged_cursor(&self) -> &OfficeSyncCursor {
        &self.acknowledged_cursor
    }

    /// Returns the last tracked outgoing sync status.
    pub fn status(&self) -> &OfficeSyncState {
        &self.status
    }

    /// Refreshes pending-sync status without returning a full outgoing batch.
    pub fn refresh_from_session<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
        timestamp_ms: u64,
    ) -> &OfficeSyncState
    where
        Edit: Clone,
    {
        let outcome = self.prepare_pending_changes(session, timestamp_ms);

        match outcome {
            OfficeSyncOutcome::Prepared(_) | OfficeSyncOutcome::Skipped(_) => {}
            OfficeSyncOutcome::Failed(_) => {}
        }

        &self.status
    }

    /// Collects operations after the acknowledged cursor for upload by a sync service.
    pub fn prepare_pending_changes<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
        timestamp_ms: u64,
    ) -> OfficeSyncOutcome<Edit>
    where
        Edit: Clone,
    {
        let acknowledged_cursor = self.acknowledged_cursor.clone();

        match session.operations_after(acknowledged_cursor.clone()) {
            Ok(batch) if batch.is_empty() => {
                let skip = OfficeSyncSkip {
                    reason: OfficeSyncSkipReason::UpToDate,
                    cursor: acknowledged_cursor,
                    timestamp_ms,
                };
                self.status = OfficeSyncState::Idle;
                OfficeSyncOutcome::Skipped(skip)
            }
            Ok(batch) => {
                let pending_operation_count = batch.len();
                self.status = OfficeSyncState::Pending {
                    target: batch.target.clone(),
                    pending_operation_count,
                    timestamp_ms,
                };
                OfficeSyncOutcome::Prepared(OfficePendingSyncChanges {
                    timestamp_ms,
                    pending_operation_count,
                    batch,
                })
            }
            Err(error) => {
                let failure = OfficeSyncFailure {
                    cursor: acknowledged_cursor.clone(),
                    timestamp_ms,
                    error,
                };
                self.status = OfficeSyncState::Failed {
                    cursor: acknowledged_cursor,
                    timestamp_ms,
                    error: failure.error.clone(),
                };
                OfficeSyncOutcome::Failed(failure)
            }
        }
    }

    /// Advances the acknowledged cursor after a product sync service confirms upload.
    pub fn mark_synced(
        &mut self,
        target: OfficeSyncCursor,
        timestamp_ms: u64,
    ) -> Result<OfficeSyncReceipt, OfficeSyncError> {
        validate_acknowledgement_target(&self.acknowledged_cursor, &target)?;

        let previous = self.acknowledged_cursor.clone();
        let acknowledged_sequence_count = target.sequence.saturating_sub(previous.sequence);
        self.acknowledged_cursor = target.clone();
        self.status = OfficeSyncState::Synced {
            target: target.clone(),
            acknowledged_sequence_count,
            timestamp_ms,
        };

        Ok(OfficeSyncReceipt {
            previous,
            target,
            acknowledged_sequence_count,
            timestamp_ms,
        })
    }
}

/// Describes outgoing sync readiness for a product sync service.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum OfficeSyncState {
    Idle,
    Pending {
        target: OfficeSyncCursor,
        pending_operation_count: usize,
        timestamp_ms: u64,
    },
    Synced {
        target: OfficeSyncCursor,
        acknowledged_sequence_count: u64,
        timestamp_ms: u64,
    },
    Failed {
        cursor: OfficeSyncCursor,
        timestamp_ms: u64,
        error: OfficeSyncError,
    },
}

impl OfficeSyncState {
    /// Returns whether no outgoing operations are waiting on the sync service.
    pub fn is_idle(&self) -> bool {
        matches!(self, Self::Idle | Self::Synced { .. })
    }

    /// Returns whether an outgoing batch is ready to upload.
    pub fn is_pending(&self) -> bool {
        matches!(self, Self::Pending { .. })
    }

    /// Returns whether pending sync preparation failed.
    pub fn is_failed(&self) -> bool {
        matches!(self, Self::Failed { .. })
    }
}

/// Describes a prepared outgoing operation batch.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(serialize = "Edit: Serialize", deserialize = "Edit: Deserialize<'de>"))]
pub struct OfficePendingSyncChanges<Edit> {
    pub timestamp_ms: u64,
    pub pending_operation_count: usize,
    pub batch: OfficeOperationBatch<Edit>,
}

/// Explains why an outgoing sync preparation did not produce a batch.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeSyncSkipReason {
    UpToDate,
}

/// Reports an outgoing sync preparation that did not need to upload operations.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSyncSkip {
    pub reason: OfficeSyncSkipReason,
    pub cursor: OfficeSyncCursor,
    pub timestamp_ms: u64,
}

/// Reports an outgoing sync preparation failure.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSyncFailure {
    pub cursor: OfficeSyncCursor,
    pub timestamp_ms: u64,
    pub error: OfficeSyncError,
}

/// Reports a cursor acknowledgement from a product sync service.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSyncReceipt {
    pub previous: OfficeSyncCursor,
    pub target: OfficeSyncCursor,
    pub acknowledged_sequence_count: u64,
    pub timestamp_ms: u64,
}

/// Describes the result of preparing outgoing sync changes.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "outcome", content = "details", rename_all = "snake_case")]
#[serde(bound(serialize = "Edit: Serialize", deserialize = "Edit: Deserialize<'de>"))]
pub enum OfficeSyncOutcome<Edit> {
    Prepared(OfficePendingSyncChanges<Edit>),
    Skipped(OfficeSyncSkip),
    Failed(OfficeSyncFailure),
}

impl<Edit> OfficeSyncOutcome<Edit> {
    /// Returns whether this outcome contains a batch ready to upload.
    pub fn is_prepared(&self) -> bool {
        matches!(self, Self::Prepared(_))
    }

    /// Returns whether outgoing sync was skipped.
    pub fn is_skipped(&self) -> bool {
        matches!(self, Self::Skipped(_))
    }

    /// Returns whether outgoing sync preparation failed.
    pub fn is_failed(&self) -> bool {
        matches!(self, Self::Failed(_))
    }

    /// Returns prepared changes when this outcome contains a batch.
    pub fn prepared(&self) -> Option<&OfficePendingSyncChanges<Edit>> {
        match self {
            Self::Prepared(changes) => Some(changes),
            Self::Skipped(_) | Self::Failed(_) => None,
        }
    }

    /// Returns skip details when outgoing sync did not need a batch.
    pub fn skip(&self) -> Option<&OfficeSyncSkip> {
        match self {
            Self::Skipped(skip) => Some(skip),
            Self::Prepared(_) | Self::Failed(_) => None,
        }
    }

    /// Returns failure details when outgoing sync preparation failed.
    pub fn failure(&self) -> Option<&OfficeSyncFailure> {
        match self {
            Self::Failed(failure) => Some(failure),
            Self::Prepared(_) | Self::Skipped(_) => None,
        }
    }
}

fn validate_acknowledgement_target(
    acknowledged: &OfficeSyncCursor,
    target: &OfficeSyncCursor,
) -> Result<(), OfficeSyncError> {
    if target.engine != acknowledged.engine {
        return Err(OfficeSyncError::CursorEngineMismatch {
            expected: acknowledged.engine.clone(),
            actual: target.engine.clone(),
        });
    }

    if target.document_id != acknowledged.document_id {
        return Err(OfficeSyncError::CursorDocumentMismatch {
            expected: acknowledged.document_id.clone(),
            actual: target.document_id.clone(),
        });
    }

    if target.sequence < acknowledged.sequence {
        return Err(OfficeSyncError::TargetSequenceBehindBase {
            base_sequence: acknowledged.sequence,
            target_sequence: target.sequence,
        });
    }

    Ok(())
}

use super::{OfficeDocumentSession, OfficeSessionCheckpoint, OfficeSessionError};
use crate::{
    DocumentId, OfficeDocumentStore, OfficeOperationBatch, OfficeSnapshot, OperationApplier,
    OperationLog,
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeRecoveryPolicy {
    pub mark_replayed_operations_saved: bool,
    pub clear_recovery_events: bool,
}

impl Default for OfficeRecoveryPolicy {
    fn default() -> Self {
        Self {
            mark_replayed_operations_saved: true,
            clear_recovery_events: true,
        }
    }
}

impl OfficeRecoveryPolicy {
    pub fn keep_replayed_operations_dirty() -> Self {
        Self {
            mark_replayed_operations_saved: false,
            ..Self::default()
        }
    }

    pub fn with_mark_replayed_operations_saved(
        mut self,
        mark_replayed_operations_saved: bool,
    ) -> Self {
        self.mark_replayed_operations_saved = mark_replayed_operations_saved;
        self
    }

    pub fn with_clear_recovery_events(mut self, clear_recovery_events: bool) -> Self {
        self.clear_recovery_events = clear_recovery_events;
        self
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeRecoveryReport {
    pub snapshot_sequence: u64,
    pub recovered_sequence: u64,
    pub baseline_operation_count: usize,
    pub replayed_operation_count: usize,
    pub latest_replayed_timestamp_ms: Option<u64>,
    pub save_checkpoint: OfficeSessionCheckpoint,
}

impl OfficeRecoveryReport {
    pub fn replayed_sequence_range(&self) -> Option<(u64, u64)> {
        if self.replayed_operation_count == 0 {
            return None;
        }

        Some((self.snapshot_sequence + 1, self.recovered_sequence))
    }

    pub fn replayed_operations(&self) -> bool {
        self.replayed_operation_count > 0
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct OfficeRecoveredSession<State, Edit> {
    pub session: OfficeDocumentSession<State, Edit>,
    pub report: OfficeRecoveryReport,
}

#[derive(Debug, Clone, PartialEq)]
pub enum OfficeRecoveryStoreError<StoreError, ApplyError> {
    Store(StoreError),
    Recovery(OfficeSessionError<ApplyError>),
}

pub type OfficeRecoveryStoreResult<State, Edit, Store> = Result<
    Option<OfficeRecoveredSession<State, Edit>>,
    OfficeRecoveryStoreError<
        <Store as crate::OfficeStore>::Error,
        <State as OperationApplier<Edit>>::Error,
    >,
>;

impl<StoreError, ApplyError> OfficeRecoveryStoreError<StoreError, ApplyError> {
    pub fn store(error: StoreError) -> Self {
        Self::Store(error)
    }

    pub fn recovery(error: OfficeSessionError<ApplyError>) -> Self {
        Self::Recovery(error)
    }
}

pub fn recover_session_from_snapshot_and_log<State, Edit>(
    snapshot: OfficeSnapshot<State, Edit>,
    operation_log: OperationLog<Edit>,
    policy: OfficeRecoveryPolicy,
) -> Result<OfficeRecoveredSession<State, Edit>, OfficeSessionError<State::Error>>
where
    State: OperationApplier<Edit>,
    Edit: Clone,
{
    let snapshot_sequence = snapshot.sequence;
    let snapshot_timestamp_ms = snapshot.timestamp_ms;
    let baseline_operation_count = operation_log
        .operations
        .iter()
        .filter(|operation| operation.sequence <= snapshot_sequence)
        .count();

    let mut session = OfficeDocumentSession::try_from_snapshot(snapshot)
        .map_err(OfficeSessionError::validation)?;
    let batch = OfficeOperationBatch::from_log_after(session.sync_cursor(), &operation_log)
        .map_err(OfficeSessionError::sync)?;
    let replayed_operation_count = batch.len();
    let latest_replayed_timestamp_ms = batch
        .operations
        .iter()
        .map(|operation| operation.timestamp_ms)
        .max();
    let recovered_timestamp_ms = latest_replayed_timestamp_ms
        .unwrap_or(snapshot_timestamp_ms)
        .max(snapshot_timestamp_ms);

    if replayed_operation_count > 0 {
        session.apply_remote_batch(batch)?;
        if policy.mark_replayed_operations_saved {
            session.mark_saved(recovered_timestamp_ms);
        }
    }

    if policy.clear_recovery_events {
        session.clear_events();
    }

    session.record_recovery_completed(
        snapshot_sequence,
        session.sequence(),
        replayed_operation_count,
        recovered_timestamp_ms,
    );

    let report = OfficeRecoveryReport {
        snapshot_sequence,
        recovered_sequence: session.sequence(),
        baseline_operation_count,
        replayed_operation_count,
        latest_replayed_timestamp_ms,
        save_checkpoint: session.save_checkpoint().clone(),
    };

    Ok(OfficeRecoveredSession { session, report })
}

pub fn recover_session_from_store<State, Edit, Store>(
    store: &Store,
    document_id: &DocumentId,
    policy: OfficeRecoveryPolicy,
) -> OfficeRecoveryStoreResult<State, Edit, Store>
where
    Store: OfficeDocumentStore<State, Edit>,
    State: OperationApplier<Edit>,
    Edit: Clone,
{
    let Some(snapshot) = store
        .load_snapshot(document_id)
        .map_err(OfficeRecoveryStoreError::store)?
    else {
        return Ok(None);
    };

    let operation_log = store
        .load_operation_log(document_id)
        .map_err(OfficeRecoveryStoreError::store)?
        .unwrap_or_else(|| snapshot.operation_log.clone());

    recover_session_from_snapshot_and_log(snapshot, operation_log, policy)
        .map(Some)
        .map_err(OfficeRecoveryStoreError::recovery)
}

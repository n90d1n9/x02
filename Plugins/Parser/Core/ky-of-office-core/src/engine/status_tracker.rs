use super::session::OfficeDocumentSession;
use super::{
    OfficeAutosavePolicy, OfficeSaveCoordinator, OfficeSaveOutcome,
    OfficeSessionCommandExecutionError, OfficeSessionCommandRequest, OfficeSessionCommandResult,
    OfficeSessionDiagnosticsPolicy, OfficeSessionError, OfficeSessionEventCategory,
    OfficeSessionEventCursor, OfficeSessionEventError, OfficeSessionEventFilter,
    OfficeSessionStatusDelta, OfficeSessionStatusObserver, OfficeSessionStatusSnapshot,
    OfficeSessionStatusUpdate, OfficeSyncCoordinator, OfficeSyncOutcome, OfficeSyncReceipt,
};
use crate::{
    OfficeDocumentStore, OfficeOperationBatch, OfficeSyncCursor, OfficeSyncError, OperationApplier,
};
use serde::{Deserialize, Serialize};

/// Stores reusable status polling state together with the last delivered snapshot.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionStatusTracker {
    observer: OfficeSessionStatusObserver,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    last_snapshot: Option<OfficeSessionStatusSnapshot>,
}

impl Default for OfficeSessionStatusTracker {
    fn default() -> Self {
        Self::all_events()
    }
}

impl OfficeSessionStatusTracker {
    /// Builds a status tracker that watches every session event.
    pub fn all_events() -> Self {
        Self::new(OfficeSessionStatusObserver::all_events())
    }

    /// Builds a status tracker scoped to one event category.
    pub fn category(category: OfficeSessionEventCategory) -> Self {
        Self::new(OfficeSessionStatusObserver::category(category))
    }

    /// Builds a status tracker scoped to multiple event categories.
    pub fn categories(categories: impl IntoIterator<Item = OfficeSessionEventCategory>) -> Self {
        Self::new(OfficeSessionStatusObserver::categories(categories))
    }

    /// Builds a status tracker from an explicit diagnostics policy and event filter.
    pub fn with_event_filter(
        diagnostics_policy: OfficeSessionDiagnosticsPolicy,
        event_filter: OfficeSessionEventFilter,
    ) -> Self {
        Self::new(OfficeSessionStatusObserver::with_event_filter(
            diagnostics_policy,
            event_filter,
        ))
    }

    /// Builds a status tracker from an existing status observer.
    pub fn new(observer: OfficeSessionStatusObserver) -> Self {
        Self {
            observer,
            last_snapshot: None,
        }
    }

    /// Replaces the diagnostics policy while preserving tracker and event cursor state.
    pub fn with_diagnostics_policy(
        mut self,
        diagnostics_policy: OfficeSessionDiagnosticsPolicy,
    ) -> Self {
        self.observer = self.observer.with_diagnostics_policy(diagnostics_policy);
        self
    }

    /// Returns the inner status observer.
    pub fn observer(&self) -> &OfficeSessionStatusObserver {
        &self.observer
    }

    /// Returns the mutable inner status observer for advanced product integrations.
    pub fn observer_mut(&mut self) -> &mut OfficeSessionStatusObserver {
        &mut self.observer
    }

    /// Returns the last snapshot delivered by this tracker.
    pub fn last_snapshot(&self) -> Option<&OfficeSessionStatusSnapshot> {
        self.last_snapshot.as_ref()
    }

    /// Seeds the last snapshot used for the next incremental diff.
    pub fn seed_last_snapshot(&mut self, snapshot: OfficeSessionStatusSnapshot) {
        self.last_snapshot = Some(snapshot);
    }

    /// Clears the stored snapshot so the next poll is treated as an initial hydrate.
    pub fn reset_last_snapshot(&mut self) {
        self.last_snapshot = None;
    }

    /// Returns the next event cursor that will be used by this tracker.
    pub fn event_cursor(&self) -> OfficeSessionEventCursor {
        self.observer.event_cursor()
    }

    /// Resets the tracker event cursor for product surfaces that manually resync.
    pub fn reset_event_cursor(&mut self, cursor: OfficeSessionEventCursor) {
        self.observer.reset_event_cursor(cursor);
    }

    /// Executes a core session command and immediately polls tracked status.
    pub fn execute_command<State, Edit>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        request: OfficeSessionCommandRequest,
    ) -> Result<
        OfficeSessionTrackedCommandResult<State::Outcome>,
        OfficeSessionTrackedCommandError<State::Error>,
    >
    where
        State: OperationApplier<Edit>,
        Edit: Clone,
    {
        let command = session
            .execute_command(request)
            .map_err(OfficeSessionTrackedCommandError::command)?;
        let status = self
            .poll(session)
            .map_err(OfficeSessionTrackedCommandError::status)?;

        Ok(OfficeSessionTrackedCommandResult::new(command, status))
    }

    /// Runs a manual save and immediately polls tracked status for product surfaces.
    pub fn save_now<State, Edit, Store>(
        &mut self,
        save_coordinator: &mut OfficeSaveCoordinator,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        timestamp_ms: u64,
    ) -> Result<
        OfficeSessionTrackedSaveResult<Store::Error>,
        OfficeSessionTrackedSaveError<Store::Error>,
    >
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        let save = save_coordinator.save_now(session, store, timestamp_ms);

        self.poll_after_save(session, save)
    }

    /// Runs autosave policy evaluation and immediately polls tracked status.
    pub fn autosave_if_needed<State, Edit, Store>(
        &mut self,
        save_coordinator: &mut OfficeSaveCoordinator,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        policy: &OfficeAutosavePolicy,
        timestamp_ms: u64,
    ) -> Result<
        OfficeSessionTrackedSaveResult<Store::Error>,
        OfficeSessionTrackedSaveError<Store::Error>,
    >
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        let save = save_coordinator.autosave_if_needed(session, store, policy, timestamp_ms);

        self.poll_after_save(session, save)
    }

    /// Prepares outgoing sync changes and immediately polls tracked status.
    pub fn prepare_sync_pending_changes<State, Edit>(
        &mut self,
        sync_coordinator: &mut OfficeSyncCoordinator,
        session: &OfficeDocumentSession<State, Edit>,
        timestamp_ms: u64,
    ) -> Result<OfficeSessionTrackedSyncResult<Edit>, OfficeSessionTrackedSyncError<Edit>>
    where
        Edit: Clone,
    {
        let sync = sync_coordinator.prepare_pending_changes(session, timestamp_ms);

        self.poll_after_sync(session, sync)
    }

    /// Marks an uploaded sync target as acknowledged and immediately polls tracked status.
    pub fn mark_synced<State, Edit>(
        &mut self,
        sync_coordinator: &mut OfficeSyncCoordinator,
        session: &OfficeDocumentSession<State, Edit>,
        target: OfficeSyncCursor,
        timestamp_ms: u64,
    ) -> Result<OfficeSessionTrackedSyncReceipt, OfficeSessionTrackedSyncReceiptError> {
        let receipt = sync_coordinator
            .mark_synced(target, timestamp_ms)
            .map_err(OfficeSessionTrackedSyncReceiptError::sync)?;

        match self.poll(session) {
            Ok(status) => Ok(OfficeSessionTrackedSyncReceipt::new(receipt, status)),
            Err(status_error) => Err(OfficeSessionTrackedSyncReceiptError::status(
                receipt,
                status_error,
            )),
        }
    }

    /// Applies an incoming remote operation batch and immediately polls tracked status.
    pub fn apply_remote_batch<State, Edit>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        batch: OfficeOperationBatch<Edit>,
    ) -> Result<
        OfficeSessionTrackedRemoteBatchResult<State::Outcome>,
        OfficeSessionTrackedRemoteBatchError<State::Error, State::Outcome>,
    >
    where
        State: OperationApplier<Edit>,
        Edit: Clone,
    {
        let mut remote_batch = OfficeSessionRemoteBatchResult::from_batch(&batch);
        let operation_outcomes = session
            .apply_remote_batch(batch)
            .map_err(OfficeSessionTrackedRemoteBatchError::remote_batch)?;

        remote_batch.operation_outcomes = operation_outcomes;

        match self.poll(session) {
            Ok(status) => Ok(OfficeSessionTrackedRemoteBatchResult::new(
                remote_batch,
                status,
            )),
            Err(status_error) => Err(OfficeSessionTrackedRemoteBatchError::status(
                remote_batch,
                status_error,
            )),
        }
    }

    /// Polls status and returns an incremental delta when a previous snapshot exists.
    pub fn poll<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
    ) -> Result<OfficeSessionStatusTrackerUpdate, OfficeSessionEventError> {
        let update = self.observer.poll(session)?;
        let delta = self
            .last_snapshot
            .as_ref()
            .map(|previous| update.diff_from(previous));

        self.last_snapshot = Some(update.snapshot.clone());

        Ok(OfficeSessionStatusTrackerUpdate::new(update, delta))
    }

    fn poll_after_save<State, Edit, StoreError>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
        save: OfficeSaveOutcome<StoreError>,
    ) -> Result<OfficeSessionTrackedSaveResult<StoreError>, OfficeSessionTrackedSaveError<StoreError>>
    {
        match self.poll(session) {
            Ok(status) => Ok(OfficeSessionTrackedSaveResult::new(save, status)),
            Err(status_error) => Err(OfficeSessionTrackedSaveError::new(save, status_error)),
        }
    }

    fn poll_after_sync<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
        sync: OfficeSyncOutcome<Edit>,
    ) -> Result<OfficeSessionTrackedSyncResult<Edit>, OfficeSessionTrackedSyncError<Edit>> {
        match self.poll(session) {
            Ok(status) => Ok(OfficeSessionTrackedSyncResult::new(sync, status)),
            Err(status_error) => Err(OfficeSessionTrackedSyncError::new(sync, status_error)),
        }
    }
}

/// Describes an incoming remote batch that was applied to a session.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(
    serialize = "Outcome: Serialize",
    deserialize = "Outcome: Deserialize<'de>"
))]
pub struct OfficeSessionRemoteBatchResult<Outcome> {
    pub base: OfficeSyncCursor,
    pub target: OfficeSyncCursor,
    pub operation_count: usize,
    #[serde(default)]
    pub operation_outcomes: Vec<Outcome>,
}

impl<Outcome> OfficeSessionRemoteBatchResult<Outcome> {
    /// Builds a remote batch result from cursor metadata and applied operation outcomes.
    pub fn new(
        base: OfficeSyncCursor,
        target: OfficeSyncCursor,
        operation_count: usize,
        operation_outcomes: Vec<Outcome>,
    ) -> Self {
        Self {
            base,
            target,
            operation_count,
            operation_outcomes,
        }
    }

    /// Builds remote batch metadata before the batch is consumed by session application.
    pub fn from_batch<Edit>(batch: &OfficeOperationBatch<Edit>) -> Self {
        Self::new(
            batch.base.clone(),
            batch.target.clone(),
            batch.len(),
            Vec::new(),
        )
    }

    /// Returns whether applying the remote batch advanced the session sequence.
    pub fn sequence_changed(&self) -> bool {
        self.base.sequence != self.target.sequence
    }

    /// Returns whether the incoming remote batch contained operations.
    pub fn applied_operations(&self) -> bool {
        self.operation_count > 0
    }
}

/// Describes an applied remote batch together with the resulting tracked status update.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(
    serialize = "Outcome: Serialize",
    deserialize = "Outcome: Deserialize<'de>"
))]
pub struct OfficeSessionTrackedRemoteBatchResult<Outcome> {
    pub remote_batch: OfficeSessionRemoteBatchResult<Outcome>,
    pub status: OfficeSessionStatusTrackerUpdate,
}

impl<Outcome> OfficeSessionTrackedRemoteBatchResult<Outcome> {
    /// Builds a tracked remote batch result from the batch receipt and status update.
    pub fn new(
        remote_batch: OfficeSessionRemoteBatchResult<Outcome>,
        status: OfficeSessionStatusTrackerUpdate,
    ) -> Self {
        Self {
            remote_batch,
            status,
        }
    }

    /// Returns whether the remote batch changed the session sequence.
    pub fn sequence_changed(&self) -> bool {
        self.remote_batch.sequence_changed()
    }

    /// Returns whether the post-remote status update contains incremental changes.
    pub fn has_incremental_changes(&self) -> bool {
        self.status.has_incremental_changes()
    }

    /// Returns whether status polling recovered from a compacted event cursor.
    pub fn event_cursor_was_reset(&self) -> bool {
        self.status.event_cursor_was_reset()
    }
}

/// Describes a failure while applying an incoming remote batch and polling tracked status.
#[derive(Debug, Clone, PartialEq)]
pub enum OfficeSessionTrackedRemoteBatchError<Error, Outcome = ()> {
    RemoteBatch(OfficeSessionError<Error>),
    Status {
        remote_batch: OfficeSessionRemoteBatchResult<Outcome>,
        status_error: OfficeSessionEventError,
    },
}

impl<Error, Outcome> OfficeSessionTrackedRemoteBatchError<Error, Outcome> {
    /// Builds a tracked remote-batch error from a rejected incoming batch.
    pub fn remote_batch(error: OfficeSessionError<Error>) -> Self {
        Self::RemoteBatch(error)
    }

    /// Builds a tracked remote-batch error after applying the batch but failing to poll status.
    pub fn status(
        remote_batch: OfficeSessionRemoteBatchResult<Outcome>,
        status_error: OfficeSessionEventError,
    ) -> Self {
        Self::Status {
            remote_batch,
            status_error,
        }
    }
}

/// Describes a command execution together with the resulting tracked status update.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSessionTrackedCommandResult<Outcome> {
    pub command: OfficeSessionCommandResult<Outcome>,
    pub status: OfficeSessionStatusTrackerUpdate,
}

impl<Outcome> OfficeSessionTrackedCommandResult<Outcome> {
    /// Builds a tracked command result from the command receipt and status update.
    pub fn new(
        command: OfficeSessionCommandResult<Outcome>,
        status: OfficeSessionStatusTrackerUpdate,
    ) -> Self {
        Self { command, status }
    }

    /// Returns whether the post-command status update contains incremental changes.
    pub fn has_incremental_changes(&self) -> bool {
        self.status.has_incremental_changes()
    }

    /// Returns whether status polling recovered from a compacted event cursor.
    pub fn event_cursor_was_reset(&self) -> bool {
        self.status.event_cursor_was_reset()
    }
}

/// Describes a failure while executing a command and polling tracked status.
#[derive(Debug, Clone, PartialEq)]
pub enum OfficeSessionTrackedCommandError<Error> {
    Command(OfficeSessionCommandExecutionError<Error>),
    Status(OfficeSessionEventError),
}

impl<Error> OfficeSessionTrackedCommandError<Error> {
    /// Builds a tracked-command error from a rejected or failed command.
    pub fn command(error: OfficeSessionCommandExecutionError<Error>) -> Self {
        Self::Command(error)
    }

    /// Builds a tracked-command error from a failed status poll.
    pub fn status(error: OfficeSessionEventError) -> Self {
        Self::Status(error)
    }
}

/// Describes a save attempt together with the resulting tracked status update.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(
    serialize = "StoreError: Serialize",
    deserialize = "StoreError: Deserialize<'de>"
))]
pub struct OfficeSessionTrackedSaveResult<StoreError> {
    pub save: OfficeSaveOutcome<StoreError>,
    pub status: OfficeSessionStatusTrackerUpdate,
}

impl<StoreError> OfficeSessionTrackedSaveResult<StoreError> {
    /// Builds a tracked save result from the save outcome and status update.
    pub fn new(
        save: OfficeSaveOutcome<StoreError>,
        status: OfficeSessionStatusTrackerUpdate,
    ) -> Self {
        Self { save, status }
    }

    /// Returns whether the save attempt persisted the document.
    pub fn is_saved(&self) -> bool {
        self.save.is_saved()
    }

    /// Returns whether the save attempt was skipped.
    pub fn is_skipped(&self) -> bool {
        self.save.is_skipped()
    }

    /// Returns whether the save attempt failed during persistence.
    pub fn is_failed(&self) -> bool {
        self.save.is_failed()
    }

    /// Returns whether the post-save status update contains incremental changes.
    pub fn has_incremental_changes(&self) -> bool {
        self.status.has_incremental_changes()
    }

    /// Returns whether status polling recovered from a compacted event cursor.
    pub fn event_cursor_was_reset(&self) -> bool {
        self.status.event_cursor_was_reset()
    }
}

/// Preserves a save outcome when the follow-up status poll fails.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(
    serialize = "StoreError: Serialize",
    deserialize = "StoreError: Deserialize<'de>"
))]
pub struct OfficeSessionTrackedSaveError<StoreError> {
    pub save: OfficeSaveOutcome<StoreError>,
    pub status_error: OfficeSessionEventError,
}

impl<StoreError> OfficeSessionTrackedSaveError<StoreError> {
    /// Builds a tracked save error from the save outcome and status polling failure.
    pub fn new(save: OfficeSaveOutcome<StoreError>, status_error: OfficeSessionEventError) -> Self {
        Self { save, status_error }
    }
}

/// Describes outgoing sync preparation together with the resulting tracked status update.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(serialize = "Edit: Serialize", deserialize = "Edit: Deserialize<'de>"))]
pub struct OfficeSessionTrackedSyncResult<Edit> {
    pub sync: OfficeSyncOutcome<Edit>,
    pub status: OfficeSessionStatusTrackerUpdate,
}

impl<Edit> OfficeSessionTrackedSyncResult<Edit> {
    /// Builds a tracked sync result from the sync outcome and status update.
    pub fn new(sync: OfficeSyncOutcome<Edit>, status: OfficeSessionStatusTrackerUpdate) -> Self {
        Self { sync, status }
    }

    /// Returns whether outgoing sync preparation produced a batch.
    pub fn is_prepared(&self) -> bool {
        self.sync.is_prepared()
    }

    /// Returns whether outgoing sync preparation was skipped.
    pub fn is_skipped(&self) -> bool {
        self.sync.is_skipped()
    }

    /// Returns whether outgoing sync preparation failed.
    pub fn is_failed(&self) -> bool {
        self.sync.is_failed()
    }

    /// Returns whether the post-sync status update contains incremental changes.
    pub fn has_incremental_changes(&self) -> bool {
        self.status.has_incremental_changes()
    }

    /// Returns whether status polling recovered from a compacted event cursor.
    pub fn event_cursor_was_reset(&self) -> bool {
        self.status.event_cursor_was_reset()
    }
}

/// Preserves an outgoing sync outcome when the follow-up status poll fails.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(serialize = "Edit: Serialize", deserialize = "Edit: Deserialize<'de>"))]
pub struct OfficeSessionTrackedSyncError<Edit> {
    pub sync: OfficeSyncOutcome<Edit>,
    pub status_error: OfficeSessionEventError,
}

impl<Edit> OfficeSessionTrackedSyncError<Edit> {
    /// Builds a tracked sync error from the sync outcome and status polling failure.
    pub fn new(sync: OfficeSyncOutcome<Edit>, status_error: OfficeSessionEventError) -> Self {
        Self { sync, status_error }
    }
}

/// Describes a sync acknowledgement together with the resulting tracked status update.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSessionTrackedSyncReceipt {
    pub receipt: OfficeSyncReceipt,
    pub status: OfficeSessionStatusTrackerUpdate,
}

impl OfficeSessionTrackedSyncReceipt {
    /// Builds a tracked sync receipt from the acknowledgement receipt and status update.
    pub fn new(receipt: OfficeSyncReceipt, status: OfficeSessionStatusTrackerUpdate) -> Self {
        Self { receipt, status }
    }

    /// Returns whether the acknowledged cursor advanced.
    pub fn acknowledged_sequences(&self) -> bool {
        self.receipt.acknowledged_sequence_count > 0
    }

    /// Returns whether the post-acknowledgement status update contains incremental changes.
    pub fn has_incremental_changes(&self) -> bool {
        self.status.has_incremental_changes()
    }

    /// Returns whether status polling recovered from a compacted event cursor.
    pub fn event_cursor_was_reset(&self) -> bool {
        self.status.event_cursor_was_reset()
    }
}

/// Describes a failure while acknowledging sync completion and polling tracked status.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum OfficeSessionTrackedSyncReceiptError {
    Sync(OfficeSyncError),
    Status {
        receipt: OfficeSyncReceipt,
        status_error: OfficeSessionEventError,
    },
}

impl OfficeSessionTrackedSyncReceiptError {
    /// Builds a tracked sync receipt error from a rejected acknowledgement target.
    pub fn sync(error: OfficeSyncError) -> Self {
        Self::Sync(error)
    }

    /// Builds a tracked sync receipt error after acknowledgement but failed status polling.
    pub fn status(receipt: OfficeSyncReceipt, status_error: OfficeSessionEventError) -> Self {
        Self::Status {
            receipt,
            status_error,
        }
    }
}

/// Describes one tracked status poll with an optional incremental delta.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSessionStatusTrackerUpdate {
    pub update: OfficeSessionStatusUpdate,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub delta: Option<OfficeSessionStatusDelta>,
}

impl OfficeSessionStatusTrackerUpdate {
    /// Builds a tracked status update from the raw update and optional delta.
    pub fn new(update: OfficeSessionStatusUpdate, delta: Option<OfficeSessionStatusDelta>) -> Self {
        Self { update, delta }
    }

    /// Returns whether this update is the first hydrate from the tracker.
    pub fn is_initial(&self) -> bool {
        self.delta.is_none()
    }

    /// Returns whether an incremental delta exists and contains changes.
    pub fn has_incremental_changes(&self) -> bool {
        self.delta.as_ref().is_some_and(|delta| !delta.is_empty())
    }

    /// Returns the delivered status snapshot.
    pub fn snapshot(&self) -> &OfficeSessionStatusSnapshot {
        &self.update.snapshot
    }

    /// Returns whether polling had to recover from an event cursor compacted by retention.
    pub fn event_cursor_was_reset(&self) -> bool {
        self.update.event_cursor_was_reset()
    }
}

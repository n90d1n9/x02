//! Snapshot, store persistence, and persistence-related event helpers.

use super::super::{OfficeSaveSkipReason, OfficeSaveTrigger, OfficeSessionEventKind};
use super::OfficeDocumentSession;
use crate::{
    DocumentId, OfficeDocumentPersistReceipt, OfficeDocumentStore, OfficeOperationLogStore,
    OfficeSnapshot, OfficeSnapshotStore,
};

impl<State, Edit> OfficeDocumentSession<State, Edit> {
    pub fn load_from_store<S>(store: &S, document_id: &DocumentId) -> Result<Option<Self>, S::Error>
    where
        S: OfficeSnapshotStore<State, Edit>,
    {
        store
            .load_snapshot(document_id)
            .map(|snapshot| snapshot.map(Self::from_snapshot))
    }

    pub fn save_snapshot_to<S>(&self, store: &mut S, timestamp_ms: u64) -> Result<(), S::Error>
    where
        S: OfficeSnapshotStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        store.save_snapshot(self.snapshot(timestamp_ms))
    }

    pub fn save_operation_log_to<S>(&self, store: &mut S) -> Result<(), S::Error>
    where
        S: OfficeOperationLogStore<Edit>,
        Edit: Clone,
    {
        store.save_operation_log(self.document_id.clone(), self.operation_log.clone())
    }

    pub fn save_snapshot_and_mark_saved_to<S>(
        &mut self,
        store: &mut S,
        timestamp_ms: u64,
    ) -> Result<(), S::Error>
    where
        S: OfficeSnapshotStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        self.save_snapshot_to(store, timestamp_ms)?;
        self.mark_saved(timestamp_ms);
        Ok(())
    }

    pub fn persist_to<S>(&self, store: &mut S, timestamp_ms: u64) -> Result<(), S::Error>
    where
        S: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        self.persist_with_receipt_to(store, timestamp_ms)
            .map(|_| ())
    }

    pub fn persist_with_receipt_to<S>(
        &self,
        store: &mut S,
        timestamp_ms: u64,
    ) -> Result<OfficeDocumentPersistReceipt, S::Error>
    where
        S: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        let snapshot = self.snapshot(timestamp_ms);
        let operation_log = snapshot.operation_log.clone();
        store.save_document(snapshot, operation_log)
    }

    pub fn persist_and_mark_saved_to<S>(
        &mut self,
        store: &mut S,
        timestamp_ms: u64,
    ) -> Result<(), S::Error>
    where
        S: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        self.persist_and_mark_saved_with_receipt_to(store, timestamp_ms)
            .map(|_| ())
    }

    pub fn persist_and_mark_saved_with_receipt_to<S>(
        &mut self,
        store: &mut S,
        timestamp_ms: u64,
    ) -> Result<OfficeDocumentPersistReceipt, S::Error>
    where
        S: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        let receipt = self.persist_with_receipt_to(store, timestamp_ms)?;
        self.record_document_saved(&receipt, timestamp_ms);
        self.mark_saved(timestamp_ms);
        Ok(receipt)
    }

    pub(crate) fn record_document_saved(
        &mut self,
        receipt: &OfficeDocumentPersistReceipt,
        timestamp_ms: u64,
    ) {
        self.record_event(
            OfficeSessionEventKind::DocumentSaved {
                sequence: receipt.snapshot_sequence,
                timestamp_ms: receipt.snapshot_timestamp_ms,
                operation_count: receipt.operation_count,
                persist_mode: receipt.mode,
            },
            timestamp_ms,
        );
    }

    pub(crate) fn record_save_skipped(
        &mut self,
        trigger: Option<OfficeSaveTrigger>,
        reason: OfficeSaveSkipReason,
        timestamp_ms: u64,
    ) {
        self.record_event(
            OfficeSessionEventKind::SaveSkipped { trigger, reason },
            timestamp_ms,
        );
    }

    pub(crate) fn record_recovery_completed(
        &mut self,
        snapshot_sequence: u64,
        recovered_sequence: u64,
        replayed_operation_count: usize,
        timestamp_ms: u64,
    ) {
        self.record_event(
            OfficeSessionEventKind::RecoveryCompleted {
                snapshot_sequence,
                recovered_sequence,
                replayed_operation_count,
            },
            timestamp_ms,
        );
    }

    pub(crate) fn record_compaction_completed(
        &mut self,
        snapshot_sequence: u64,
        removed_operation_count: usize,
        retained_operation_count: usize,
        retained_sequence_range: Option<(u64, u64)>,
        timestamp_ms: u64,
    ) {
        self.record_event(
            OfficeSessionEventKind::CompactionCompleted {
                snapshot_sequence,
                removed_operation_count,
                retained_operation_count,
                retained_sequence_range,
            },
            timestamp_ms,
        );
    }

    pub fn snapshot(&self, timestamp_ms: u64) -> OfficeSnapshot<State, Edit>
    where
        State: Clone,
        Edit: Clone,
    {
        OfficeSnapshot::new(
            self.engine.clone(),
            self.document_id.clone(),
            self.sequence,
            timestamp_ms,
            self.state.clone(),
        )
        .with_operation_log(self.operation_log.clone())
        .with_selection(self.selection.clone())
    }
}

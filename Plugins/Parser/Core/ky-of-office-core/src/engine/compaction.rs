use crate::{
    DocumentId, OfficeDocumentStore, OfficeOperationBatch, OfficeSnapshot, OfficeSyncCursor,
    OfficeSyncError, OperationLog, Validatable, ValidationReport,
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeCompactionPolicy {
    pub retain_snapshot_operation_log: bool,
}

impl Default for OfficeCompactionPolicy {
    fn default() -> Self {
        Self {
            retain_snapshot_operation_log: false,
        }
    }
}

impl OfficeCompactionPolicy {
    pub fn retain_snapshot_operation_log() -> Self {
        Self {
            retain_snapshot_operation_log: true,
        }
    }

    pub fn with_retain_snapshot_operation_log(
        mut self,
        retain_snapshot_operation_log: bool,
    ) -> Self {
        self.retain_snapshot_operation_log = retain_snapshot_operation_log;
        self
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeCompactionReport {
    pub document_id: DocumentId,
    pub snapshot_sequence: u64,
    pub original_operation_count: usize,
    pub retained_operation_count: usize,
    pub removed_operation_count: usize,
    pub snapshot_operation_count: usize,
    pub retained_sequence_range: Option<(u64, u64)>,
}

impl OfficeCompactionReport {
    pub fn removed_operations(&self) -> bool {
        self.removed_operation_count > 0
    }

    pub fn compacted_operations(&self) -> bool {
        self.removed_operation_count > 0
    }

    pub fn retained_operations(&self) -> bool {
        self.retained_operation_count > 0
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct OfficeCompactedDocument<State, Edit> {
    pub snapshot: OfficeSnapshot<State, Edit>,
    pub operation_log: OperationLog<Edit>,
    pub report: OfficeCompactionReport,
}

#[derive(Debug, Clone, PartialEq)]
pub enum OfficeCompactionError {
    Snapshot(ValidationReport),
    Sync(OfficeSyncError),
}

impl OfficeCompactionError {
    pub fn snapshot(report: ValidationReport) -> Self {
        Self::Snapshot(report)
    }

    pub fn sync(error: OfficeSyncError) -> Self {
        Self::Sync(error)
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum OfficeCompactionStoreError<StoreError> {
    Store(StoreError),
    Compaction(OfficeCompactionError),
}

impl<StoreError> OfficeCompactionStoreError<StoreError> {
    pub fn store(error: StoreError) -> Self {
        Self::Store(error)
    }

    pub fn compaction(error: OfficeCompactionError) -> Self {
        Self::Compaction(error)
    }
}

pub type OfficeCompactionStoreResult<Store> = Result<
    Option<OfficeCompactionReport>,
    OfficeCompactionStoreError<<Store as crate::OfficeStore>::Error>,
>;

pub fn compact_snapshot_and_log<State, Edit>(
    snapshot: OfficeSnapshot<State, Edit>,
    operation_log: OperationLog<Edit>,
    policy: OfficeCompactionPolicy,
) -> Result<OfficeCompactedDocument<State, Edit>, OfficeCompactionError>
where
    Edit: Clone,
{
    snapshot
        .require_valid()
        .map_err(OfficeCompactionError::snapshot)?;

    let cursor = OfficeSyncCursor::from_snapshot(&snapshot);
    let batch = OfficeOperationBatch::from_log_after(cursor, &operation_log)
        .map_err(OfficeCompactionError::sync)?;
    let original_operation_count = operation_log.len();
    let retained_operation_log = batch.operation_log();
    let retained_operation_count = retained_operation_log.len();
    let retained_sequence_range = retained_operation_log
        .operations
        .first()
        .zip(retained_operation_log.operations.last())
        .map(|(first, last)| (first.sequence, last.sequence));

    let mut compacted_snapshot = snapshot;
    if !policy.retain_snapshot_operation_log {
        compacted_snapshot.operation_log = OperationLog::new();
    }

    let report = OfficeCompactionReport {
        document_id: compacted_snapshot.document_id.clone(),
        snapshot_sequence: compacted_snapshot.sequence,
        original_operation_count,
        retained_operation_count,
        removed_operation_count: original_operation_count.saturating_sub(retained_operation_count),
        snapshot_operation_count: compacted_snapshot.operation_log.len(),
        retained_sequence_range,
    };

    Ok(OfficeCompactedDocument {
        snapshot: compacted_snapshot,
        operation_log: retained_operation_log,
        report,
    })
}

pub fn compact_document_in_store<State, Edit, Store>(
    store: &mut Store,
    document_id: &DocumentId,
    policy: OfficeCompactionPolicy,
) -> OfficeCompactionStoreResult<Store>
where
    Store: OfficeDocumentStore<State, Edit>,
    State: Clone,
    Edit: Clone,
{
    let Some(snapshot) = store
        .load_snapshot(document_id)
        .map_err(OfficeCompactionStoreError::store)?
    else {
        return Ok(None);
    };

    let operation_log = store
        .load_operation_log(document_id)
        .map_err(OfficeCompactionStoreError::store)?
        .unwrap_or_else(|| snapshot.operation_log.clone());
    let compacted = compact_snapshot_and_log(snapshot, operation_log, policy)
        .map_err(OfficeCompactionStoreError::compaction)?;
    let report = compacted.report.clone();

    store
        .save_document(compacted.snapshot, compacted.operation_log)
        .map_err(OfficeCompactionStoreError::store)?;

    Ok(Some(report))
}

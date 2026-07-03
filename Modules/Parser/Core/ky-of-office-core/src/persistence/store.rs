use crate::{DocumentId, OfficeSnapshot, OperationEnvelope, OperationLog};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeDocumentPersistMode {
    Atomic,
    SequentialFallback,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeDocumentPersistReceipt {
    pub document_id: DocumentId,
    pub snapshot_sequence: u64,
    pub snapshot_timestamp_ms: u64,
    pub operation_count: usize,
    pub operation_sequence_range: Option<(u64, u64)>,
    pub mode: OfficeDocumentPersistMode,
}

impl OfficeDocumentPersistReceipt {
    pub fn new<State, Edit>(
        snapshot: &OfficeSnapshot<State, Edit>,
        operation_log: &OperationLog<Edit>,
        mode: OfficeDocumentPersistMode,
    ) -> Self {
        let operation_sequence_range = operation_log
            .operations
            .first()
            .zip(operation_log.operations.last())
            .map(|(first, last)| (first.sequence, last.sequence));

        Self {
            document_id: snapshot.document_id.clone(),
            snapshot_sequence: snapshot.sequence,
            snapshot_timestamp_ms: snapshot.timestamp_ms,
            operation_count: operation_log.len(),
            operation_sequence_range,
            mode,
        }
    }

    pub fn atomic<State, Edit>(
        snapshot: &OfficeSnapshot<State, Edit>,
        operation_log: &OperationLog<Edit>,
    ) -> Self {
        Self::new(snapshot, operation_log, OfficeDocumentPersistMode::Atomic)
    }

    pub fn sequential_fallback<State, Edit>(
        snapshot: &OfficeSnapshot<State, Edit>,
        operation_log: &OperationLog<Edit>,
    ) -> Self {
        Self::new(
            snapshot,
            operation_log,
            OfficeDocumentPersistMode::SequentialFallback,
        )
    }
}

pub trait OfficeStore {
    type Error;
}

pub trait OfficeSnapshotStore<State, Edit>: OfficeStore {
    fn load_snapshot(
        &self,
        document_id: &DocumentId,
    ) -> Result<Option<OfficeSnapshot<State, Edit>>, Self::Error>;

    fn save_snapshot(&mut self, snapshot: OfficeSnapshot<State, Edit>) -> Result<(), Self::Error>;

    fn delete_snapshot(&mut self, document_id: &DocumentId) -> Result<bool, Self::Error>;
}

pub trait OfficeOperationLogStore<Edit>: OfficeStore {
    fn load_operation_log(
        &self,
        document_id: &DocumentId,
    ) -> Result<Option<OperationLog<Edit>>, Self::Error>;

    fn save_operation_log(
        &mut self,
        document_id: DocumentId,
        operation_log: OperationLog<Edit>,
    ) -> Result<(), Self::Error>;

    fn append_operation(&mut self, operation: OperationEnvelope<Edit>) -> Result<(), Self::Error>;

    fn delete_operation_log(&mut self, document_id: &DocumentId) -> Result<bool, Self::Error>;
}

pub trait OfficeDocumentStore<State, Edit>:
    OfficeSnapshotStore<State, Edit> + OfficeOperationLogStore<Edit>
{
    fn save_document(
        &mut self,
        snapshot: OfficeSnapshot<State, Edit>,
        operation_log: OperationLog<Edit>,
    ) -> Result<OfficeDocumentPersistReceipt, Self::Error> {
        let receipt = OfficeDocumentPersistReceipt::sequential_fallback(&snapshot, &operation_log);
        let document_id = snapshot.document_id.clone();

        self.save_snapshot(snapshot)?;
        self.save_operation_log(document_id, operation_log)?;

        Ok(receipt)
    }
}

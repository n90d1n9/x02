use super::{
    OfficeDocumentPersistReceipt, OfficeDocumentStore, OfficeOperationLogStore,
    OfficeSnapshotStore, OfficeStore,
};
use crate::{DocumentId, OfficeSnapshot, OperationEnvelope, OperationLog};
use std::collections::BTreeMap;
use std::convert::Infallible;

#[derive(Debug, Clone, Default, PartialEq)]
pub struct InMemoryOfficeStore<State, Edit> {
    snapshots: BTreeMap<DocumentId, OfficeSnapshot<State, Edit>>,
    operation_logs: BTreeMap<DocumentId, OperationLog<Edit>>,
}

impl<State, Edit> InMemoryOfficeStore<State, Edit> {
    pub fn new() -> Self {
        Self {
            snapshots: BTreeMap::new(),
            operation_logs: BTreeMap::new(),
        }
    }

    pub fn snapshot_count(&self) -> usize {
        self.snapshots.len()
    }

    pub fn operation_log_count(&self) -> usize {
        self.operation_logs.len()
    }

    pub fn contains_snapshot(&self, document_id: &DocumentId) -> bool {
        self.snapshots.contains_key(document_id)
    }

    pub fn contains_operation_log(&self, document_id: &DocumentId) -> bool {
        self.operation_logs.contains_key(document_id)
    }
}

impl<State, Edit> OfficeStore for InMemoryOfficeStore<State, Edit> {
    type Error = Infallible;
}

impl<State, Edit> OfficeSnapshotStore<State, Edit> for InMemoryOfficeStore<State, Edit>
where
    State: Clone,
    Edit: Clone,
{
    fn load_snapshot(
        &self,
        document_id: &DocumentId,
    ) -> Result<Option<OfficeSnapshot<State, Edit>>, Self::Error> {
        Ok(self.snapshots.get(document_id).cloned())
    }

    fn save_snapshot(&mut self, snapshot: OfficeSnapshot<State, Edit>) -> Result<(), Self::Error> {
        let document_id = snapshot.document_id.clone();
        self.operation_logs
            .insert(document_id.clone(), snapshot.operation_log.clone());
        self.snapshots.insert(document_id, snapshot);
        Ok(())
    }

    fn delete_snapshot(&mut self, document_id: &DocumentId) -> Result<bool, Self::Error> {
        Ok(self.snapshots.remove(document_id).is_some())
    }
}

impl<State, Edit> OfficeOperationLogStore<Edit> for InMemoryOfficeStore<State, Edit>
where
    Edit: Clone,
{
    fn load_operation_log(
        &self,
        document_id: &DocumentId,
    ) -> Result<Option<OperationLog<Edit>>, Self::Error> {
        Ok(self.operation_logs.get(document_id).cloned())
    }

    fn save_operation_log(
        &mut self,
        document_id: DocumentId,
        operation_log: OperationLog<Edit>,
    ) -> Result<(), Self::Error> {
        self.operation_logs.insert(document_id, operation_log);
        Ok(())
    }

    fn append_operation(&mut self, operation: OperationEnvelope<Edit>) -> Result<(), Self::Error> {
        let document_id = operation.document_id.clone();
        self.operation_logs
            .entry(document_id)
            .or_insert_with(OperationLog::new)
            .push(operation);
        Ok(())
    }

    fn delete_operation_log(&mut self, document_id: &DocumentId) -> Result<bool, Self::Error> {
        Ok(self.operation_logs.remove(document_id).is_some())
    }
}

impl<State, Edit> OfficeDocumentStore<State, Edit> for InMemoryOfficeStore<State, Edit>
where
    State: Clone,
    Edit: Clone,
{
    fn save_document(
        &mut self,
        snapshot: OfficeSnapshot<State, Edit>,
        operation_log: OperationLog<Edit>,
    ) -> Result<OfficeDocumentPersistReceipt, Self::Error> {
        let receipt = OfficeDocumentPersistReceipt::atomic(&snapshot, &operation_log);
        let document_id = snapshot.document_id.clone();

        self.snapshots.insert(document_id.clone(), snapshot);
        self.operation_logs.insert(document_id, operation_log);

        Ok(receipt)
    }
}

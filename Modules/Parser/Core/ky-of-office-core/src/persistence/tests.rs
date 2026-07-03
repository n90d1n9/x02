use super::*;
use crate::{DocumentId, OfficeSnapshot, OperationEnvelope, OperationLog};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
enum TestEdit {
    Add(i64),
    Set(i64),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
struct TestState {
    value: i64,
}

fn operation(
    document_id: impl Into<DocumentId>,
    operation_id: &str,
    sequence: u64,
    edit: TestEdit,
) -> OperationEnvelope<TestEdit> {
    OperationEnvelope::new(
        "counter",
        operation_id,
        document_id,
        "actor-1",
        sequence,
        1_000 + sequence,
        edit,
    )
}

fn snapshot() -> OfficeSnapshot<TestState, TestEdit> {
    OfficeSnapshot::new("counter", "doc-1", 2, 2_000, TestState { value: 12 })
        .with_operation_log(OperationLog::from_operations(vec![
            operation("doc-1", "op-1", 1, TestEdit::Add(5)),
            operation("doc-1", "op-2", 2, TestEdit::Add(7)),
        ]))
        .with_metadata_text("source", "test")
}

fn accepts_document_store<S>(store: &mut S)
where
    S: OfficeDocumentStore<TestState, TestEdit>,
{
    let _ = store.load_snapshot(&DocumentId::new("doc-1"));
    let _ = store.load_operation_log(&DocumentId::new("doc-1"));
}

#[test]
fn memory_store_saves_loads_and_deletes_snapshots() {
    let mut store = InMemoryOfficeStore::new();
    let snapshot = snapshot();

    store.save_snapshot(snapshot.clone()).unwrap();

    let document_id = DocumentId::new("doc-1");
    let restored = store.load_snapshot(&document_id).unwrap().unwrap();
    let restored_log = store.load_operation_log(&document_id).unwrap().unwrap();

    assert_eq!(restored, snapshot);
    assert_eq!(restored_log.len(), 2);
    assert_eq!(store.snapshot_count(), 1);
    assert_eq!(store.operation_log_count(), 1);
    assert!(store.contains_snapshot(&document_id));
    assert!(store.contains_operation_log(&document_id));
    accepts_document_store(&mut store);

    assert!(store.delete_snapshot(&document_id).unwrap());
    assert!(!store.delete_snapshot(&document_id).unwrap());
    assert!(store.load_snapshot(&document_id).unwrap().is_none());
    assert!(store.load_operation_log(&document_id).unwrap().is_some());
}

#[test]
fn memory_store_saves_document_with_atomic_receipt() {
    let mut store = InMemoryOfficeStore::new();
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 2, 2_000, TestState { value: 12 });
    let retained_log =
        OperationLog::from_operations(vec![operation("doc-1", "op-3", 3, TestEdit::Add(1))]);

    let receipt = store
        .save_document(snapshot.clone(), retained_log.clone())
        .unwrap();

    assert_eq!(
        receipt,
        OfficeDocumentPersistReceipt {
            document_id: DocumentId::new("doc-1"),
            snapshot_sequence: 2,
            snapshot_timestamp_ms: 2_000,
            operation_count: 1,
            operation_sequence_range: Some((3, 3)),
            mode: OfficeDocumentPersistMode::Atomic,
        }
    );
    let document_id = DocumentId::new("doc-1");
    let restored_snapshot = store.load_snapshot(&document_id).unwrap().unwrap();
    let restored_log = store.load_operation_log(&document_id).unwrap().unwrap();
    assert_eq!(restored_snapshot, snapshot);
    assert_eq!(restored_snapshot.operation_log.len(), 0);
    assert_eq!(restored_log, retained_log);
}

#[test]
fn memory_store_appends_operation_logs_by_document() {
    let mut store: InMemoryOfficeStore<TestState, TestEdit> = InMemoryOfficeStore::new();
    let doc_1 = DocumentId::new("doc-1");
    let doc_2 = DocumentId::new("doc-2");

    store
        .append_operation(operation(doc_1.clone(), "op-1", 1, TestEdit::Add(5)))
        .unwrap();
    store
        .append_operation(operation(doc_1.clone(), "op-2", 2, TestEdit::Set(3)))
        .unwrap();
    store
        .append_operation(operation(doc_2.clone(), "op-3", 1, TestEdit::Add(9)))
        .unwrap();

    let doc_1_log = store.load_operation_log(&doc_1).unwrap().unwrap();
    let doc_2_log = store.load_operation_log(&doc_2).unwrap().unwrap();

    assert_eq!(doc_1_log.len(), 2);
    assert_eq!(doc_2_log.len(), 1);
    assert_eq!(doc_1_log.operations[0].operation_id, "op-1");
    assert_eq!(doc_1_log.operations[1].operation_id, "op-2");
    assert_eq!(doc_2_log.operations[0].operation_id, "op-3");
}

#[test]
fn memory_store_replaces_and_deletes_operation_logs() {
    let mut store: InMemoryOfficeStore<TestState, TestEdit> = InMemoryOfficeStore::new();
    let document_id = DocumentId::new("doc-1");

    store
        .append_operation(operation(document_id.clone(), "op-1", 1, TestEdit::Add(5)))
        .unwrap();
    store
        .save_operation_log(
            document_id.clone(),
            OperationLog::from_operations(vec![operation(
                document_id.clone(),
                "op-2",
                2,
                TestEdit::Set(8),
            )]),
        )
        .unwrap();

    let restored = store.load_operation_log(&document_id).unwrap().unwrap();

    assert_eq!(restored.len(), 1);
    assert_eq!(restored.operations[0].operation_id, "op-2");
    assert!(store.delete_operation_log(&document_id).unwrap());
    assert!(!store.delete_operation_log(&document_id).unwrap());
    assert!(store.load_operation_log(&document_id).unwrap().is_none());
}

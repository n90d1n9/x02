use super::*;
use crate::{OfficeSnapshot, OperationEnvelope, OperationLog};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
enum TestEdit {
    Add(i64),
}

fn operation(operation_id: &str, document_id: &str, sequence: u64) -> OperationEnvelope<TestEdit> {
    OperationEnvelope::new(
        "counter",
        operation_id,
        document_id,
        "actor-1",
        sequence,
        1_000 + sequence,
        TestEdit::Add(sequence as i64),
    )
}

fn operation_log() -> OperationLog<TestEdit> {
    OperationLog::from_operations(vec![
        operation("op-1", "doc-1", 1),
        operation("op-2", "doc-1", 2),
        operation("op-3", "doc-1", 3),
    ])
}

#[test]
fn cursor_tracks_snapshot_position_and_operation_identity() {
    let snapshot: OfficeSnapshot<String, TestEdit> =
        OfficeSnapshot::new("counter", "doc-1", 7, 9_000, "state".into());
    let cursor = OfficeSyncCursor::from_snapshot(&snapshot);

    assert_eq!(cursor.engine, "counter");
    assert_eq!(cursor.document_id, "doc-1");
    assert_eq!(cursor.sequence, 7);
    assert!(cursor.matches_operation(&operation("op-8", "doc-1", 8)));
    assert!(!cursor.matches_operation(&operation("op-8", "other-doc", 8)));
}

#[test]
fn batch_collects_operations_after_cursor() {
    let cursor = OfficeSyncCursor::new("counter", "doc-1", 1);
    let batch = collect_operations_after(cursor.clone(), &operation_log()).unwrap();

    assert_eq!(batch.base, cursor);
    assert_eq!(batch.target, OfficeSyncCursor::new("counter", "doc-1", 3));
    assert_eq!(batch.len(), 2);
    assert_eq!(batch.operations[0].operation_id, "op-2");
    assert_eq!(batch.operations[1].operation_id, "op-3");
    assert_eq!(batch.operation_log().len(), 2);
    assert_eq!(validate_incoming_batch(&batch.base, &batch), Ok(()));
}

#[test]
fn batch_returns_empty_delta_when_cursor_is_current() {
    let cursor = OfficeSyncCursor::new("counter", "doc-1", 3);
    let batch = OfficeOperationBatch::from_log_after(cursor.clone(), &operation_log()).unwrap();

    assert!(batch.is_empty());
    assert_eq!(batch.base, cursor);
    assert_eq!(batch.target, OfficeSyncCursor::new("counter", "doc-1", 3));
    assert_eq!(batch.validate(), Ok(()));
}

#[test]
fn batch_rejects_operation_identity_mismatch() {
    let log = OperationLog::from_operations(vec![operation("op-1", "other-doc", 1)]);
    let err =
        collect_operations_after(OfficeSyncCursor::new("counter", "doc-1", 0), &log).unwrap_err();

    assert_eq!(
        err,
        OfficeSyncError::OperationDocumentMismatch {
            sequence: 1,
            expected: "doc-1".into(),
            actual: "other-doc".into(),
        }
    );
}

#[test]
fn batch_rejects_non_increasing_operation_sequences() {
    let log = OperationLog::from_operations(vec![
        operation("op-2", "doc-1", 2),
        operation("op-2b", "doc-1", 2),
    ]);
    let err =
        collect_operations_after(OfficeSyncCursor::new("counter", "doc-1", 0), &log).unwrap_err();

    assert_eq!(
        err,
        OfficeSyncError::NonIncreasingSequence {
            previous: 2,
            next: 2,
        }
    );
}

#[test]
fn incoming_batch_requires_matching_base_cursor() {
    let cursor = OfficeSyncCursor::new("counter", "doc-1", 1);
    let batch = collect_operations_after(cursor.clone(), &operation_log()).unwrap();
    let current = OfficeSyncCursor::new("counter", "doc-1", 0);

    let err = validate_incoming_batch(&current, &batch).unwrap_err();

    assert_eq!(
        err,
        OfficeSyncError::BatchBaseMismatch {
            expected: current,
            actual: cursor,
        }
    );
}

#[test]
fn batch_rejects_target_that_does_not_match_last_operation() {
    let batch = OfficeOperationBatch::new(
        OfficeSyncCursor::new("counter", "doc-1", 1),
        OfficeSyncCursor::new("counter", "doc-1", 5),
        vec![operation("op-2", "doc-1", 2)],
    );

    assert_eq!(
        batch.validate(),
        Err(OfficeSyncError::TargetSequenceMismatch {
            expected: 2,
            actual: 5,
        })
    );
}

use super::*;
use crate::OperationEnvelope;
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
enum TestEdit {
    Add(i64),
    Set(i64),
}

#[derive(Default)]
struct Counter {
    value: i64,
    applied_ids: Vec<String>,
}

impl OperationApplier<TestEdit> for Counter {
    type Outcome = i64;
    type Error = String;

    fn apply_operation(
        &mut self,
        operation: OperationEnvelope<TestEdit>,
    ) -> Result<Self::Outcome, Self::Error> {
        self.applied_ids.push(operation.operation_id.into_string());
        match operation.edit {
            TestEdit::Add(amount) => {
                self.value += amount;
                Ok(self.value)
            }
            TestEdit::Set(value) => {
                self.value = value;
                Ok(self.value)
            }
        }
    }
}

fn operation(operation_id: &str, sequence: u64, edit: TestEdit) -> OperationEnvelope<TestEdit> {
    OperationEnvelope::new(
        "test",
        operation_id,
        "doc-1",
        "actor-1",
        sequence,
        1_000 + sequence,
        edit,
    )
}

#[test]
fn transaction_validates_consistent_operation_streams() {
    let transaction = OperationTransaction::new("tx-1")
        .with_operation(operation("op-1", 1, TestEdit::Add(2)))
        .with_operation(operation("op-2", 2, TestEdit::Add(3)));

    assert_eq!(transaction.validate(), Ok(()));

    let invalid = OperationTransaction::new("tx-2")
        .with_operation(operation("op-1", 2, TestEdit::Add(2)))
        .with_operation(operation("op-2", 2, TestEdit::Add(3)));

    assert_eq!(
        invalid.validate(),
        Err(TransactionError::NonIncreasingSequence {
            transaction_id: "tx-2".into(),
            previous: 2,
            next: 2,
        })
    );
}

#[test]
fn transaction_json_roundtrips_with_inverse_operations() {
    let transaction = OperationTransaction::new("tx-1")
        .with_operation(operation("op-1", 1, TestEdit::Add(5)))
        .with_inverse_operation(operation("undo-op-1", 2, TestEdit::Add(-5)))
        .with_metadata_text("source", "unit-test");

    let json = transaction.to_json().unwrap();
    let restored = OperationTransaction::<TestEdit>::from_json(&json).unwrap();

    assert_eq!(restored.transaction_id, "tx-1");
    assert_eq!(restored.len(), 1);
    assert_eq!(restored.inverse_operations.len(), 1);
    assert_eq!(
        restored.metadata.get("source"),
        Some(&Value::String("unit-test".into()))
    );
}

#[test]
fn transaction_builder_creates_valid_undoable_transactions() {
    let transaction = OperationTransaction::builder("tx-1")
        .operation_pair(
            operation("op-1", 1, TestEdit::Add(5)),
            operation("undo-op-1", 1, TestEdit::Add(-5)),
        )
        .metadata_text("source", "builder")
        .metadata_value("interactive", Value::Bool(true))
        .build_undoable()
        .unwrap();

    assert_eq!(transaction.transaction_id, "tx-1");
    assert_eq!(transaction.operations.len(), 1);
    assert_eq!(transaction.inverse_operations.len(), 1);
    assert_eq!(transaction.validate_undoable(), Ok(()));
    assert_eq!(
        transaction.metadata.get("source"),
        Some(&Value::String("builder".into()))
    );
    assert_eq!(
        transaction.metadata.get("interactive"),
        Some(&Value::Bool(true))
    );
}

#[test]
fn transaction_builder_rejects_undoable_transactions_without_inverses() {
    let err = OperationTransactionBuilder::new("tx-1")
        .operation(operation("op-1", 1, TestEdit::Add(5)))
        .build_undoable()
        .unwrap_err();

    assert_eq!(
        err,
        TransactionError::MissingInverseOperations {
            transaction_id: "tx-1".into()
        }
    );
}

#[test]
fn transaction_builder_rejects_inverse_identity_mismatches() {
    let inverse = OperationEnvelope::new(
        "test",
        "undo-op-1",
        "other-doc",
        "actor-1",
        1,
        1_001,
        TestEdit::Add(-5),
    );

    let err = OperationTransaction::builder("tx-1")
        .operation_pair(operation("op-1", 1, TestEdit::Add(5)), inverse)
        .build_undoable()
        .unwrap_err();

    assert_eq!(
        err,
        TransactionError::MismatchedDocument {
            transaction_id: "tx-1".into(),
            expected: "doc-1".into(),
            actual: "other-doc".into(),
        }
    );
}

#[test]
fn history_commit_undo_and_redo_use_inverse_and_forward_operations() {
    let transaction = OperationTransaction::new("tx-1")
        .with_operation(operation("op-1", 1, TestEdit::Add(5)))
        .with_inverse_operation(operation("undo-op-1", 2, TestEdit::Add(-5)));
    let mut history = TransactionHistory::new();

    history.commit(transaction).unwrap();
    assert!(history.can_undo());
    assert!(!history.can_redo());

    let undo_ops = history.undo_operations().unwrap();
    assert_eq!(undo_ops.len(), 1);
    assert_eq!(undo_ops[0].operation_id, "undo-op-1");
    assert!(!history.can_undo());
    assert!(history.can_redo());

    let redo_ops = history.redo_operations();
    assert_eq!(redo_ops.len(), 1);
    assert_eq!(redo_ops[0].operation_id, "op-1");
    assert!(history.can_undo());
    assert!(!history.can_redo());
}

#[test]
fn apply_transaction_invokes_applier_in_order() {
    let transaction = OperationTransaction::new("tx-1")
        .with_operation(operation("op-1", 1, TestEdit::Add(5)))
        .with_operation(operation("op-2", 2, TestEdit::Set(3)))
        .with_operation(operation("op-3", 3, TestEdit::Add(7)));
    let mut counter = Counter::default();

    let outcomes = apply_transaction(&mut counter, &transaction).unwrap();

    assert_eq!(outcomes, vec![5, 3, 10]);
    assert_eq!(counter.value, 10);
    assert_eq!(counter.applied_ids, vec!["op-1", "op-2", "op-3"]);
}

#[test]
fn history_enforces_max_depth_and_flattens_to_operation_log() {
    let mut history = TransactionHistory::with_max_depth(1);
    history
        .commit(OperationTransaction::new("tx-1").with_operation(operation(
            "op-1",
            1,
            TestEdit::Add(1),
        )))
        .unwrap();
    history
        .commit(OperationTransaction::new("tx-2").with_operation(operation(
            "op-2",
            2,
            TestEdit::Add(2),
        )))
        .unwrap();

    let log = history.operation_log();

    assert_eq!(history.committed_len(), 1);
    assert_eq!(log.operations.len(), 1);
    assert_eq!(log.operations[0].operation_id, "op-2");
}

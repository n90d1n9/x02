use super::*;
use crate::{OfficeSelection, OperationEnvelope, TextSelection};
use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
struct TestState {
    title: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
enum TestEdit {
    Rename { title: String },
}

fn edit_operation(sequence: u64, title: &str) -> OperationEnvelope<TestEdit> {
    OperationEnvelope::new(
        "docs",
        format!("op-{sequence}"),
        "doc-1",
        "actor-1",
        sequence,
        1_000 + sequence,
        TestEdit::Rename {
            title: title.into(),
        },
    )
}

#[test]
fn snapshot_roundtrips_state_operation_log_and_metadata() {
    let mut operation_log = crate::OperationLog::new();
    operation_log.push(edit_operation(1, "Draft"));
    operation_log.push(edit_operation(2, "Final"));

    let snapshot = OfficeSnapshot::new(
        "docs",
        "doc-1",
        2,
        10_000,
        TestState {
            title: "Final".into(),
        },
    )
    .with_operation_log(operation_log)
    .with_selection(OfficeSelection::Text(TextSelection::caret(5)))
    .with_metadata_text("source", "unit-test")
    .with_metadata_value("autosave", Value::Bool(true));

    let json = snapshot.to_json().unwrap();
    let restored = OfficeSnapshot::<TestState, TestEdit>::from_json(&json).unwrap();

    assert_eq!(restored.engine, "docs");
    assert_eq!(restored.document_id, "doc-1");
    assert_eq!(restored.sequence, 2);
    assert_eq!(restored.state.title, "Final");
    assert_eq!(
        restored.selection,
        OfficeSelection::Text(TextSelection::caret(5))
    );
    assert_eq!(restored.operation_log.len(), 2);
    assert_eq!(
        restored.metadata.get("source"),
        Some(&Value::String("unit-test".into()))
    );
    assert_eq!(restored.metadata.get("autosave"), Some(&Value::Bool(true)));
}

#[test]
fn snapshot_maps_state_without_touching_identity_or_history() {
    let snapshot = OfficeSnapshot::<_, TestEdit>::new(
        "sheet",
        "sheet-1",
        4,
        20_000,
        TestState {
            title: "Raw".into(),
        },
    );

    let mapped = snapshot.map_state(|state| state.title);

    assert_eq!(mapped.engine, "sheet");
    assert_eq!(mapped.document_id, "sheet-1");
    assert_eq!(mapped.sequence, 4);
    assert_eq!(mapped.state, "Raw");
    assert_eq!(mapped.selection, OfficeSelection::None);
    assert!(mapped.operation_log.is_empty());
}

use super::*;
use crate::{OfficeSnapshot, OperationEnvelope, OperationLog, OperationTransaction};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
enum TestEdit {
    Rename { title: String },
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
struct TestState {
    title: String,
}

fn edit(title: &str) -> TestEdit {
    TestEdit::Rename {
        title: title.into(),
    }
}

fn operation(sequence: u64) -> OperationEnvelope<TestEdit> {
    OperationEnvelope::new(
        "docs",
        format!("op-{sequence}"),
        "doc-1",
        "actor-1",
        sequence,
        1_000 + sequence,
        edit("Draft"),
    )
}

#[test]
fn validation_report_counts_severities_and_roundtrips() {
    let mut report = ValidationReport::new();
    report.push(ValidationIssue::error("required", "Required").with_path("title"));
    report.push(ValidationIssue::warning("stale", "Stale"));
    report.push(ValidationIssue::info("note", "Note"));

    assert_eq!(report.error_count(), 1);
    assert_eq!(report.warning_count(), 1);
    assert_eq!(report.info_count(), 1);
    assert!(!report.is_valid());

    let json = report.to_json().unwrap();
    let restored = ValidationReport::from_json(&json).unwrap();

    assert_eq!(restored, report);
}

#[test]
fn operation_validation_reports_empty_identity_fields() {
    let operation = OperationEnvelope::new("", "", "doc-1", "", 1, 1_000, edit("Draft"));
    let report = operation.validate_report();

    assert_eq!(report.error_count(), 3);
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.path.as_deref() == Some("engine")));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.path.as_deref() == Some("operation_id")));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.path.as_deref() == Some("actor_id")));
}

#[test]
fn operation_log_validation_prefixes_operation_paths() {
    let mut log = OperationLog::new();
    log.push(OperationEnvelope::new(
        "docs",
        "op-1",
        "",
        "actor-1",
        1,
        1_000,
        edit("Draft"),
    ));

    let report = log.validate_report();

    assert_eq!(report.error_count(), 1);
    assert_eq!(
        report.issues()[0].path.as_deref(),
        Some("operations[0].document_id")
    );
}

#[test]
fn transaction_validation_reports_stream_errors() {
    let transaction = OperationTransaction::new("tx-1")
        .with_operation(operation(2))
        .with_operation(operation(2));

    let report = transaction.validate_report();

    assert!(!report.is_valid());
    assert!(report.issues().iter().any(|issue| {
        issue.code == "transaction.operations.sequence_not_increasing"
            && issue.path.as_deref() == Some("operations")
    }));
}

#[test]
fn snapshot_validation_reports_mismatched_operation_history() {
    let mut log = OperationLog::new();
    log.push(OperationEnvelope::new(
        "sheet",
        "op-1",
        "other-doc",
        "actor-1",
        3,
        1_003,
        edit("Draft"),
    ));

    let snapshot = OfficeSnapshot::new(
        "docs",
        "doc-1",
        2,
        2_000,
        TestState {
            title: "Draft".into(),
        },
    )
    .with_operation_log(log);

    let report = snapshot.validate_report();

    assert_eq!(report.error_count(), 3);
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "snapshot.operation.engine_mismatch"));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "snapshot.operation.document_mismatch"));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "snapshot.operation.sequence_after_snapshot"));
}

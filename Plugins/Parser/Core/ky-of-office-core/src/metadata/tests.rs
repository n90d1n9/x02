use super::*;
use crate::{OfficeSnapshot, OperationLog, Validatable};
use serde_json::Value;

#[test]
fn document_metadata_tracks_owner_timestamps_revision_and_properties() {
    let mut metadata = OfficeDocumentMetadata::new("Budget", 1_000)
        .with_owner_id("actor-1")
        .with_version_label("v1")
        .with_property_text("department", "finance")
        .with_property_value("locked", Value::Bool(false));

    assert_eq!(metadata.title, "Budget");
    assert_eq!(metadata.owner_id.as_ref().unwrap().as_str(), "actor-1");
    assert_eq!(metadata.created_at_ms, 1_000);
    assert_eq!(metadata.updated_at_ms, 1_000);
    assert_eq!(metadata.revision, 0);

    metadata.set_title("Budget 2027", 1_500);
    assert_eq!(metadata.title, "Budget 2027");
    assert_eq!(metadata.updated_at_ms, 1_500);
    assert_eq!(metadata.advance_revision(1_700), 1);
    assert_eq!(metadata.revision, 1);
    assert_eq!(metadata.updated_at_ms, 1_700);
    assert!(metadata.validate_report().is_valid());
}

#[test]
fn document_metadata_validation_reports_invalid_fields() {
    let metadata = OfficeDocumentMetadata {
        title: " ".into(),
        owner_id: Some(" ".into()),
        created_at_ms: 2_000,
        updated_at_ms: 1_000,
        revision: 0,
        version_label: Some(" ".into()),
        properties: [(" ".into(), Value::Bool(true))].into_iter().collect(),
    };

    let report = metadata.validate_report();

    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "metadata.title.empty"));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "metadata.owner.empty"));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "metadata.updated_before_created"));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "metadata.version_label.empty"));
    assert!(report
        .issues()
        .iter()
        .any(|issue| issue.code == "metadata.property_key.empty"));
}

#[test]
fn snapshot_embeds_and_roundtrips_typed_document_metadata() {
    let metadata = OfficeDocumentMetadata::new("Quarterly Plan", 1_000)
        .with_owner_id("actor-1")
        .with_revision(3)
        .with_version_label("v3");
    let snapshot: OfficeSnapshot<String, String> =
        OfficeSnapshot::new("docs", "doc-1", 7, 2_000, "body".into())
            .with_operation_log(OperationLog::new())
            .try_with_document_metadata(metadata.clone())
            .unwrap();

    assert_eq!(
        snapshot.document_metadata().unwrap(),
        Some(metadata.clone())
    );
    assert!(snapshot.metadata.contains_key(OFFICE_DOCUMENT_METADATA_KEY));

    let json = snapshot.to_json().unwrap();
    let restored = OfficeSnapshot::<String, String>::from_json(&json).unwrap();

    assert_eq!(restored.document_metadata().unwrap(), Some(metadata));
    assert!(restored.validate_report().is_valid());
}

#[test]
fn snapshot_validation_includes_typed_document_metadata() {
    let invalid_metadata = OfficeDocumentMetadata::new(" ", 2_000);
    let snapshot: OfficeSnapshot<String, String> =
        OfficeSnapshot::new("docs", "doc-1", 0, 2_000, "body".into())
            .try_with_document_metadata(invalid_metadata)
            .unwrap();

    let report = snapshot.validate_report();

    assert!(report.issues().iter().any(|issue| {
        issue.code == "metadata.title.empty"
            && issue.path.as_deref() == Some("metadata.office.document_metadata.title")
    }));
}

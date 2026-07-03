use crate::{ActorId, Validatable, ValidationIssue, ValidationReport};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;

pub const OFFICE_DOCUMENT_METADATA_KEY: &str = "office.document_metadata";

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeDocumentMetadata {
    pub title: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub owner_id: Option<ActorId>,
    pub created_at_ms: u64,
    pub updated_at_ms: u64,
    pub revision: u64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub version_label: Option<String>,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub properties: BTreeMap<String, Value>,
}

impl OfficeDocumentMetadata {
    pub fn new(title: impl Into<String>, timestamp_ms: u64) -> Self {
        Self {
            title: title.into(),
            owner_id: None,
            created_at_ms: timestamp_ms,
            updated_at_ms: timestamp_ms,
            revision: 0,
            version_label: None,
            properties: BTreeMap::new(),
        }
    }

    pub fn untitled(timestamp_ms: u64) -> Self {
        Self::new("Untitled", timestamp_ms)
    }

    pub fn with_owner_id(mut self, owner_id: impl Into<ActorId>) -> Self {
        self.owner_id = Some(owner_id.into());
        self
    }

    pub fn with_revision(mut self, revision: u64) -> Self {
        self.revision = revision;
        self
    }

    pub fn with_version_label(mut self, version_label: impl Into<String>) -> Self {
        self.version_label = Some(version_label.into());
        self
    }

    pub fn with_property_text(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.properties
            .insert(key.into(), Value::String(value.into()));
        self
    }

    pub fn with_property_value(mut self, key: impl Into<String>, value: Value) -> Self {
        self.properties.insert(key.into(), value);
        self
    }

    pub fn set_title(&mut self, title: impl Into<String>, timestamp_ms: u64) {
        self.title = title.into();
        self.touch(timestamp_ms);
    }

    pub fn set_owner_id(&mut self, owner_id: impl Into<ActorId>, timestamp_ms: u64) {
        self.owner_id = Some(owner_id.into());
        self.touch(timestamp_ms);
    }

    pub fn clear_owner_id(&mut self, timestamp_ms: u64) {
        self.owner_id = None;
        self.touch(timestamp_ms);
    }

    pub fn set_version_label(&mut self, version_label: impl Into<String>, timestamp_ms: u64) {
        self.version_label = Some(version_label.into());
        self.touch(timestamp_ms);
    }

    pub fn clear_version_label(&mut self, timestamp_ms: u64) {
        self.version_label = None;
        self.touch(timestamp_ms);
    }

    pub fn touch(&mut self, timestamp_ms: u64) {
        self.updated_at_ms = self.updated_at_ms.max(timestamp_ms);
    }

    pub fn advance_revision(&mut self, timestamp_ms: u64) -> u64 {
        self.revision += 1;
        self.touch(timestamp_ms);
        self.revision
    }

    pub fn to_metadata_value(&self) -> serde_json::Result<Value> {
        serde_json::to_value(self)
    }

    pub fn from_metadata_value(value: &Value) -> serde_json::Result<Self> {
        serde_json::from_value(value.clone())
    }
}

impl Validatable for OfficeDocumentMetadata {
    fn validate_report(&self) -> ValidationReport {
        let mut report = ValidationReport::new();

        if self.title.trim().is_empty() {
            report.push(
                ValidationIssue::error(
                    "metadata.title.empty",
                    "Document metadata title is required",
                )
                .with_path("title"),
            );
        }

        if let Some(owner_id) = &self.owner_id {
            if owner_id.as_str().trim().is_empty() {
                report.push(
                    ValidationIssue::error(
                        "metadata.owner.empty",
                        "Document metadata owner id cannot be empty",
                    )
                    .with_path("owner_id"),
                );
            }
        }

        if self.updated_at_ms < self.created_at_ms {
            report.push(
                ValidationIssue::error(
                    "metadata.updated_before_created",
                    "Document metadata updated timestamp cannot be older than created timestamp",
                )
                .with_path("updated_at_ms"),
            );
        }

        if let Some(version_label) = &self.version_label {
            if version_label.trim().is_empty() {
                report.push(
                    ValidationIssue::error(
                        "metadata.version_label.empty",
                        "Document metadata version label cannot be empty",
                    )
                    .with_path("version_label"),
                );
            }
        }

        for key in self.properties.keys() {
            if key.trim().is_empty() {
                report.push(
                    ValidationIssue::error(
                        "metadata.property_key.empty",
                        "Document metadata property keys cannot be empty",
                    )
                    .with_path("properties"),
                );
            }
        }

        report
    }
}

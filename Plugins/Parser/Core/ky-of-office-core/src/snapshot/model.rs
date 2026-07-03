use crate::{
    metadata::{OfficeDocumentMetadata, OFFICE_DOCUMENT_METADATA_KEY},
    DocumentId, EngineId, OfficeSelection, OperationLog, Validatable, ValidationIssue,
    ValidationReport,
};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSnapshot<State, Edit> {
    pub engine: EngineId,
    pub document_id: DocumentId,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub state: State,
    pub operation_log: OperationLog<Edit>,
    #[serde(default, skip_serializing_if = "OfficeSelection::is_none")]
    pub selection: OfficeSelection,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub metadata: BTreeMap<String, Value>,
}

impl<State, Edit> OfficeSnapshot<State, Edit> {
    pub fn new(
        engine: impl Into<EngineId>,
        document_id: impl Into<DocumentId>,
        sequence: u64,
        timestamp_ms: u64,
        state: State,
    ) -> Self {
        Self {
            engine: engine.into(),
            document_id: document_id.into(),
            sequence,
            timestamp_ms,
            state,
            operation_log: OperationLog::new(),
            selection: OfficeSelection::None,
            metadata: BTreeMap::new(),
        }
    }

    pub fn with_operation_log(mut self, operation_log: OperationLog<Edit>) -> Self {
        self.operation_log = operation_log;
        self
    }

    pub fn with_selection(mut self, selection: OfficeSelection) -> Self {
        self.selection = selection;
        self
    }

    pub fn with_metadata_text(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.metadata
            .insert(key.into(), Value::String(value.into()));
        self
    }

    pub fn with_metadata_value(mut self, key: impl Into<String>, value: Value) -> Self {
        self.metadata.insert(key.into(), value);
        self
    }

    pub fn try_with_document_metadata(
        mut self,
        metadata: OfficeDocumentMetadata,
    ) -> serde_json::Result<Self> {
        self.metadata.insert(
            OFFICE_DOCUMENT_METADATA_KEY.into(),
            metadata.to_metadata_value()?,
        );
        Ok(self)
    }

    pub fn document_metadata(&self) -> serde_json::Result<Option<OfficeDocumentMetadata>> {
        self.metadata
            .get(OFFICE_DOCUMENT_METADATA_KEY)
            .map(OfficeDocumentMetadata::from_metadata_value)
            .transpose()
    }

    pub fn map_state<NextState>(
        self,
        map: impl FnOnce(State) -> NextState,
    ) -> OfficeSnapshot<NextState, Edit> {
        OfficeSnapshot {
            engine: self.engine,
            document_id: self.document_id,
            sequence: self.sequence,
            timestamp_ms: self.timestamp_ms,
            state: map(self.state),
            operation_log: self.operation_log,
            selection: self.selection,
            metadata: self.metadata,
        }
    }
}

impl<State, Edit> OfficeSnapshot<State, Edit>
where
    State: Serialize,
    Edit: Serialize,
{
    pub fn to_json(&self) -> serde_json::Result<String> {
        serde_json::to_string(self)
    }
}

impl<State, Edit> Validatable for OfficeSnapshot<State, Edit> {
    fn validate_report(&self) -> ValidationReport {
        let mut report = ValidationReport::new();

        if self.engine.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error("snapshot.engine.empty", "Snapshot engine id is required")
                    .with_path("engine"),
            );
        }

        if self.document_id.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error(
                    "snapshot.document.empty",
                    "Snapshot document id is required",
                )
                .with_path("document_id"),
            );
        }

        report.extend_with_prefix(self.operation_log.validate_report(), "operation_log");

        if let Some(value) = self.metadata.get(OFFICE_DOCUMENT_METADATA_KEY) {
            match OfficeDocumentMetadata::from_metadata_value(value) {
                Ok(metadata) => report.extend_with_prefix(
                    metadata.validate_report(),
                    format!("metadata.{OFFICE_DOCUMENT_METADATA_KEY}"),
                ),
                Err(error) => report.push(
                    ValidationIssue::error(
                        "snapshot.metadata.document_metadata.invalid",
                        format!("Snapshot document metadata is invalid: {error}"),
                    )
                    .with_path(&format!("metadata.{OFFICE_DOCUMENT_METADATA_KEY}")),
                ),
            }
        }

        for (index, operation) in self.operation_log.operations.iter().enumerate() {
            let path = format!("operation_log.operations[{index}]");
            if operation.engine != self.engine {
                report.push(
                    ValidationIssue::error(
                        "snapshot.operation.engine_mismatch",
                        format!(
                            "Snapshot operation engine '{}' does not match snapshot engine '{}'",
                            operation.engine, self.engine
                        ),
                    )
                    .with_path(&path),
                );
            }

            if operation.document_id != self.document_id {
                report.push(
                    ValidationIssue::error(
                        "snapshot.operation.document_mismatch",
                        format!(
                            "Snapshot operation document '{}' does not match snapshot document '{}'",
                            operation.document_id, self.document_id
                        ),
                    )
                    .with_path(&path),
                );
            }

            if operation.sequence > self.sequence {
                report.push(
                    ValidationIssue::error(
                        "snapshot.operation.sequence_after_snapshot",
                        format!(
                            "Snapshot operation sequence {} is newer than snapshot sequence {}",
                            operation.sequence, self.sequence
                        ),
                    )
                    .with_path(&path),
                );
            }
        }

        report
    }
}

impl<State, Edit> OfficeSnapshot<State, Edit>
where
    State: DeserializeOwned,
    Edit: DeserializeOwned,
{
    pub fn from_json(json: &str) -> serde_json::Result<Self> {
        serde_json::from_str(json)
    }
}

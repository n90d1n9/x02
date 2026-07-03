use crate::{
    ActorId, DocumentId, EngineId, OperationId, Validatable, ValidationIssue, ValidationReport,
};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OperationEnvelope<T> {
    pub engine: EngineId,
    pub operation_id: OperationId,
    pub document_id: DocumentId,
    pub actor_id: ActorId,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub edit: T,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub metadata: BTreeMap<String, Value>,
}

impl<T> OperationEnvelope<T> {
    pub fn new(
        engine: impl Into<EngineId>,
        operation_id: impl Into<OperationId>,
        document_id: impl Into<DocumentId>,
        actor_id: impl Into<ActorId>,
        sequence: u64,
        timestamp_ms: u64,
        edit: T,
    ) -> Self {
        Self {
            engine: engine.into(),
            operation_id: operation_id.into(),
            document_id: document_id.into(),
            actor_id: actor_id.into(),
            sequence,
            timestamp_ms,
            edit,
            metadata: BTreeMap::new(),
        }
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
}

impl<T> OperationEnvelope<T>
where
    T: Serialize,
{
    pub fn to_json(&self) -> serde_json::Result<String> {
        serde_json::to_string(self)
    }
}

impl<T> Validatable for OperationEnvelope<T> {
    fn validate_report(&self) -> ValidationReport {
        let mut report = ValidationReport::new();

        if self.engine.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error("operation.engine.empty", "Operation engine id is required")
                    .with_path("engine"),
            );
        }

        if self.operation_id.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error("operation.id.empty", "Operation id is required")
                    .with_path("operation_id"),
            );
        }

        if self.document_id.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error(
                    "operation.document.empty",
                    "Operation document id is required",
                )
                .with_path("document_id"),
            );
        }

        if self.actor_id.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error("operation.actor.empty", "Operation actor id is required")
                    .with_path("actor_id"),
            );
        }

        report
    }
}

impl<T> OperationEnvelope<T>
where
    T: DeserializeOwned,
{
    pub fn from_json(json: &str) -> serde_json::Result<Self> {
        serde_json::from_str(json)
    }
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct OperationLog<T> {
    pub operations: Vec<OperationEnvelope<T>>,
}

impl<T> OperationLog<T> {
    pub fn new() -> Self {
        Self {
            operations: Vec::new(),
        }
    }

    pub fn from_operations(operations: Vec<OperationEnvelope<T>>) -> Self {
        Self { operations }
    }

    pub fn push(&mut self, operation: OperationEnvelope<T>) {
        self.operations.push(operation);
    }

    pub fn len(&self) -> usize {
        self.operations.len()
    }

    pub fn is_empty(&self) -> bool {
        self.operations.is_empty()
    }
}

impl<T> OperationLog<T>
where
    T: Serialize,
{
    pub fn to_json(&self) -> serde_json::Result<String> {
        serde_json::to_string(self)
    }
}

impl<T> Validatable for OperationLog<T> {
    fn validate_report(&self) -> ValidationReport {
        let mut report = ValidationReport::new();

        for (index, operation) in self.operations.iter().enumerate() {
            report.extend_with_prefix(operation.validate_report(), format!("operations[{index}]"));
        }

        report
    }
}

impl<T> OperationLog<T>
where
    T: DeserializeOwned,
{
    pub fn from_json(json: &str) -> serde_json::Result<Self> {
        serde_json::from_str(json)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
    enum TestEdit {
        Rename { title: String },
    }

    fn edit() -> TestEdit {
        TestEdit::Rename {
            title: "Quarterly plan".into(),
        }
    }

    #[test]
    fn envelope_roundtrips_with_metadata() {
        let operation = OperationEnvelope::new("docs", "op-1", "doc-1", "actor-1", 7, 42, edit())
            .with_metadata_text("source", "unit-test")
            .with_metadata_value("retry", Value::Bool(false));

        let json = operation.to_json().unwrap();
        let restored = OperationEnvelope::<TestEdit>::from_json(&json).unwrap();

        assert_eq!(restored.engine, "docs");
        assert_eq!(restored.sequence, 7);
        assert_eq!(
            restored.metadata.get("source"),
            Some(&Value::String("unit-test".into()))
        );
        assert_eq!(restored.metadata.get("retry"), Some(&Value::Bool(false)));
        assert_eq!(restored.edit, edit());
    }

    #[test]
    fn operation_log_keeps_order_and_roundtrips() {
        let mut log = OperationLog::new();
        log.push(OperationEnvelope::new(
            "sheet",
            "op-1",
            "sheet-1",
            "actor-1",
            1,
            100,
            edit(),
        ));
        log.push(OperationEnvelope::new(
            "sheet",
            "op-2",
            "sheet-1",
            "actor-1",
            2,
            101,
            edit(),
        ));

        let json = log.to_json().unwrap();
        let restored = OperationLog::<TestEdit>::from_json(&json).unwrap();

        assert_eq!(restored.len(), 2);
        assert_eq!(restored.operations[0].operation_id, "op-1");
        assert_eq!(restored.operations[1].operation_id, "op-2");
    }
}

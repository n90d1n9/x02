use super::builder::OperationTransactionBuilder;
use super::validation::{validate_operation_stream, TransactionError};
use crate::{
    OperationEnvelope, OperationLog, TransactionId, Validatable, ValidationIssue, ValidationReport,
};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OperationTransaction<T> {
    pub transaction_id: TransactionId,
    pub operations: Vec<OperationEnvelope<T>>,
    pub inverse_operations: Vec<OperationEnvelope<T>>,
    pub metadata: BTreeMap<String, Value>,
}

impl<T> OperationTransaction<T> {
    pub fn builder(transaction_id: impl Into<TransactionId>) -> OperationTransactionBuilder<T> {
        OperationTransactionBuilder::new(transaction_id)
    }

    pub fn new(transaction_id: impl Into<TransactionId>) -> Self {
        Self {
            transaction_id: transaction_id.into(),
            operations: Vec::new(),
            inverse_operations: Vec::new(),
            metadata: BTreeMap::new(),
        }
    }

    pub fn from_operations(
        transaction_id: impl Into<TransactionId>,
        operations: Vec<OperationEnvelope<T>>,
    ) -> Self {
        Self {
            transaction_id: transaction_id.into(),
            operations,
            inverse_operations: Vec::new(),
            metadata: BTreeMap::new(),
        }
    }

    pub fn with_operation(mut self, operation: OperationEnvelope<T>) -> Self {
        self.operations.push(operation);
        self
    }

    pub fn with_inverse_operation(mut self, operation: OperationEnvelope<T>) -> Self {
        self.inverse_operations.push(operation);
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

    pub fn push_operation(&mut self, operation: OperationEnvelope<T>) {
        self.operations.push(operation);
    }

    pub fn push_inverse_operation(&mut self, operation: OperationEnvelope<T>) {
        self.inverse_operations.push(operation);
    }

    pub fn operations(&self) -> &[OperationEnvelope<T>] {
        &self.operations
    }

    pub fn inverse_operations(&self) -> &[OperationEnvelope<T>] {
        &self.inverse_operations
    }

    pub fn len(&self) -> usize {
        self.operations.len()
    }

    pub fn is_empty(&self) -> bool {
        self.operations.is_empty()
    }

    pub fn validate(&self) -> Result<(), TransactionError> {
        validate_operation_stream(&self.transaction_id, &self.operations)
    }

    pub fn validate_undoable(&self) -> Result<(), TransactionError> {
        self.validate()?;

        if self.inverse_operations.is_empty() {
            return Err(TransactionError::MissingInverseOperations {
                transaction_id: self.transaction_id.clone(),
            });
        }

        validate_operation_stream(&self.transaction_id, &self.inverse_operations)?;

        let forward = self
            .operations
            .first()
            .expect("validated transaction has at least one operation");
        for inverse in &self.inverse_operations {
            if inverse.engine != forward.engine {
                return Err(TransactionError::MismatchedEngine {
                    transaction_id: self.transaction_id.clone(),
                    expected: forward.engine.clone(),
                    actual: inverse.engine.clone(),
                });
            }

            if inverse.document_id != forward.document_id {
                return Err(TransactionError::MismatchedDocument {
                    transaction_id: self.transaction_id.clone(),
                    expected: forward.document_id.clone(),
                    actual: inverse.document_id.clone(),
                });
            }

            if inverse.actor_id != forward.actor_id {
                return Err(TransactionError::MismatchedActor {
                    transaction_id: self.transaction_id.clone(),
                    expected: forward.actor_id.clone(),
                    actual: inverse.actor_id.clone(),
                });
            }
        }

        Ok(())
    }

    pub fn undo_operations(&self) -> Result<Vec<OperationEnvelope<T>>, TransactionError>
    where
        T: Clone,
    {
        if self.inverse_operations.is_empty() {
            return Err(TransactionError::MissingInverseOperations {
                transaction_id: self.transaction_id.clone(),
            });
        }

        Ok(self.inverse_operations.clone())
    }

    pub fn operation_log(&self) -> OperationLog<T>
    where
        T: Clone,
    {
        OperationLog::from_operations(self.operations.clone())
    }
}

impl<T> OperationTransaction<T>
where
    T: Serialize,
{
    pub fn to_json(&self) -> serde_json::Result<String> {
        serde_json::to_string(self)
    }
}

impl<T> Validatable for OperationTransaction<T> {
    fn validate_report(&self) -> ValidationReport {
        let mut report = ValidationReport::new();

        if self.transaction_id.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error("transaction.id.empty", "Transaction id is required")
                    .with_path("transaction_id"),
            );
        }

        for (index, operation) in self.operations.iter().enumerate() {
            report.extend_with_prefix(operation.validate_report(), format!("operations[{index}]"));
        }

        for (index, operation) in self.inverse_operations.iter().enumerate() {
            report.extend_with_prefix(
                operation.validate_report(),
                format!("inverse_operations[{index}]"),
            );
        }

        if let Err(error) = self.validate() {
            report.push(transaction_error_issue(error));
        }

        report
    }
}

fn transaction_error_issue(error: TransactionError) -> ValidationIssue {
    match error {
        TransactionError::EmptyTransaction { .. } => ValidationIssue::error(
            "transaction.operations.empty",
            "Transaction must contain at least one operation",
        )
        .with_path("operations"),
        TransactionError::MismatchedEngine {
            expected, actual, ..
        } => ValidationIssue::error(
            "transaction.operations.engine_mismatch",
            format!("Operation engine '{actual}' does not match expected engine '{expected}'"),
        )
        .with_path("operations"),
        TransactionError::MismatchedDocument {
            expected, actual, ..
        } => ValidationIssue::error(
            "transaction.operations.document_mismatch",
            format!("Operation document '{actual}' does not match expected document '{expected}'"),
        )
        .with_path("operations"),
        TransactionError::MismatchedActor {
            expected, actual, ..
        } => ValidationIssue::error(
            "transaction.operations.actor_mismatch",
            format!("Operation actor '{actual}' does not match expected actor '{expected}'"),
        )
        .with_path("operations"),
        TransactionError::NonIncreasingSequence { previous, next, .. } => ValidationIssue::error(
            "transaction.operations.sequence_not_increasing",
            format!("Operation sequence {next} must be greater than previous sequence {previous}"),
        )
        .with_path("operations"),
        TransactionError::MissingInverseOperations { .. } => ValidationIssue::error(
            "transaction.inverse_operations.empty",
            "Transaction does not contain inverse operations",
        )
        .with_path("inverse_operations"),
    }
}

impl<T> OperationTransaction<T>
where
    T: DeserializeOwned,
{
    pub fn from_json(json: &str) -> serde_json::Result<Self> {
        serde_json::from_str(json)
    }
}

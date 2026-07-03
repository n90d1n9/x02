use super::model::OperationTransaction;
use super::validation::TransactionError;
use crate::{OperationEnvelope, TransactionId};
use serde_json::Value;

#[derive(Debug, Clone, PartialEq)]
pub struct OperationTransactionBuilder<T> {
    transaction: OperationTransaction<T>,
}

impl<T> OperationTransactionBuilder<T> {
    pub fn new(transaction_id: impl Into<TransactionId>) -> Self {
        Self {
            transaction: OperationTransaction::new(transaction_id),
        }
    }

    pub fn operation(mut self, operation: OperationEnvelope<T>) -> Self {
        self.transaction.push_operation(operation);
        self
    }

    pub fn inverse_operation(mut self, operation: OperationEnvelope<T>) -> Self {
        self.transaction.push_inverse_operation(operation);
        self
    }

    pub fn operation_pair(
        mut self,
        operation: OperationEnvelope<T>,
        inverse_operation: OperationEnvelope<T>,
    ) -> Self {
        self.transaction.push_operation(operation);
        self.transaction.push_inverse_operation(inverse_operation);
        self
    }

    pub fn metadata_text(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.transaction
            .metadata
            .insert(key.into(), Value::String(value.into()));
        self
    }

    pub fn metadata_value(mut self, key: impl Into<String>, value: Value) -> Self {
        self.transaction.metadata.insert(key.into(), value);
        self
    }

    pub fn build(self) -> OperationTransaction<T> {
        self.transaction
    }

    pub fn build_validated(self) -> Result<OperationTransaction<T>, TransactionError> {
        self.transaction.validate()?;
        Ok(self.transaction)
    }

    pub fn build_undoable(self) -> Result<OperationTransaction<T>, TransactionError> {
        self.transaction.validate_undoable()?;
        Ok(self.transaction)
    }
}

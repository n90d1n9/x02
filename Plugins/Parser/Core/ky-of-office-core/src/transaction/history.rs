use super::model::OperationTransaction;
use super::validation::TransactionError;
use crate::{OperationEnvelope, OperationLog};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TransactionHistory<T> {
    committed: Vec<OperationTransaction<T>>,
    undone: Vec<OperationTransaction<T>>,
    max_depth: usize,
}

impl<T> TransactionHistory<T> {
    pub fn new() -> Self {
        Self {
            committed: Vec::new(),
            undone: Vec::new(),
            max_depth: 0,
        }
    }

    pub fn with_max_depth(max_depth: usize) -> Self {
        Self {
            max_depth,
            ..Self::new()
        }
    }

    pub fn commit(&mut self, transaction: OperationTransaction<T>) -> Result<(), TransactionError> {
        transaction.validate()?;
        self.committed.push(transaction);
        self.undone.clear();
        self.enforce_max_depth();
        Ok(())
    }

    pub fn can_undo(&self) -> bool {
        !self.committed.is_empty()
    }

    pub fn can_redo(&self) -> bool {
        !self.undone.is_empty()
    }

    pub fn committed_len(&self) -> usize {
        self.committed.len()
    }

    pub fn undone_len(&self) -> usize {
        self.undone.len()
    }

    pub fn committed(&self) -> &[OperationTransaction<T>] {
        &self.committed
    }

    pub fn undone(&self) -> &[OperationTransaction<T>] {
        &self.undone
    }

    pub fn operation_log(&self) -> OperationLog<T>
    where
        T: Clone,
    {
        let operations = self
            .committed
            .iter()
            .flat_map(|transaction| transaction.operations.iter().cloned())
            .collect();

        OperationLog::from_operations(operations)
    }

    pub fn undo(&mut self) -> Option<OperationTransaction<T>>
    where
        T: Clone,
    {
        let transaction = self.committed.pop()?;
        self.undone.push(transaction.clone());
        Some(transaction)
    }

    pub fn redo(&mut self) -> Option<OperationTransaction<T>>
    where
        T: Clone,
    {
        let transaction = self.undone.pop()?;
        self.committed.push(transaction.clone());
        Some(transaction)
    }

    pub fn undo_operations(&mut self) -> Result<Vec<OperationEnvelope<T>>, TransactionError>
    where
        T: Clone,
    {
        let Some(transaction) = self.committed.last() else {
            return Ok(Vec::new());
        };
        let operations = transaction.undo_operations()?;

        let transaction = self.committed.pop().expect("transaction was checked above");
        self.undone.push(transaction);
        Ok(operations)
    }

    pub fn redo_operations(&mut self) -> Vec<OperationEnvelope<T>>
    where
        T: Clone,
    {
        let Some(transaction) = self.undone.pop() else {
            return Vec::new();
        };
        let operations = transaction.operations.clone();
        self.committed.push(transaction);
        operations
    }

    fn enforce_max_depth(&mut self) {
        if self.max_depth == 0 || self.committed.len() <= self.max_depth {
            return;
        }

        let drop_count = self.committed.len() - self.max_depth;
        self.committed.drain(0..drop_count);
    }
}

impl<T> Default for TransactionHistory<T> {
    fn default() -> Self {
        Self::new()
    }
}

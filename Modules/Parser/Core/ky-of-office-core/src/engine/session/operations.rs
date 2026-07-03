//! Operation application, transaction replay, history navigation, and validation.

use super::super::{
    history::{issue_redo_operations, issue_undo_operations},
    OfficeSessionError, OfficeSessionEventKind,
};
use super::OfficeDocumentSession;
use crate::{
    validate_incoming_batch, OfficeOperationBatch, OperationApplier, OperationEnvelope,
    OperationTransaction, Validatable, ValidationIssue, ValidationReport,
};

impl<State, Edit> OfficeDocumentSession<State, Edit>
where
    State: OperationApplier<Edit>,
    Edit: Clone,
{
    pub fn apply_operation(
        &mut self,
        operation: OperationEnvelope<Edit>,
    ) -> Result<State::Outcome, OfficeSessionError<State::Error>> {
        self.validate_operation_for_session(&operation)
            .require_valid()
            .map_err(OfficeSessionError::validation)?;

        let outcome = self
            .state
            .apply_operation(operation.clone())
            .map_err(OfficeSessionError::apply)?;
        self.record_operation(operation);
        Ok(outcome)
    }

    pub fn apply_transaction(
        &mut self,
        transaction: OperationTransaction<Edit>,
    ) -> Result<Vec<State::Outcome>, OfficeSessionError<State::Error>> {
        transaction
            .validate()
            .map_err(OfficeSessionError::transaction)?;
        self.validate_transaction_for_session(&transaction)
            .require_valid()
            .map_err(OfficeSessionError::validation)?;

        let mut outcomes = Vec::with_capacity(transaction.len());
        for operation in transaction.operations().iter().cloned() {
            let outcome = self
                .state
                .apply_operation(operation.clone())
                .map_err(OfficeSessionError::apply)?;
            self.record_operation(operation);
            outcomes.push(outcome);
        }

        let transaction_id = transaction.transaction_id.clone();
        let operation_count = transaction.len();
        self.history
            .commit(transaction)
            .map_err(OfficeSessionError::transaction)?;
        self.record_event(
            OfficeSessionEventKind::TransactionCommitted {
                transaction_id,
                operation_count,
            },
            self.last_timestamp_ms,
        );
        Ok(outcomes)
    }

    pub fn apply_remote_batch(
        &mut self,
        batch: OfficeOperationBatch<Edit>,
    ) -> Result<Vec<State::Outcome>, OfficeSessionError<State::Error>> {
        validate_incoming_batch(&self.sync_cursor(), &batch).map_err(OfficeSessionError::sync)?;

        let base_sequence = batch.base.sequence;
        let target_sequence = batch.target.sequence;
        let operation_count = batch.len();
        if operation_count == 0 {
            return Ok(Vec::new());
        }

        let outcomes = self.apply_recorded_operations(batch.operations)?;
        self.record_event(
            OfficeSessionEventKind::RemoteBatchApplied {
                base_sequence,
                target_sequence,
                operation_count,
            },
            self.last_timestamp_ms,
        );
        Ok(outcomes)
    }

    pub fn undo(
        &mut self,
        timestamp_ms: u64,
    ) -> Result<Vec<State::Outcome>, OfficeSessionError<State::Error>> {
        let (transaction_id, operations) = {
            let Some(transaction) = self.history.committed().last() else {
                return Ok(Vec::new());
            };
            let operations = issue_undo_operations(transaction, self.sequence, timestamp_ms)
                .map_err(OfficeSessionError::transaction)?;
            (transaction.transaction_id.clone(), operations)
        };
        let operation_count = operations.len();

        let outcomes = self.apply_recorded_operations(operations)?;
        self.history.undo();
        self.record_event(
            OfficeSessionEventKind::UndoApplied {
                transaction_id,
                operation_count,
            },
            timestamp_ms,
        );
        Ok(outcomes)
    }

    pub fn redo(
        &mut self,
        timestamp_ms: u64,
    ) -> Result<Vec<State::Outcome>, OfficeSessionError<State::Error>> {
        let (transaction_id, operations) = {
            let Some(transaction) = self.history.undone().last() else {
                return Ok(Vec::new());
            };
            (
                transaction.transaction_id.clone(),
                issue_redo_operations(transaction, self.sequence, timestamp_ms),
            )
        };
        let operation_count = operations.len();

        let outcomes = self.apply_recorded_operations(operations)?;
        self.history.redo();
        self.record_event(
            OfficeSessionEventKind::RedoApplied {
                transaction_id,
                operation_count,
            },
            timestamp_ms,
        );
        Ok(outcomes)
    }

    fn record_operation(&mut self, operation: OperationEnvelope<Edit>) {
        let operation_id = operation.operation_id.clone();
        let timestamp_ms = operation.timestamp_ms;
        self.sequence = self.sequence.max(operation.sequence);
        self.last_timestamp_ms = self.last_timestamp_ms.max(operation.timestamp_ms);
        self.operation_log.push(operation);
        self.record_event(
            OfficeSessionEventKind::OperationApplied { operation_id },
            timestamp_ms,
        );
    }

    fn apply_recorded_operations(
        &mut self,
        operations: Vec<OperationEnvelope<Edit>>,
    ) -> Result<Vec<State::Outcome>, OfficeSessionError<State::Error>> {
        self.validate_operations_for_session(&operations)
            .require_valid()
            .map_err(OfficeSessionError::validation)?;

        let mut outcomes = Vec::with_capacity(operations.len());
        for operation in operations {
            let outcome = self
                .state
                .apply_operation(operation.clone())
                .map_err(OfficeSessionError::apply)?;
            self.record_operation(operation);
            outcomes.push(outcome);
        }

        Ok(outcomes)
    }

    fn validate_transaction_for_session(
        &self,
        transaction: &OperationTransaction<Edit>,
    ) -> ValidationReport {
        let mut report = transaction.validate_report();
        for (index, operation) in transaction.operations().iter().enumerate() {
            report.extend_with_prefix(
                self.validate_operation_for_session(operation),
                format!("operations[{index}]"),
            );
        }
        report
    }

    fn validate_operations_for_session(
        &self,
        operations: &[OperationEnvelope<Edit>],
    ) -> ValidationReport {
        let mut report = ValidationReport::new();
        for (index, operation) in operations.iter().enumerate() {
            report.extend_with_prefix(
                self.validate_operation_for_session(operation),
                format!("operations[{index}]"),
            );
        }
        report
    }

    fn validate_operation_for_session(
        &self,
        operation: &OperationEnvelope<Edit>,
    ) -> ValidationReport {
        let mut report = operation.validate_report();

        if operation.engine != self.engine {
            report.push(
                ValidationIssue::error(
                    "session.operation.engine_mismatch",
                    format!(
                        "Operation engine '{}' does not match session engine '{}'",
                        operation.engine, self.engine
                    ),
                )
                .with_path("engine"),
            );
        }

        if operation.document_id != self.document_id {
            report.push(
                ValidationIssue::error(
                    "session.operation.document_mismatch",
                    format!(
                        "Operation document '{}' does not match session document '{}'",
                        operation.document_id, self.document_id
                    ),
                )
                .with_path("document_id"),
            );
        }

        if operation.sequence <= self.sequence {
            report.push(
                ValidationIssue::error(
                    "session.operation.sequence_not_newer",
                    format!(
                        "Operation sequence {} must be newer than session sequence {}",
                        operation.sequence, self.sequence
                    ),
                )
                .with_path("sequence"),
            );
        }

        report
    }
}

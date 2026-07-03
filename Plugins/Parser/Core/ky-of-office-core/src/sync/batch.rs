use super::{OfficeSyncCursor, OfficeSyncError};
use crate::{OperationEnvelope, OperationLog};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeOperationBatch<Edit> {
    pub base: OfficeSyncCursor,
    pub target: OfficeSyncCursor,
    pub operations: Vec<OperationEnvelope<Edit>>,
}

impl<Edit> OfficeOperationBatch<Edit> {
    pub fn new(
        base: OfficeSyncCursor,
        target: OfficeSyncCursor,
        operations: Vec<OperationEnvelope<Edit>>,
    ) -> Self {
        Self {
            base,
            target,
            operations,
        }
    }

    pub fn len(&self) -> usize {
        self.operations.len()
    }

    pub fn is_empty(&self) -> bool {
        self.operations.is_empty()
    }

    pub fn validate(&self) -> Result<(), OfficeSyncError> {
        validate_cursor_pair(&self.base, &self.target)?;

        let mut previous_sequence = self.base.sequence;
        for operation in &self.operations {
            validate_operation_identity(&self.base, operation)?;

            if operation.sequence <= self.base.sequence {
                return Err(OfficeSyncError::OperationSequenceNotAfterCursor {
                    cursor_sequence: self.base.sequence,
                    operation_sequence: operation.sequence,
                });
            }

            if operation.sequence <= previous_sequence {
                return Err(OfficeSyncError::NonIncreasingSequence {
                    previous: previous_sequence,
                    next: operation.sequence,
                });
            }

            previous_sequence = operation.sequence;
        }

        let expected_target = self
            .operations
            .last()
            .map(|operation| operation.sequence)
            .unwrap_or(self.base.sequence);
        if self.target.sequence != expected_target {
            return Err(OfficeSyncError::TargetSequenceMismatch {
                expected: expected_target,
                actual: self.target.sequence,
            });
        }

        Ok(())
    }
}

impl<Edit> OfficeOperationBatch<Edit>
where
    Edit: Clone,
{
    pub fn from_log_after(
        cursor: OfficeSyncCursor,
        operation_log: &OperationLog<Edit>,
    ) -> Result<Self, OfficeSyncError> {
        validate_log_identity_and_order(&cursor, operation_log)?;

        let operations = operation_log
            .operations
            .iter()
            .filter(|operation| operation.sequence > cursor.sequence)
            .cloned()
            .collect::<Vec<_>>();
        let target_sequence = operations
            .last()
            .map(|operation| operation.sequence)
            .unwrap_or(cursor.sequence);
        let target = cursor.advance_to(target_sequence);
        let batch = Self::new(cursor, target, operations);
        batch.validate()?;
        Ok(batch)
    }

    pub fn operation_log(&self) -> OperationLog<Edit> {
        OperationLog::from_operations(self.operations.clone())
    }
}

pub fn collect_operations_after<Edit>(
    cursor: OfficeSyncCursor,
    operation_log: &OperationLog<Edit>,
) -> Result<OfficeOperationBatch<Edit>, OfficeSyncError>
where
    Edit: Clone,
{
    OfficeOperationBatch::from_log_after(cursor, operation_log)
}

pub fn validate_incoming_batch<Edit>(
    current: &OfficeSyncCursor,
    batch: &OfficeOperationBatch<Edit>,
) -> Result<(), OfficeSyncError> {
    if &batch.base != current {
        return Err(OfficeSyncError::BatchBaseMismatch {
            expected: current.clone(),
            actual: batch.base.clone(),
        });
    }

    batch.validate()
}

fn validate_cursor_pair(
    base: &OfficeSyncCursor,
    target: &OfficeSyncCursor,
) -> Result<(), OfficeSyncError> {
    if target.engine != base.engine {
        return Err(OfficeSyncError::CursorEngineMismatch {
            expected: base.engine.clone(),
            actual: target.engine.clone(),
        });
    }

    if target.document_id != base.document_id {
        return Err(OfficeSyncError::CursorDocumentMismatch {
            expected: base.document_id.clone(),
            actual: target.document_id.clone(),
        });
    }

    if target.sequence < base.sequence {
        return Err(OfficeSyncError::TargetSequenceBehindBase {
            base_sequence: base.sequence,
            target_sequence: target.sequence,
        });
    }

    Ok(())
}

fn validate_log_identity_and_order<Edit>(
    cursor: &OfficeSyncCursor,
    operation_log: &OperationLog<Edit>,
) -> Result<(), OfficeSyncError> {
    let mut previous_sequence = None;

    for operation in &operation_log.operations {
        validate_operation_identity(cursor, operation)?;

        if let Some(previous) = previous_sequence {
            if operation.sequence <= previous {
                return Err(OfficeSyncError::NonIncreasingSequence {
                    previous,
                    next: operation.sequence,
                });
            }
        }

        previous_sequence = Some(operation.sequence);
    }

    Ok(())
}

fn validate_operation_identity<Edit>(
    cursor: &OfficeSyncCursor,
    operation: &OperationEnvelope<Edit>,
) -> Result<(), OfficeSyncError> {
    if operation.engine != cursor.engine {
        return Err(OfficeSyncError::OperationEngineMismatch {
            sequence: operation.sequence,
            expected: cursor.engine.clone(),
            actual: operation.engine.clone(),
        });
    }

    if operation.document_id != cursor.document_id {
        return Err(OfficeSyncError::OperationDocumentMismatch {
            sequence: operation.sequence,
            expected: cursor.document_id.clone(),
            actual: operation.document_id.clone(),
        });
    }

    Ok(())
}

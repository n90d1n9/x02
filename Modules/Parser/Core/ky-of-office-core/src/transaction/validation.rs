use crate::{ActorId, DocumentId, EngineId, OperationEnvelope, TransactionId};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum TransactionError {
    EmptyTransaction {
        transaction_id: TransactionId,
    },
    MismatchedEngine {
        transaction_id: TransactionId,
        expected: EngineId,
        actual: EngineId,
    },
    MismatchedDocument {
        transaction_id: TransactionId,
        expected: DocumentId,
        actual: DocumentId,
    },
    MismatchedActor {
        transaction_id: TransactionId,
        expected: ActorId,
        actual: ActorId,
    },
    NonIncreasingSequence {
        transaction_id: TransactionId,
        previous: u64,
        next: u64,
    },
    MissingInverseOperations {
        transaction_id: TransactionId,
    },
}

pub(crate) fn validate_operation_stream<T>(
    transaction_id: &TransactionId,
    operations: &[OperationEnvelope<T>],
) -> Result<(), TransactionError> {
    let Some(first) = operations.first() else {
        return Err(TransactionError::EmptyTransaction {
            transaction_id: transaction_id.clone(),
        });
    };

    let expected_engine = &first.engine;
    let expected_document = &first.document_id;
    let expected_actor = &first.actor_id;
    let mut previous_sequence = first.sequence;

    for operation in operations {
        if operation.engine != *expected_engine {
            return Err(TransactionError::MismatchedEngine {
                transaction_id: transaction_id.to_owned(),
                expected: expected_engine.clone(),
                actual: operation.engine.clone(),
            });
        }

        if operation.document_id != *expected_document {
            return Err(TransactionError::MismatchedDocument {
                transaction_id: transaction_id.to_owned(),
                expected: expected_document.clone(),
                actual: operation.document_id.clone(),
            });
        }

        if operation.actor_id != *expected_actor {
            return Err(TransactionError::MismatchedActor {
                transaction_id: transaction_id.to_owned(),
                expected: expected_actor.clone(),
                actual: operation.actor_id.clone(),
            });
        }
    }

    for operation in operations.iter().skip(1) {
        if operation.sequence <= previous_sequence {
            return Err(TransactionError::NonIncreasingSequence {
                transaction_id: transaction_id.to_owned(),
                previous: previous_sequence,
                next: operation.sequence,
            });
        }
        previous_sequence = operation.sequence;
    }

    Ok(())
}

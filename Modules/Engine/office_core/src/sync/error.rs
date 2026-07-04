use super::OfficeSyncCursor;
use crate::{DocumentId, EngineId};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeSyncError {
    BatchBaseMismatch {
        expected: OfficeSyncCursor,
        actual: OfficeSyncCursor,
    },
    CursorEngineMismatch {
        expected: EngineId,
        actual: EngineId,
    },
    CursorDocumentMismatch {
        expected: DocumentId,
        actual: DocumentId,
    },
    TargetSequenceBehindBase {
        base_sequence: u64,
        target_sequence: u64,
    },
    OperationLogCompacted {
        requested_sequence: u64,
        available_after_sequence: u64,
    },
    OperationEngineMismatch {
        sequence: u64,
        expected: EngineId,
        actual: EngineId,
    },
    OperationDocumentMismatch {
        sequence: u64,
        expected: DocumentId,
        actual: DocumentId,
    },
    OperationSequenceNotAfterCursor {
        cursor_sequence: u64,
        operation_sequence: u64,
    },
    NonIncreasingSequence {
        previous: u64,
        next: u64,
    },
    TargetSequenceMismatch {
        expected: u64,
        actual: u64,
    },
}

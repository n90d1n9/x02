//! Sync cursor access and operation-delta retrieval for document sessions.

use super::OfficeDocumentSession;
use crate::{collect_operations_after, OfficeOperationBatch, OfficeSyncCursor, OfficeSyncError};

impl<State, Edit> OfficeDocumentSession<State, Edit> {
    pub fn sync_cursor(&self) -> OfficeSyncCursor {
        OfficeSyncCursor::new(self.engine.clone(), self.document_id.clone(), self.sequence)
    }

    pub fn operations_after(
        &self,
        cursor: OfficeSyncCursor,
    ) -> Result<OfficeOperationBatch<Edit>, OfficeSyncError>
    where
        Edit: Clone,
    {
        self.validate_cursor_for_session(&cursor)?;
        collect_operations_after(cursor, &self.operation_log)
    }

    fn validate_cursor_for_session(
        &self,
        cursor: &OfficeSyncCursor,
    ) -> Result<(), OfficeSyncError> {
        if cursor.engine != self.engine {
            return Err(OfficeSyncError::CursorEngineMismatch {
                expected: self.engine.clone(),
                actual: cursor.engine.clone(),
            });
        }

        if cursor.document_id != self.document_id {
            return Err(OfficeSyncError::CursorDocumentMismatch {
                expected: self.document_id.clone(),
                actual: cursor.document_id.clone(),
            });
        }

        if cursor.sequence > self.sequence {
            return Err(OfficeSyncError::TargetSequenceBehindBase {
                base_sequence: cursor.sequence,
                target_sequence: self.sequence,
            });
        }

        if cursor.sequence < self.operation_log_pruned_through_sequence {
            return Err(OfficeSyncError::OperationLogCompacted {
                requested_sequence: cursor.sequence,
                available_after_sequence: self.operation_log_pruned_through_sequence,
            });
        }

        Ok(())
    }
}

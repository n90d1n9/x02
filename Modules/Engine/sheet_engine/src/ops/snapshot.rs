//! Builders for typed sheet operation envelopes and snapshots.

use crate::{
    SheetEdit, SheetGrid, SheetOperation, SheetOperationLog, SheetSnapshot, SHEET_ENGINE_ID,
};
use waraq_core::{ActorId, DocumentId, OfficeSnapshot, OperationEnvelope, OperationId};

/// Create a sheet operation envelope with the stable sheet engine id.
pub fn sheet_operation(
    operation_id: impl Into<OperationId>,
    document_id: impl Into<DocumentId>,
    actor_id: impl Into<ActorId>,
    sequence: u64,
    timestamp_ms: u64,
    edit: SheetEdit,
) -> SheetOperation {
    OperationEnvelope::new(
        SHEET_ENGINE_ID,
        operation_id,
        document_id,
        actor_id,
        sequence,
        timestamp_ms,
        edit,
    )
}

/// Create a sheet snapshot with the stable sheet engine id and operation log.
pub fn sheet_snapshot(
    document_id: impl Into<DocumentId>,
    sequence: u64,
    timestamp_ms: u64,
    grid: SheetGrid,
    operation_log: SheetOperationLog,
) -> SheetSnapshot {
    OfficeSnapshot::new(SHEET_ENGINE_ID, document_id, sequence, timestamp_ms, grid)
        .with_operation_log(operation_log)
}

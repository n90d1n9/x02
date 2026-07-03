/// Re-exports command request, state, and tracked command-result APIs.
pub mod commands {
    pub use crate::{
        OfficeSessionCommand, OfficeSessionCommandDelta, OfficeSessionCommandExecutionError,
        OfficeSessionCommandRequest, OfficeSessionCommandResult, OfficeSessionCommandState,
        OfficeSessionTrackedCommandError, OfficeSessionTrackedCommandResult,
    };
}

/// Re-exports session lifecycle and document checkpoint APIs.
pub mod document {
    pub use crate::{
        OfficeDocumentMetadata, OfficeDocumentSession, OfficeSessionCheckpoint, OfficeSessionError,
        OfficeSessionLogPruneReport, OfficeSnapshot, OFFICE_DOCUMENT_METADATA_KEY,
    };
}

/// Re-exports session event polling, filtering, and retention APIs.
pub mod events {
    pub use crate::{
        OfficeSessionEvent, OfficeSessionEventBatch, OfficeSessionEventCategory,
        OfficeSessionEventCursor, OfficeSessionEventError, OfficeSessionEventFilter,
        OfficeSessionEventKind, OfficeSessionEventObserver, OfficeSessionEventObserverUpdate,
        OfficeSessionEventPruneReport, OfficeSessionEventRetentionPolicy,
    };
}

/// Re-exports persistence stores and save/restore receipt APIs.
pub mod persistence {
    pub use crate::{
        InMemoryOfficeStore, OfficeDocumentPersistMode, OfficeDocumentPersistReceipt,
        OfficeDocumentStore, OfficeOperationLogStore, OfficeSnapshotStore, OfficeStore,
    };
}

/// Re-exports save and autosave coordinator APIs.
pub mod save {
    pub use crate::{
        OfficeAutosaveContext, OfficeAutosaveDecision, OfficeAutosavePolicy, OfficeAutosaveReason,
        OfficeAutosaveRequest, OfficeAutosaveSkipReason, OfficeSaveCoordinator, OfficeSaveFailure,
        OfficeSaveOutcome, OfficeSaveReceipt, OfficeSaveSkip, OfficeSaveSkipReason,
        OfficeSaveState, OfficeSaveTrigger, OfficeSessionTrackedSaveError,
        OfficeSessionTrackedSaveResult,
    };
}

/// Re-exports status diagnostics, snapshots, deltas, and tracked operation APIs.
pub mod status {
    pub use crate::{
        OfficeSelectionKind, OfficeSessionDiagnosticFlag, OfficeSessionDiagnosticSeverity,
        OfficeSessionDiagnostics, OfficeSessionDiagnosticsPolicy, OfficeSessionDiagnosticsSignal,
        OfficeSessionRemoteBatchResult, OfficeSessionStatusDelta, OfficeSessionStatusField,
        OfficeSessionStatusObserver, OfficeSessionStatusSnapshot, OfficeSessionStatusTracker,
        OfficeSessionStatusTrackerUpdate, OfficeSessionStatusUpdate,
        OfficeSessionTrackedRemoteBatchError, OfficeSessionTrackedRemoteBatchResult,
    };
}

/// Re-exports collaboration and operation-batch sync APIs.
pub mod sync {
    pub use crate::{
        collect_operations_after, validate_incoming_batch, OfficeOperationBatch,
        OfficePendingSyncChanges, OfficeSessionTrackedSyncError, OfficeSessionTrackedSyncReceipt,
        OfficeSessionTrackedSyncReceiptError, OfficeSessionTrackedSyncResult,
        OfficeSyncCoordinator, OfficeSyncCursor, OfficeSyncError, OfficeSyncFailure,
        OfficeSyncOutcome, OfficeSyncReceipt, OfficeSyncSkip, OfficeSyncSkipReason,
        OfficeSyncState,
    };
}

/// Re-exports editor selection primitives shared by Office products.
pub mod selection {
    pub use crate::{
        GridPosition, GridRange, GridSelection, ObjectSelection, OfficeSelection, PageSelection,
        SelectionDirection, TextSelection,
    };
}

/// Re-exports operation, transaction, and undo/redo primitives.
pub mod operations {
    pub use crate::{
        apply_operations, apply_transaction, OperationApplier, OperationEnvelope, OperationId,
        OperationLog, OperationTransaction, OperationTransactionBuilder, TransactionError,
        TransactionHistory, UndoGroup, UndoRecord, UndoStack,
    };
}

/// Re-exports identity and lightweight scalar primitives.
pub mod identity {
    pub use crate::{
        ActorId, DocumentId, EngineId, IdValidationError, ObjectId, Range, TransactionId,
    };
}

/// Re-exports text buffer and edit primitives.
pub mod text {
    pub use crate::{EditOp, TextBuffer, TextBufferError, TextBufferResult, TextChange};
}

/// Re-exports validation primitives for product-specific models and snapshots.
pub mod validation {
    pub use crate::{
        Validatable, ValidationIssue, ValidationReport, ValidationResult, ValidationSeverity,
    };
}

/// Re-exports recovery, maintenance, and compaction APIs.
pub mod lifecycle {
    pub use crate::{
        compact_document_in_store, compact_snapshot_and_log, recover_session_from_snapshot_and_log,
        recover_session_from_store, OfficeCompactedDocument, OfficeCompactionError,
        OfficeCompactionPolicy, OfficeCompactionReport, OfficeCompactionStoreError,
        OfficeCompactionStoreResult, OfficeMaintenanceCompactionOutcome,
        OfficeMaintenanceCompactionReceipt, OfficeMaintenanceCompactionSkip,
        OfficeMaintenanceCompactionSkipReason, OfficeMaintenanceCoordinator,
        OfficeMaintenanceOutcome, OfficeMaintenancePolicy, OfficeMaintenanceProfile,
        OfficeRecoveredSession, OfficeRecoveryPolicy, OfficeRecoveryReport,
        OfficeRecoveryStoreError, OfficeRecoveryStoreResult,
    };
}

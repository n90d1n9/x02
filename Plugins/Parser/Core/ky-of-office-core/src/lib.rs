// Core primitives placeholder

pub mod buffer;
pub mod edit;
pub mod engine;
mod facade;
pub mod identity;
pub mod metadata;
pub mod operation;
pub mod persistence;
pub mod selection;
pub mod snapshot;
pub mod sync;
pub mod transaction;
pub mod types;
pub mod undo_redo;
pub mod validation;

pub use buffer::{TextBuffer, TextBufferError, TextBufferResult, TextChange};
pub use edit::EditOp;
pub use engine::{
    compact_document_in_store, compact_snapshot_and_log, recover_session_from_snapshot_and_log,
    recover_session_from_store, OfficeAutosaveContext, OfficeAutosaveDecision,
    OfficeAutosavePolicy, OfficeAutosaveReason, OfficeAutosaveRequest, OfficeAutosaveSkipReason,
    OfficeCompactedDocument, OfficeCompactionError, OfficeCompactionPolicy, OfficeCompactionReport,
    OfficeCompactionStoreError, OfficeCompactionStoreResult, OfficeDocumentSession,
    OfficeMaintenanceCompactionOutcome, OfficeMaintenanceCompactionReceipt,
    OfficeMaintenanceCompactionSkip, OfficeMaintenanceCompactionSkipReason,
    OfficeMaintenanceCoordinator, OfficeMaintenanceOutcome, OfficeMaintenancePolicy,
    OfficeMaintenanceProfile, OfficePendingSyncChanges, OfficeRecoveredSession,
    OfficeRecoveryPolicy, OfficeRecoveryReport, OfficeRecoveryStoreError,
    OfficeRecoveryStoreResult, OfficeSaveCoordinator, OfficeSaveFailure, OfficeSaveOutcome,
    OfficeSaveReceipt, OfficeSaveSkip, OfficeSaveSkipReason, OfficeSaveState, OfficeSaveTrigger,
    OfficeSelectionKind, OfficeSessionCheckpoint, OfficeSessionCommand, OfficeSessionCommandDelta,
    OfficeSessionCommandExecutionError, OfficeSessionCommandRequest, OfficeSessionCommandResult,
    OfficeSessionCommandState, OfficeSessionDiagnosticFlag, OfficeSessionDiagnosticSeverity,
    OfficeSessionDiagnostics, OfficeSessionDiagnosticsPolicy, OfficeSessionDiagnosticsSignal,
    OfficeSessionError, OfficeSessionEvent, OfficeSessionEventBatch, OfficeSessionEventCategory,
    OfficeSessionEventCursor, OfficeSessionEventError, OfficeSessionEventFilter,
    OfficeSessionEventKind, OfficeSessionEventObserver, OfficeSessionEventObserverUpdate,
    OfficeSessionEventPruneReport, OfficeSessionEventRetentionPolicy, OfficeSessionLogPruneReport,
    OfficeSessionRemoteBatchResult, OfficeSessionStatusDelta, OfficeSessionStatusField,
    OfficeSessionStatusObserver, OfficeSessionStatusSnapshot, OfficeSessionStatusTracker,
    OfficeSessionStatusTrackerUpdate, OfficeSessionStatusUpdate, OfficeSessionTrackedCommandError,
    OfficeSessionTrackedCommandResult, OfficeSessionTrackedRemoteBatchError,
    OfficeSessionTrackedRemoteBatchResult, OfficeSessionTrackedSaveError,
    OfficeSessionTrackedSaveResult, OfficeSessionTrackedSyncError, OfficeSessionTrackedSyncReceipt,
    OfficeSessionTrackedSyncReceiptError, OfficeSessionTrackedSyncResult, OfficeSyncCoordinator,
    OfficeSyncFailure, OfficeSyncOutcome, OfficeSyncReceipt, OfficeSyncSkip, OfficeSyncSkipReason,
    OfficeSyncState,
};
pub use identity::{
    ActorId, DocumentId, EngineId, IdValidationError, ObjectId, OperationId, TransactionId,
};
pub use metadata::{OfficeDocumentMetadata, OFFICE_DOCUMENT_METADATA_KEY};
pub use operation::{OperationEnvelope, OperationLog};
pub use persistence::{
    InMemoryOfficeStore, OfficeDocumentPersistMode, OfficeDocumentPersistReceipt,
    OfficeDocumentStore, OfficeOperationLogStore, OfficeSnapshotStore, OfficeStore,
};
pub use selection::{
    GridPosition, GridRange, GridSelection, ObjectSelection, OfficeSelection, PageSelection,
    SelectionDirection, TextSelection,
};
pub use snapshot::OfficeSnapshot;
pub use sync::{
    collect_operations_after, validate_incoming_batch, OfficeOperationBatch, OfficeSyncCursor,
    OfficeSyncError,
};
pub use transaction::{
    apply_operations, apply_transaction, OperationApplier, OperationTransaction,
    OperationTransactionBuilder, TransactionError, TransactionHistory,
};
pub use types::Range;
pub use undo_redo::{UndoGroup, UndoRecord, UndoStack};
pub use validation::{
    Validatable, ValidationIssue, ValidationReport, ValidationResult, ValidationSeverity,
};

pub mod core {
    pub use crate::facade::{
        commands, document, events, identity, lifecycle, operations, persistence, save, selection,
        status, sync, text, validation,
    };
    pub use crate::{
        apply_operations, apply_transaction, collect_operations_after, compact_document_in_store,
        compact_snapshot_and_log, recover_session_from_snapshot_and_log,
        recover_session_from_store, validate_incoming_batch, ActorId, DocumentId, EditOp, EngineId,
        GridPosition, GridRange, GridSelection, IdValidationError, InMemoryOfficeStore, ObjectId,
        ObjectSelection, OfficeAutosaveContext, OfficeAutosaveDecision, OfficeAutosavePolicy,
        OfficeAutosaveReason, OfficeAutosaveRequest, OfficeAutosaveSkipReason,
        OfficeCompactedDocument, OfficeCompactionError, OfficeCompactionPolicy,
        OfficeCompactionReport, OfficeCompactionStoreError, OfficeCompactionStoreResult,
        OfficeDocumentMetadata, OfficeDocumentPersistMode, OfficeDocumentPersistReceipt,
        OfficeDocumentSession, OfficeDocumentStore, OfficeMaintenanceCompactionOutcome,
        OfficeMaintenanceCompactionReceipt, OfficeMaintenanceCompactionSkip,
        OfficeMaintenanceCompactionSkipReason, OfficeMaintenanceCoordinator,
        OfficeMaintenanceOutcome, OfficeMaintenancePolicy, OfficeMaintenanceProfile,
        OfficeOperationBatch, OfficeOperationLogStore, OfficePendingSyncChanges,
        OfficeRecoveredSession, OfficeRecoveryPolicy, OfficeRecoveryReport,
        OfficeRecoveryStoreError, OfficeRecoveryStoreResult, OfficeSaveCoordinator,
        OfficeSaveFailure, OfficeSaveOutcome, OfficeSaveReceipt, OfficeSaveSkip,
        OfficeSaveSkipReason, OfficeSaveState, OfficeSaveTrigger, OfficeSelection,
        OfficeSelectionKind, OfficeSessionCheckpoint, OfficeSessionCommand,
        OfficeSessionCommandDelta, OfficeSessionCommandExecutionError, OfficeSessionCommandRequest,
        OfficeSessionCommandResult, OfficeSessionCommandState, OfficeSessionDiagnosticFlag,
        OfficeSessionDiagnosticSeverity, OfficeSessionDiagnostics, OfficeSessionDiagnosticsPolicy,
        OfficeSessionDiagnosticsSignal, OfficeSessionError, OfficeSessionEvent,
        OfficeSessionEventBatch, OfficeSessionEventCategory, OfficeSessionEventCursor,
        OfficeSessionEventError, OfficeSessionEventFilter, OfficeSessionEventKind,
        OfficeSessionEventObserver, OfficeSessionEventObserverUpdate,
        OfficeSessionEventPruneReport, OfficeSessionEventRetentionPolicy,
        OfficeSessionLogPruneReport, OfficeSessionRemoteBatchResult, OfficeSessionStatusDelta,
        OfficeSessionStatusField, OfficeSessionStatusObserver, OfficeSessionStatusSnapshot,
        OfficeSessionStatusTracker, OfficeSessionStatusTrackerUpdate, OfficeSessionStatusUpdate,
        OfficeSessionTrackedCommandError, OfficeSessionTrackedCommandResult,
        OfficeSessionTrackedRemoteBatchError, OfficeSessionTrackedRemoteBatchResult,
        OfficeSessionTrackedSaveError, OfficeSessionTrackedSaveResult,
        OfficeSessionTrackedSyncError, OfficeSessionTrackedSyncReceipt,
        OfficeSessionTrackedSyncReceiptError, OfficeSessionTrackedSyncResult, OfficeSnapshot,
        OfficeSnapshotStore, OfficeStore, OfficeSyncCoordinator, OfficeSyncCursor, OfficeSyncError,
        OfficeSyncFailure, OfficeSyncOutcome, OfficeSyncReceipt, OfficeSyncSkip,
        OfficeSyncSkipReason, OfficeSyncState, OperationApplier, OperationEnvelope, OperationId,
        OperationLog, OperationTransaction, OperationTransactionBuilder, PageSelection, Range,
        SelectionDirection, TextBuffer, TextBufferError, TextBufferResult, TextChange,
        TextSelection, TransactionError, TransactionHistory, TransactionId, Validatable,
        ValidationIssue, ValidationReport, ValidationResult, ValidationSeverity,
        OFFICE_DOCUMENT_METADATA_KEY,
    };
}

pub mod prelude {
    pub use crate::core::*;
}

#[cfg(test)]
mod public_api_tests {
    use super::core;

    #[test]
    fn organized_core_facade_exposes_status_and_sync_paths() {
        let mut tracker = core::status::OfficeSessionStatusTracker::all_events();
        let mut sync_coordinator =
            core::sync::OfficeSyncCoordinator::document_start("counter", "doc-1");
        let session: core::document::OfficeDocumentSession<(), ()> =
            core::document::OfficeDocumentSession::new("counter", "doc-1", ());

        let sync = tracker
            .prepare_sync_pending_changes(&mut sync_coordinator, &session, 1_000)
            .unwrap();

        assert!(sync.is_skipped());
        assert_eq!(
            sync.sync.skip().unwrap().cursor,
            core::sync::OfficeSyncCursor::document_start("counter", "doc-1")
        );
    }

    #[test]
    fn prelude_preserves_flat_core_compatibility() {
        use super::prelude::*;

        let command = OfficeSessionCommandRequest::clear_selection(1_000);
        let selection = OfficeSelection::None;
        let cursor = OfficeSyncCursor::document_start("counter", "doc-1");

        assert_eq!(command.command, OfficeSessionCommand::ClearSelection);
        assert!(selection.is_empty());
        assert_eq!(cursor.sequence, 0);
    }
}

// TODO: Move existing core logic here from the old Waraq project.

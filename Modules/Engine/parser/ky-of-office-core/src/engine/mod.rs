mod autosave;
mod checkpoint;
mod command_execution;
mod command_state;
mod compaction;
mod diagnostics;
mod error;
mod event;
mod event_filter;
mod event_observer;
mod event_retention;
mod history;
mod maintenance;
mod recovery;
mod save;
mod session;
mod status_delta;
mod status_observer;
mod status_tracker;
mod sync_coordinator;

pub use autosave::{
    OfficeAutosaveContext, OfficeAutosaveDecision, OfficeAutosavePolicy, OfficeAutosaveReason,
    OfficeAutosaveRequest, OfficeAutosaveSkipReason,
};
pub use checkpoint::OfficeSessionCheckpoint;
pub use command_execution::{
    OfficeSessionCommandExecutionError, OfficeSessionCommandRequest, OfficeSessionCommandResult,
};
pub use command_state::{
    OfficeSessionCommand, OfficeSessionCommandDelta, OfficeSessionCommandState,
};
pub use compaction::{
    compact_document_in_store, compact_snapshot_and_log, OfficeCompactedDocument,
    OfficeCompactionError, OfficeCompactionPolicy, OfficeCompactionReport,
    OfficeCompactionStoreError, OfficeCompactionStoreResult,
};
pub use diagnostics::{
    OfficeSelectionKind, OfficeSessionDiagnosticFlag, OfficeSessionDiagnosticSeverity,
    OfficeSessionDiagnostics, OfficeSessionDiagnosticsPolicy, OfficeSessionDiagnosticsSignal,
};
pub use error::OfficeSessionError;
pub use event::{
    OfficeSessionEvent, OfficeSessionEventBatch, OfficeSessionEventCursor, OfficeSessionEventError,
    OfficeSessionEventKind,
};
pub use event_filter::{OfficeSessionEventCategory, OfficeSessionEventFilter};
pub use event_observer::{OfficeSessionEventObserver, OfficeSessionEventObserverUpdate};
pub use event_retention::{OfficeSessionEventPruneReport, OfficeSessionEventRetentionPolicy};
pub use maintenance::{
    OfficeMaintenanceCompactionOutcome, OfficeMaintenanceCompactionReceipt,
    OfficeMaintenanceCompactionSkip, OfficeMaintenanceCompactionSkipReason,
    OfficeMaintenanceCoordinator, OfficeMaintenanceOutcome, OfficeMaintenancePolicy,
    OfficeMaintenanceProfile,
};
pub use recovery::{
    recover_session_from_snapshot_and_log, recover_session_from_store, OfficeRecoveredSession,
    OfficeRecoveryPolicy, OfficeRecoveryReport, OfficeRecoveryStoreError,
    OfficeRecoveryStoreResult,
};
pub use save::{
    OfficeSaveCoordinator, OfficeSaveFailure, OfficeSaveOutcome, OfficeSaveReceipt, OfficeSaveSkip,
    OfficeSaveSkipReason, OfficeSaveState, OfficeSaveTrigger,
};
pub use session::{OfficeDocumentSession, OfficeSessionLogPruneReport};
pub use status_delta::{OfficeSessionStatusDelta, OfficeSessionStatusField};
pub use status_observer::{
    OfficeSessionStatusObserver, OfficeSessionStatusSnapshot, OfficeSessionStatusUpdate,
};
pub use status_tracker::{
    OfficeSessionRemoteBatchResult, OfficeSessionStatusTracker, OfficeSessionStatusTrackerUpdate,
    OfficeSessionTrackedCommandError, OfficeSessionTrackedCommandResult,
    OfficeSessionTrackedRemoteBatchError, OfficeSessionTrackedRemoteBatchResult,
    OfficeSessionTrackedSaveError, OfficeSessionTrackedSaveResult, OfficeSessionTrackedSyncError,
    OfficeSessionTrackedSyncReceipt, OfficeSessionTrackedSyncReceiptError,
    OfficeSessionTrackedSyncResult,
};
pub use sync_coordinator::{
    OfficePendingSyncChanges, OfficeSyncCoordinator, OfficeSyncFailure, OfficeSyncOutcome,
    OfficeSyncReceipt, OfficeSyncSkip, OfficeSyncSkipReason, OfficeSyncState,
};

#[cfg(test)]
mod tests;

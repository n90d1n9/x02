use super::{
    compact_document_in_store, OfficeAutosavePolicy, OfficeCompactionPolicy,
    OfficeCompactionReport, OfficeCompactionStoreError, OfficeDocumentSession,
    OfficeSaveCoordinator, OfficeSaveOutcome, OfficeSaveState, OfficeSessionLogPruneReport,
};
use crate::{DocumentId, OfficeDocumentStore};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeMaintenanceProfile {
    InteractiveEditor,
    LargeDocument,
    LowMemoryDevice,
    CollaborativeSession,
}

impl OfficeMaintenanceProfile {
    pub fn policy(self) -> OfficeMaintenancePolicy {
        OfficeMaintenancePolicy::from_profile(self)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeMaintenancePolicy {
    pub autosave_policy: OfficeAutosavePolicy,
    pub compaction_policy: OfficeCompactionPolicy,
    pub compact_after_save: bool,
    pub min_operations_before_compaction: usize,
}

impl Default for OfficeMaintenancePolicy {
    fn default() -> Self {
        Self {
            autosave_policy: OfficeAutosavePolicy::default(),
            compaction_policy: OfficeCompactionPolicy::default(),
            compact_after_save: false,
            min_operations_before_compaction: 100,
        }
    }
}

impl OfficeMaintenancePolicy {
    pub fn from_profile(profile: OfficeMaintenanceProfile) -> Self {
        match profile {
            OfficeMaintenanceProfile::InteractiveEditor => Self::interactive_editor(),
            OfficeMaintenanceProfile::LargeDocument => Self::large_document(),
            OfficeMaintenanceProfile::LowMemoryDevice => Self::low_memory_device(),
            OfficeMaintenanceProfile::CollaborativeSession => Self::collaborative_session(),
        }
    }

    pub fn interactive_editor() -> Self {
        Self {
            autosave_policy: OfficeAutosavePolicy::default(),
            compaction_policy: OfficeCompactionPolicy::default(),
            compact_after_save: true,
            min_operations_before_compaction: 250,
        }
    }

    pub fn large_document() -> Self {
        Self {
            autosave_policy: OfficeAutosavePolicy::default()
                .with_idle_after_ms(3_000)
                .with_min_interval_ms(20_000)
                .with_max_pending_operations(40),
            compaction_policy: OfficeCompactionPolicy::default(),
            compact_after_save: true,
            min_operations_before_compaction: 75,
        }
    }

    pub fn low_memory_device() -> Self {
        Self {
            autosave_policy: OfficeAutosavePolicy::default()
                .with_idle_after_ms(1_000)
                .with_min_interval_ms(5_000)
                .with_max_pending_operations(10),
            compaction_policy: OfficeCompactionPolicy::default(),
            compact_after_save: true,
            min_operations_before_compaction: 25,
        }
    }

    pub fn collaborative_session() -> Self {
        Self {
            autosave_policy: OfficeAutosavePolicy::default()
                .with_idle_after_ms(500)
                .with_min_interval_ms(3_000)
                .with_max_pending_operations(5),
            compaction_policy: OfficeCompactionPolicy::default(),
            compact_after_save: true,
            min_operations_before_compaction: 1_000,
        }
    }

    pub fn autosave_and_compact() -> Self {
        Self {
            compact_after_save: true,
            ..Self::default()
        }
    }

    pub fn with_autosave_policy(mut self, autosave_policy: OfficeAutosavePolicy) -> Self {
        self.autosave_policy = autosave_policy;
        self
    }

    pub fn with_compaction_policy(mut self, compaction_policy: OfficeCompactionPolicy) -> Self {
        self.compaction_policy = compaction_policy;
        self
    }

    pub fn with_compact_after_save(mut self, compact_after_save: bool) -> Self {
        self.compact_after_save = compact_after_save;
        self
    }

    pub fn with_min_operations_before_compaction(
        mut self,
        min_operations_before_compaction: usize,
    ) -> Self {
        self.min_operations_before_compaction = min_operations_before_compaction;
        self
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeMaintenanceCompactionSkip {
    pub document_id: DocumentId,
    pub sequence: u64,
    pub reason: OfficeMaintenanceCompactionSkipReason,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeMaintenanceCompactionSkipReason {
    Disabled,
    SaveDidNotPersist,
    NoSnapshot,
    OperationThresholdNotReached {
        operation_count: usize,
        required_count: usize,
    },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeMaintenanceCompactionReceipt {
    pub persistence: OfficeCompactionReport,
    pub session_log_prune: OfficeSessionLogPruneReport,
}

impl OfficeMaintenanceCompactionReceipt {
    pub fn pruned_session_log(&self) -> bool {
        self.session_log_prune.pruned_operations()
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum OfficeMaintenanceCompactionOutcome<StoreError> {
    Compacted(OfficeMaintenanceCompactionReceipt),
    Skipped(OfficeMaintenanceCompactionSkip),
    Failed(OfficeCompactionStoreError<StoreError>),
}

impl<StoreError> OfficeMaintenanceCompactionOutcome<StoreError> {
    pub fn is_compacted(&self) -> bool {
        matches!(self, Self::Compacted(_))
    }

    pub fn is_skipped(&self) -> bool {
        matches!(self, Self::Skipped(_))
    }

    pub fn is_failed(&self) -> bool {
        matches!(self, Self::Failed(_))
    }

    pub fn report(&self) -> Option<&OfficeCompactionReport> {
        match self {
            Self::Compacted(receipt) => Some(&receipt.persistence),
            Self::Skipped(_) | Self::Failed(_) => None,
        }
    }

    pub fn receipt(&self) -> Option<&OfficeMaintenanceCompactionReceipt> {
        match self {
            Self::Compacted(receipt) => Some(receipt),
            Self::Skipped(_) | Self::Failed(_) => None,
        }
    }

    pub fn skip(&self) -> Option<&OfficeMaintenanceCompactionSkip> {
        match self {
            Self::Skipped(skip) => Some(skip),
            Self::Compacted(_) | Self::Failed(_) => None,
        }
    }

    pub fn failure(&self) -> Option<&OfficeCompactionStoreError<StoreError>> {
        match self {
            Self::Failed(error) => Some(error),
            Self::Compacted(_) | Self::Skipped(_) => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct OfficeMaintenanceOutcome<StoreError> {
    pub save: OfficeSaveOutcome<StoreError>,
    pub compaction: OfficeMaintenanceCompactionOutcome<StoreError>,
}

impl<StoreError> OfficeMaintenanceOutcome<StoreError> {
    pub fn is_saved(&self) -> bool {
        self.save.is_saved()
    }

    pub fn compacted(&self) -> bool {
        self.compaction.is_compacted()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeMaintenanceCoordinator {
    save_coordinator: OfficeSaveCoordinator,
}

impl Default for OfficeMaintenanceCoordinator {
    fn default() -> Self {
        Self::new()
    }
}

impl OfficeMaintenanceCoordinator {
    pub fn new() -> Self {
        Self {
            save_coordinator: OfficeSaveCoordinator::new(),
        }
    }

    pub fn for_session<State, Edit>(session: &OfficeDocumentSession<State, Edit>) -> Self {
        Self {
            save_coordinator: OfficeSaveCoordinator::for_session(session),
        }
    }

    pub fn save_status(&self) -> &OfficeSaveState {
        self.save_coordinator.status()
    }

    pub fn save_coordinator(&self) -> &OfficeSaveCoordinator {
        &self.save_coordinator
    }

    pub fn save_coordinator_mut(&mut self) -> &mut OfficeSaveCoordinator {
        &mut self.save_coordinator
    }

    pub fn refresh_from_session<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
    ) -> &OfficeSaveState {
        self.save_coordinator.refresh_from_session(session)
    }

    pub fn save_now<State, Edit, Store>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        policy: &OfficeMaintenancePolicy,
        timestamp_ms: u64,
    ) -> OfficeMaintenanceOutcome<Store::Error>
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        let save = self.save_coordinator.save_now(session, store, timestamp_ms);
        let compaction = self.compact_after_save(session, store, policy, &save);
        OfficeMaintenanceOutcome { save, compaction }
    }

    pub fn autosave_if_needed<State, Edit, Store>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        policy: &OfficeMaintenancePolicy,
        timestamp_ms: u64,
    ) -> OfficeMaintenanceOutcome<Store::Error>
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        let save = self.save_coordinator.autosave_if_needed(
            session,
            store,
            &policy.autosave_policy,
            timestamp_ms,
        );
        let compaction = self.compact_after_save(session, store, policy, &save);
        OfficeMaintenanceOutcome { save, compaction }
    }

    fn compact_after_save<State, Edit, Store>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        policy: &OfficeMaintenancePolicy,
        save: &OfficeSaveOutcome<Store::Error>,
    ) -> OfficeMaintenanceCompactionOutcome<Store::Error>
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        if !save.is_saved() {
            return Self::compaction_skip(
                session,
                OfficeMaintenanceCompactionSkipReason::SaveDidNotPersist,
            );
        }

        self.compact_if_enabled(session, store, policy)
    }

    fn compact_if_enabled<State, Edit, Store>(
        &mut self,
        session: &mut OfficeDocumentSession<State, Edit>,
        store: &mut Store,
        policy: &OfficeMaintenancePolicy,
    ) -> OfficeMaintenanceCompactionOutcome<Store::Error>
    where
        Store: OfficeDocumentStore<State, Edit>,
        State: Clone,
        Edit: Clone,
    {
        if !policy.compact_after_save {
            return Self::compaction_skip(session, OfficeMaintenanceCompactionSkipReason::Disabled);
        }

        let operation_count = session.operation_log().len();
        if operation_count < policy.min_operations_before_compaction {
            return Self::compaction_skip(
                session,
                OfficeMaintenanceCompactionSkipReason::OperationThresholdNotReached {
                    operation_count,
                    required_count: policy.min_operations_before_compaction,
                },
            );
        }

        match compact_document_in_store(
            store,
            session.document_id(),
            policy.compaction_policy.clone(),
        ) {
            Ok(Some(report)) => {
                let session_log_prune =
                    session.prune_saved_operations_through(report.snapshot_sequence);
                session.record_compaction_completed(
                    report.snapshot_sequence,
                    report.removed_operation_count,
                    report.retained_operation_count,
                    report.retained_sequence_range,
                    session.save_checkpoint().timestamp_ms,
                );
                OfficeMaintenanceCompactionOutcome::Compacted(OfficeMaintenanceCompactionReceipt {
                    persistence: report,
                    session_log_prune,
                })
            }
            Ok(None) => {
                Self::compaction_skip(session, OfficeMaintenanceCompactionSkipReason::NoSnapshot)
            }
            Err(error) => OfficeMaintenanceCompactionOutcome::Failed(error),
        }
    }

    fn compaction_skip<State, Edit, StoreError>(
        session: &OfficeDocumentSession<State, Edit>,
        reason: OfficeMaintenanceCompactionSkipReason,
    ) -> OfficeMaintenanceCompactionOutcome<StoreError> {
        OfficeMaintenanceCompactionOutcome::Skipped(OfficeMaintenanceCompactionSkip {
            document_id: session.document_id().clone(),
            sequence: session.sequence(),
            reason,
        })
    }
}

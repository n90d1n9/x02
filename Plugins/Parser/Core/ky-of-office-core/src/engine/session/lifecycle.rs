//! Session construction, hydration, accessors, and builder helpers.

use super::{log_prune::retained_log_floor_for_snapshot, OfficeDocumentSession};
use crate::{
    DocumentId, EngineId, OfficeSelection, OfficeSessionCheckpoint, OfficeSnapshot, OperationLog,
    TransactionHistory, Validatable, ValidationResult,
};

impl<State, Edit> OfficeDocumentSession<State, Edit> {
    pub fn new(
        engine: impl Into<EngineId>,
        document_id: impl Into<DocumentId>,
        state: State,
    ) -> Self {
        Self {
            engine: engine.into(),
            document_id: document_id.into(),
            state,
            operation_log: OperationLog::new(),
            history: TransactionHistory::new(),
            selection: OfficeSelection::None,
            events: Vec::new(),
            last_event_index: 0,
            event_pruned_through_index: 0,
            sequence: 0,
            last_timestamp_ms: 0,
            save_checkpoint: OfficeSessionCheckpoint::document_start(),
            operation_log_pruned_through_sequence: 0,
        }
    }

    pub fn from_snapshot(snapshot: OfficeSnapshot<State, Edit>) -> Self {
        let save_checkpoint =
            OfficeSessionCheckpoint::new(snapshot.sequence, snapshot.timestamp_ms);
        let operation_log_pruned_through_sequence =
            retained_log_floor_for_snapshot(snapshot.sequence, &snapshot.operation_log);
        Self {
            engine: snapshot.engine,
            document_id: snapshot.document_id,
            state: snapshot.state,
            operation_log: snapshot.operation_log,
            history: TransactionHistory::new(),
            selection: snapshot.selection,
            events: Vec::new(),
            last_event_index: 0,
            event_pruned_through_index: 0,
            sequence: snapshot.sequence,
            last_timestamp_ms: snapshot.timestamp_ms,
            save_checkpoint,
            operation_log_pruned_through_sequence,
        }
    }

    pub fn try_from_snapshot(snapshot: OfficeSnapshot<State, Edit>) -> ValidationResult<Self> {
        snapshot.require_valid()?;
        Ok(Self::from_snapshot(snapshot))
    }

    pub fn engine(&self) -> &EngineId {
        &self.engine
    }

    pub fn document_id(&self) -> &DocumentId {
        &self.document_id
    }

    pub fn state(&self) -> &State {
        &self.state
    }

    pub fn state_mut(&mut self) -> &mut State {
        &mut self.state
    }

    pub fn into_state(self) -> State {
        self.state
    }

    pub fn operation_log(&self) -> &OperationLog<Edit> {
        &self.operation_log
    }

    pub fn operation_log_pruned_through_sequence(&self) -> u64 {
        self.operation_log_pruned_through_sequence
    }

    pub fn history(&self) -> &TransactionHistory<Edit> {
        &self.history
    }

    pub fn can_undo(&self) -> bool {
        self.history.can_undo()
    }

    pub fn can_redo(&self) -> bool {
        self.history.can_redo()
    }

    pub fn with_operation_log(mut self, operation_log: OperationLog<Edit>) -> Self {
        self.sequence = operation_log
            .operations
            .iter()
            .map(|operation| operation.sequence)
            .max()
            .unwrap_or(0);
        self.last_timestamp_ms = operation_log
            .operations
            .iter()
            .map(|operation| operation.timestamp_ms)
            .max()
            .unwrap_or(0);
        self.operation_log = operation_log;
        self.operation_log_pruned_through_sequence =
            super::log_prune::retained_log_floor_for_operation_log(&self.operation_log);
        self
    }

    pub fn with_save_checkpoint(mut self, save_checkpoint: OfficeSessionCheckpoint) -> Self {
        self.save_checkpoint = save_checkpoint;
        self
    }

    pub fn with_history(mut self, history: TransactionHistory<Edit>) -> Self {
        self.history = history;
        self
    }
}

use super::*;
use crate::{
    DocumentId, EngineId, GridPosition, GridSelection, InMemoryOfficeStore, OfficeOperationBatch,
    OfficeOperationLogStore, OfficeSelection, OfficeSnapshot, OfficeSnapshotStore, OfficeStore,
    OfficeSyncCursor, OfficeSyncError, OperationApplier, OperationEnvelope, OperationLog,
    OperationTransaction, TextSelection, TransactionError, Validatable,
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
enum TestEdit {
    Add(i64),
    Set(i64),
}

#[derive(Debug, Clone, Default, PartialEq)]
struct CounterState {
    value: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
enum SaveTestError {
    OperationLogWriteFailed,
    SnapshotLoadFailed,
}

struct FailingSaveStore;
struct FailingLoadStore;

impl OfficeStore for FailingSaveStore {
    type Error = SaveTestError;
}

impl OfficeSnapshotStore<CounterState, TestEdit> for FailingSaveStore {
    fn load_snapshot(
        &self,
        _document_id: &DocumentId,
    ) -> Result<Option<OfficeSnapshot<CounterState, TestEdit>>, Self::Error> {
        Ok(None)
    }

    fn save_snapshot(
        &mut self,
        _snapshot: OfficeSnapshot<CounterState, TestEdit>,
    ) -> Result<(), Self::Error> {
        Ok(())
    }

    fn delete_snapshot(&mut self, _document_id: &DocumentId) -> Result<bool, Self::Error> {
        Ok(false)
    }
}

impl OfficeOperationLogStore<TestEdit> for FailingSaveStore {
    fn load_operation_log(
        &self,
        _document_id: &DocumentId,
    ) -> Result<Option<OperationLog<TestEdit>>, Self::Error> {
        Ok(None)
    }

    fn save_operation_log(
        &mut self,
        _document_id: DocumentId,
        _operation_log: OperationLog<TestEdit>,
    ) -> Result<(), Self::Error> {
        Err(SaveTestError::OperationLogWriteFailed)
    }

    fn append_operation(
        &mut self,
        _operation: OperationEnvelope<TestEdit>,
    ) -> Result<(), Self::Error> {
        Err(SaveTestError::OperationLogWriteFailed)
    }

    fn delete_operation_log(&mut self, _document_id: &DocumentId) -> Result<bool, Self::Error> {
        Ok(false)
    }
}

impl crate::OfficeDocumentStore<CounterState, TestEdit> for FailingSaveStore {}

impl OfficeStore for FailingLoadStore {
    type Error = SaveTestError;
}

impl OfficeSnapshotStore<CounterState, TestEdit> for FailingLoadStore {
    fn load_snapshot(
        &self,
        _document_id: &DocumentId,
    ) -> Result<Option<OfficeSnapshot<CounterState, TestEdit>>, Self::Error> {
        Err(SaveTestError::SnapshotLoadFailed)
    }

    fn save_snapshot(
        &mut self,
        _snapshot: OfficeSnapshot<CounterState, TestEdit>,
    ) -> Result<(), Self::Error> {
        Ok(())
    }

    fn delete_snapshot(&mut self, _document_id: &DocumentId) -> Result<bool, Self::Error> {
        Ok(false)
    }
}

impl OfficeOperationLogStore<TestEdit> for FailingLoadStore {
    fn load_operation_log(
        &self,
        _document_id: &DocumentId,
    ) -> Result<Option<OperationLog<TestEdit>>, Self::Error> {
        Ok(None)
    }

    fn save_operation_log(
        &mut self,
        _document_id: DocumentId,
        _operation_log: OperationLog<TestEdit>,
    ) -> Result<(), Self::Error> {
        Ok(())
    }

    fn append_operation(
        &mut self,
        _operation: OperationEnvelope<TestEdit>,
    ) -> Result<(), Self::Error> {
        Ok(())
    }

    fn delete_operation_log(&mut self, _document_id: &DocumentId) -> Result<bool, Self::Error> {
        Ok(false)
    }
}

impl crate::OfficeDocumentStore<CounterState, TestEdit> for FailingLoadStore {}

impl OperationApplier<TestEdit> for CounterState {
    type Outcome = i64;
    type Error = String;

    fn apply_operation(
        &mut self,
        operation: OperationEnvelope<TestEdit>,
    ) -> Result<Self::Outcome, Self::Error> {
        match operation.edit {
            TestEdit::Add(amount) => {
                self.value += amount;
                Ok(self.value)
            }
            TestEdit::Set(value) => {
                self.value = value;
                Ok(self.value)
            }
        }
    }
}

fn operation(sequence: u64, edit: TestEdit) -> OperationEnvelope<TestEdit> {
    operation_with_id(format!("op-{sequence}"), sequence, edit)
}

fn operation_with_id(
    operation_id: impl Into<String>,
    sequence: u64,
    edit: TestEdit,
) -> OperationEnvelope<TestEdit> {
    OperationEnvelope::new(
        "counter",
        operation_id.into(),
        "doc-1",
        "actor-1",
        sequence,
        1_000 + sequence,
        edit,
    )
}

#[test]
fn session_applies_operation_and_records_log_position() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());

    let outcome = session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();

    assert_eq!(outcome, 5);
    assert_eq!(session.state().value, 5);
    assert_eq!(session.sequence(), 1);
    assert_eq!(session.last_timestamp_ms(), 1_001);
    assert_eq!(session.operation_log().len(), 1);
    assert_eq!(session.events().len(), 1);
    assert!(matches!(
        &session.events()[0].kind,
        OfficeSessionEventKind::OperationApplied { operation_id }
            if operation_id.as_str() == "op-1"
    ));
    assert!(session.validate_report().is_valid());
}

#[test]
fn session_applies_transaction_and_commits_history() {
    let transaction = OperationTransaction::new("tx-1")
        .with_operation(operation(1, TestEdit::Add(5)))
        .with_operation(operation(2, TestEdit::Set(3)));
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());

    let outcomes = session.apply_transaction(transaction).unwrap();

    assert_eq!(outcomes, vec![5, 3]);
    assert_eq!(session.state().value, 3);
    assert_eq!(session.sequence(), 2);
    assert_eq!(session.operation_log().len(), 2);
    assert_eq!(session.history().committed_len(), 1);
    assert_eq!(session.events().len(), 3);
    assert!(matches!(
        &session.events()[2].kind,
        OfficeSessionEventKind::TransactionCommitted {
            transaction_id,
            operation_count,
        } if transaction_id.as_str() == "tx-1" && *operation_count == 2
    ));
}

#[test]
fn session_undo_reissues_inverse_operations_and_updates_history() {
    let transaction = OperationTransaction::builder("tx-1")
        .operation_pair(
            operation(1, TestEdit::Add(5)),
            operation_with_id("inverse-op-1", 1, TestEdit::Add(-5)),
        )
        .build_undoable()
        .unwrap();
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.apply_transaction(transaction).unwrap();

    let outcomes = session.undo(2_000).unwrap();

    assert_eq!(outcomes, vec![0]);
    assert_eq!(session.state().value, 0);
    assert_eq!(session.sequence(), 2);
    assert_eq!(session.operation_log().len(), 2);
    assert_eq!(session.history().committed_len(), 0);
    assert_eq!(session.history().undone_len(), 1);
    assert!(!session.can_undo());
    assert!(session.can_redo());

    let undo_operation = session.operation_log().operations.last().unwrap();
    assert_eq!(undo_operation.operation_id, "undo-tx-1-2");
    assert_eq!(undo_operation.sequence, 2);
    assert_eq!(undo_operation.timestamp_ms, 2_000);
    assert_eq!(
        undo_operation.metadata.get("history_action"),
        Some(&serde_json::Value::String("undo".into()))
    );
    assert_eq!(
        undo_operation.metadata.get("history_source_operation_id"),
        Some(&serde_json::Value::String("inverse-op-1".into()))
    );
    assert!(matches!(
        &session.events().last().unwrap().kind,
        OfficeSessionEventKind::UndoApplied {
            transaction_id,
            operation_count,
        } if transaction_id.as_str() == "tx-1" && *operation_count == 1
    ));
    assert!(session.validate_report().is_valid());
}

#[test]
fn session_redo_reissues_forward_operations_after_undo() {
    let transaction = OperationTransaction::builder("tx-1")
        .operation_pair(
            operation(1, TestEdit::Add(5)),
            operation_with_id("inverse-op-1", 1, TestEdit::Add(-5)),
        )
        .build_undoable()
        .unwrap();
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.apply_transaction(transaction).unwrap();
    session.undo(2_000).unwrap();

    let outcomes = session.redo(3_000).unwrap();

    assert_eq!(outcomes, vec![5]);
    assert_eq!(session.state().value, 5);
    assert_eq!(session.sequence(), 3);
    assert_eq!(session.operation_log().len(), 3);
    assert_eq!(session.history().committed_len(), 1);
    assert_eq!(session.history().undone_len(), 0);
    assert!(session.can_undo());
    assert!(!session.can_redo());

    let redo_operation = session.operation_log().operations.last().unwrap();
    assert_eq!(redo_operation.operation_id, "redo-tx-1-3");
    assert_eq!(redo_operation.sequence, 3);
    assert_eq!(redo_operation.timestamp_ms, 3_000);
    assert_eq!(
        redo_operation.metadata.get("history_action"),
        Some(&serde_json::Value::String("redo".into()))
    );
    assert_eq!(
        redo_operation.metadata.get("history_source_operation_id"),
        Some(&serde_json::Value::String("op-1".into()))
    );
    assert!(matches!(
        &session.events().last().unwrap().kind,
        OfficeSessionEventKind::RedoApplied {
            transaction_id,
            operation_count,
        } if transaction_id.as_str() == "tx-1" && *operation_count == 1
    ));
    assert!(session.validate_report().is_valid());
}

#[test]
fn session_undo_requires_inverse_operations_without_moving_history() {
    let transaction =
        OperationTransaction::new("tx-1").with_operation(operation(1, TestEdit::Add(5)));
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.apply_transaction(transaction).unwrap();

    let err = session.undo(2_000).unwrap_err();

    match err {
        OfficeSessionError::Transaction(TransactionError::MissingInverseOperations {
            transaction_id,
        }) => {
            assert_eq!(transaction_id, "tx-1");
        }
        _ => panic!("expected missing inverse transaction error"),
    }
    assert_eq!(session.state().value, 5);
    assert_eq!(session.sequence(), 1);
    assert_eq!(session.operation_log().len(), 1);
    assert_eq!(session.history().committed_len(), 1);
    assert_eq!(session.history().undone_len(), 0);
    assert!(session.can_undo());
    assert!(!session.can_redo());
}

#[test]
fn session_snapshot_captures_state_and_log() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    session.set_selection(OfficeSelection::Text(TextSelection::caret(3)));

    let snapshot: OfficeSnapshot<CounterState, TestEdit> = session.snapshot(2_000);

    assert_eq!(snapshot.engine, "counter");
    assert_eq!(snapshot.document_id, "doc-1");
    assert_eq!(snapshot.sequence, 1);
    assert_eq!(snapshot.timestamp_ms, 2_000);
    assert_eq!(snapshot.state.value, 8);
    assert_eq!(
        snapshot.selection,
        OfficeSelection::Text(TextSelection::caret(3))
    );
    assert_eq!(snapshot.operation_log.len(), 1);
    assert!(snapshot.validate_report().is_valid());
}

#[test]
fn session_hydrates_from_snapshot_with_log_selection_and_position() {
    let mut original = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    original
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    original.set_selection(OfficeSelection::Text(TextSelection::caret(3)));
    let snapshot: OfficeSnapshot<CounterState, TestEdit> = original.snapshot(2_000);

    let mut restored = OfficeDocumentSession::try_from_snapshot(snapshot).unwrap();

    assert_eq!(restored.engine().as_str(), "counter");
    assert_eq!(restored.document_id().as_str(), "doc-1");
    assert_eq!(restored.state().value, 8);
    assert_eq!(restored.sequence(), 1);
    assert_eq!(restored.last_timestamp_ms(), 2_000);
    assert_eq!(
        restored.save_checkpoint(),
        &OfficeSessionCheckpoint::new(1, 2_000)
    );
    assert!(!restored.is_dirty());
    assert_eq!(restored.operation_log().len(), 1);
    assert_eq!(restored.operation_log_pruned_through_sequence(), 0);
    assert_eq!(
        restored.selection(),
        &OfficeSelection::Text(TextSelection::caret(3))
    );
    assert_eq!(restored.history().committed_len(), 0);
    assert!(!restored.can_undo());

    restored
        .apply_operation(operation(2, TestEdit::Add(2)))
        .unwrap();
    assert_eq!(restored.state().value, 10);
    assert_eq!(restored.sequence(), 2);
    assert!(restored.is_dirty());
    assert_eq!(restored.dirty_sequence_range(), Some((2, 2)));
    assert_eq!(restored.operation_log().len(), 2);
}

#[test]
fn session_hydrates_compacted_snapshot_with_operation_log_floor() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 2, 1_002, CounterState { value: 12 });

    let restored =
        OfficeDocumentSession::<CounterState, TestEdit>::try_from_snapshot(snapshot).unwrap();

    assert_eq!(restored.sequence(), 2);
    assert_eq!(restored.operation_log().len(), 0);
    assert_eq!(restored.operation_log_pruned_through_sequence(), 2);
    let err = restored
        .operations_after(OfficeSyncCursor::new("counter", "doc-1", 0))
        .unwrap_err();
    assert_eq!(
        err,
        OfficeSyncError::OperationLogCompacted {
            requested_sequence: 0,
            available_after_sequence: 2,
        }
    );
}

#[test]
fn session_persists_snapshot_and_operation_log_to_store() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(3)), 2_000);
    let mut store = InMemoryOfficeStore::new();

    let receipt = session.persist_with_receipt_to(&mut store, 9_000).unwrap();

    let document_id = DocumentId::new("doc-1");
    let snapshot = store.load_snapshot(&document_id).unwrap().unwrap();
    let operation_log = store.load_operation_log(&document_id).unwrap().unwrap();

    assert_eq!(
        receipt,
        crate::OfficeDocumentPersistReceipt {
            document_id: document_id.clone(),
            snapshot_sequence: 1,
            snapshot_timestamp_ms: 9_000,
            operation_count: 1,
            operation_sequence_range: Some((1, 1)),
            mode: crate::OfficeDocumentPersistMode::Atomic,
        }
    );
    assert_eq!(snapshot.engine, "counter");
    assert_eq!(snapshot.document_id, "doc-1");
    assert_eq!(snapshot.sequence, 1);
    assert_eq!(snapshot.timestamp_ms, 9_000);
    assert_eq!(snapshot.state.value, 8);
    assert_eq!(
        snapshot.selection,
        OfficeSelection::Text(TextSelection::caret(3))
    );
    assert_eq!(snapshot.operation_log.len(), 1);
    assert_eq!(operation_log.len(), 1);
    assert_eq!(operation_log.operations[0].operation_id, "op-1");
}

#[test]
fn session_tracks_dirty_state_and_save_checkpoint() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());

    assert_eq!(
        session.save_checkpoint(),
        &OfficeSessionCheckpoint::document_start()
    );
    assert!(!session.is_dirty());
    assert_eq!(session.dirty_sequence_range(), None);

    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();

    assert!(session.is_dirty());
    assert_eq!(session.dirty_sequence_range(), Some((1, 1)));

    session.mark_saved(2_000);

    assert!(!session.is_dirty());
    assert_eq!(
        session.save_checkpoint(),
        &OfficeSessionCheckpoint::new(1, 2_000)
    );
    assert!(matches!(
        &session.events().last().unwrap().kind,
        OfficeSessionEventKind::CheckpointSaved {
            sequence,
            timestamp_ms,
        } if *sequence == 1 && *timestamp_ms == 2_000
    ));

    session
        .apply_operation(operation(2, TestEdit::Add(4)))
        .unwrap();

    assert!(session.is_dirty());
    assert_eq!(session.dirty_sequence_range(), Some((2, 2)));
}

#[test]
fn session_reports_diagnostics_for_status_surfaces() {
    let transaction =
        OperationTransaction::new("tx-1").with_operation(operation(1, TestEdit::Add(8)));
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.apply_transaction(transaction).unwrap();
    session.mark_saved(2_000);
    session
        .apply_operation(operation(2, TestEdit::Add(4)))
        .unwrap();
    session.set_selection_at(
        OfficeSelection::Grid(GridSelection::cell(GridPosition::new(2, 3))),
        2_500,
    );
    session.prune_saved_operations_to_checkpoint();
    session.prune_events(&OfficeSessionEventRetentionPolicy::max_events(2));

    let diagnostics = session.diagnostics();

    assert_eq!(
        diagnostics,
        OfficeSessionDiagnostics {
            engine: EngineId::new("counter"),
            document_id: DocumentId::new("doc-1"),
            sequence: 2,
            last_timestamp_ms: 1_002,
            save_checkpoint: OfficeSessionCheckpoint::new(1, 2_000),
            is_dirty: true,
            dirty_sequence_range: Some((2, 2)),
            pending_operation_count: 1,
            operation_log_count: 1,
            operation_log_pruned_through_sequence: 1,
            operation_log_retained_sequence_range: Some((2, 2)),
            event_cursor: OfficeSessionEventCursor::new(6),
            event_queue_count: 2,
            event_pruned_through_index: 4,
            event_retained_range: Some((5, 6)),
            selection_kind: OfficeSelectionKind::Grid,
            selection_is_empty: false,
            can_undo: true,
            can_redo: false,
        }
    );
    assert!(diagnostics.operation_log_was_pruned());
    assert!(diagnostics.event_queue_was_pruned());

    let value = serde_json::to_value(&diagnostics).unwrap();

    assert_eq!(value["selection_kind"], serde_json::json!("grid"));
    assert_eq!(value["event_cursor"]["event_index"], serde_json::json!(6));

    let restored: OfficeSessionDiagnostics = serde_json::from_value(value).unwrap();

    assert_eq!(restored, diagnostics);
}

#[test]
fn session_diagnostics_evaluates_product_status_signals() {
    let clean_session = OfficeDocumentSession::<CounterState, TestEdit>::new(
        "counter",
        "doc-1",
        CounterState::default(),
    );
    let clean_signal = clean_session
        .diagnostics()
        .evaluate(&OfficeSessionDiagnosticsPolicy::default());

    assert!(clean_signal.is_healthy());
    assert!(clean_signal.flags.is_empty());

    let transaction =
        OperationTransaction::new("tx-1").with_operation(operation(1, TestEdit::Add(8)));
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.apply_transaction(transaction).unwrap();
    session.mark_saved(2_000);
    session
        .apply_operation(operation(2, TestEdit::Add(4)))
        .unwrap();
    session.set_selection_at(
        OfficeSelection::Grid(GridSelection::cell(GridPosition::new(2, 3))),
        2_500,
    );
    session.prune_saved_operations_to_checkpoint();
    session.prune_events(&OfficeSessionEventRetentionPolicy::max_events(2));

    let policy = OfficeSessionDiagnosticsPolicy::quiet()
        .with_flag_dirty_sessions(true)
        .with_pending_operation_warning_threshold(Some(1))
        .with_operation_log_warning_threshold(Some(1))
        .with_event_queue_warning_threshold(Some(2));
    let signal = session.diagnostics().evaluate(&policy);

    assert_eq!(signal.severity, OfficeSessionDiagnosticSeverity::Warning);
    assert!(signal.has_flag(OfficeSessionDiagnosticFlag::Dirty));
    assert!(signal.has_flag(OfficeSessionDiagnosticFlag::PendingOperationsHigh));
    assert!(signal.has_flag(OfficeSessionDiagnosticFlag::OperationLogHigh));
    assert!(signal.has_flag(OfficeSessionDiagnosticFlag::EventQueueHigh));
    assert!(signal.has_flag(OfficeSessionDiagnosticFlag::OperationLogPruned));
    assert!(signal.has_flag(OfficeSessionDiagnosticFlag::EventQueuePruned));
    assert_eq!(signal.flags.len(), 6);

    let value = serde_json::to_value(&signal).unwrap();

    assert_eq!(value["severity"], serde_json::json!("warning"));

    let restored: OfficeSessionDiagnosticsSignal = serde_json::from_value(value).unwrap();

    assert_eq!(restored, signal);
}

#[test]
fn session_command_state_derives_product_action_availability() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let clean_commands = OfficeSessionCommandState::from_diagnostics(&session.diagnostics());

    assert!(clean_commands.is_empty());
    assert!(!clean_commands.can_save());
    assert!(!clean_commands.can_sync_pending_changes());
    assert!(!clean_commands.can_undo());
    assert!(!clean_commands.can_redo());
    assert!(!clean_commands.can_clear_selection());

    let transaction = OperationTransaction::builder("tx-1")
        .operation_pair(
            operation(1, TestEdit::Add(5)),
            operation_with_id("inverse-op-1", 1, TestEdit::Add(-5)),
        )
        .build_undoable()
        .unwrap();
    session.apply_transaction(transaction).unwrap();
    session.set_selection_at(
        OfficeSelection::Grid(GridSelection::cell(GridPosition::new(2, 3))),
        2_500,
    );

    let active_commands = OfficeSessionCommandState::from_diagnostics(&session.diagnostics());

    assert!(active_commands.can_save());
    assert!(active_commands.can_sync_pending_changes());
    assert!(active_commands.can_undo());
    assert!(!active_commands.can_redo());
    assert!(active_commands.can_clear_selection());
    assert!(active_commands.is_enabled(OfficeSessionCommand::Undo));
    assert_eq!(active_commands.enabled_commands().len(), 4);

    let value = serde_json::to_value(&active_commands).unwrap();

    assert_eq!(
        value["enabled"],
        serde_json::json!(["save", "sync_pending_changes", "undo", "clear_selection"])
    );

    let restored: OfficeSessionCommandState = serde_json::from_value(value).unwrap();

    assert_eq!(restored, active_commands);

    session.undo(3_000).unwrap();
    let redo_commands = OfficeSessionCommandState::from_diagnostics(&session.diagnostics());

    assert!(!redo_commands.can_undo());
    assert!(redo_commands.can_redo());

    let command_delta = redo_commands.diff_from(&active_commands);

    assert!(command_delta.was_enabled(OfficeSessionCommand::Redo));
    assert!(command_delta.was_disabled(OfficeSessionCommand::Undo));
    assert_eq!(command_delta.enabled_commands().len(), 1);
    assert_eq!(command_delta.disabled_commands().len(), 1);

    let value = serde_json::to_value(&command_delta).unwrap();

    assert_eq!(value["enabled"], serde_json::json!(["redo"]));
    assert_eq!(value["disabled"], serde_json::json!(["undo"]));

    let restored: OfficeSessionCommandDelta = serde_json::from_value(value).unwrap();

    assert_eq!(restored, command_delta);
}

#[test]
fn session_executes_core_commands_from_typed_requests() {
    let transaction = OperationTransaction::builder("tx-1")
        .operation_pair(
            operation(1, TestEdit::Add(5)),
            operation_with_id("inverse-op-1", 1, TestEdit::Add(-5)),
        )
        .build_undoable()
        .unwrap();
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.apply_transaction(transaction).unwrap();
    session.set_selection_at(
        OfficeSelection::Grid(GridSelection::cell(GridPosition::new(2, 3))),
        1_500,
    );

    assert!(OfficeSessionCommand::Undo.is_session_executable());
    assert!(OfficeSessionCommand::Save.requires_external_handler());

    let clear = session
        .execute_command(OfficeSessionCommandRequest::clear_selection(2_000))
        .unwrap();

    assert_eq!(clear.command, OfficeSessionCommand::ClearSelection);
    assert!(!clear.sequence_changed());
    assert!(clear.emitted_events());
    assert!(clear.operation_outcomes.is_empty());
    assert!(session.selection().is_empty());
    assert!(clear
        .command_delta()
        .was_disabled(OfficeSessionCommand::ClearSelection));

    let undo = session
        .execute_command(OfficeSessionCommandRequest::undo(3_000))
        .unwrap();

    assert_eq!(undo.command, OfficeSessionCommand::Undo);
    assert_eq!(undo.sequence_before, 1);
    assert_eq!(undo.sequence_after, 2);
    assert!(undo.sequence_changed());
    assert!(undo.emitted_events());
    assert_eq!(undo.operation_outcomes, vec![0]);
    assert!(undo.command_delta().was_enabled(OfficeSessionCommand::Redo));
    assert!(undo
        .command_delta()
        .was_disabled(OfficeSessionCommand::Undo));
    assert_eq!(session.state().value, 0);

    let value = serde_json::to_value(&undo).unwrap();

    assert_eq!(value["command"], serde_json::json!("undo"));
    assert_eq!(value["operation_outcomes"], serde_json::json!([0]));

    let restored: OfficeSessionCommandResult<i64> = serde_json::from_value(value).unwrap();

    assert_eq!(restored, undo);

    let redo = session
        .execute_command(OfficeSessionCommandRequest::redo(4_000))
        .unwrap();

    assert_eq!(redo.command, OfficeSessionCommand::Redo);
    assert_eq!(redo.sequence_before, 2);
    assert_eq!(redo.sequence_after, 3);
    assert_eq!(redo.operation_outcomes, vec![5]);
    assert!(redo.command_delta().was_enabled(OfficeSessionCommand::Undo));
    assert!(redo
        .command_delta()
        .was_disabled(OfficeSessionCommand::Redo));
    assert_eq!(session.state().value, 5);
}

#[test]
fn session_command_execution_reports_disabled_and_external_commands() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let err = session
        .execute_command(OfficeSessionCommandRequest::undo(1_000))
        .unwrap_err();

    assert_eq!(
        err,
        OfficeSessionCommandExecutionError::Disabled {
            command: OfficeSessionCommand::Undo,
        }
    );

    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();

    let save_request = OfficeSessionCommandRequest::save(2_000);
    let value = serde_json::to_value(save_request).unwrap();

    assert_eq!(value["command"], serde_json::json!("save"));
    assert_eq!(value["timestamp_ms"], serde_json::json!(2_000));

    let restored: OfficeSessionCommandRequest = serde_json::from_value(value).unwrap();

    assert_eq!(restored, save_request);

    let save_err = session.execute_command(save_request).unwrap_err();

    assert_eq!(
        save_err,
        OfficeSessionCommandExecutionError::RequiresExternalHandler {
            command: OfficeSessionCommand::Save,
        }
    );

    let sync_err = session
        .execute_command(OfficeSessionCommandRequest::sync_pending_changes(2_000))
        .unwrap_err();

    assert_eq!(
        sync_err,
        OfficeSessionCommandExecutionError::RequiresExternalHandler {
            command: OfficeSessionCommand::SyncPendingChanges,
        }
    );
}

#[test]
fn session_status_observer_polls_diagnostics_signal_and_events() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let policy = OfficeSessionDiagnosticsPolicy::quiet()
        .with_flag_dirty_sessions(true)
        .with_pending_operation_warning_threshold(Some(1));
    let mut observer = OfficeSessionStatusObserver::category(OfficeSessionEventCategory::Selection)
        .with_diagnostics_policy(policy);
    let baseline = observer.snapshot(&session);

    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(
        OfficeSelection::Grid(GridSelection::cell(GridPosition::new(2, 3))),
        2_500,
    );

    let update = observer.poll(&session).unwrap();

    assert_eq!(update.snapshot.diagnostics.sequence, 1);
    assert_eq!(
        update.snapshot.diagnostics.selection_kind,
        OfficeSelectionKind::Grid
    );
    assert_eq!(
        update.snapshot.signal.severity,
        OfficeSessionDiagnosticSeverity::Warning
    );
    assert!(update
        .snapshot
        .signal
        .has_flag(OfficeSessionDiagnosticFlag::Dirty));
    assert!(update
        .snapshot
        .signal
        .has_flag(OfficeSessionDiagnosticFlag::PendingOperationsHigh));
    assert!(!update.snapshot.is_healthy());
    assert!(update.snapshot.commands.can_save());
    assert!(update.snapshot.commands.can_sync_pending_changes());
    assert!(!update.snapshot.commands.can_undo());
    assert!(update.snapshot.can(OfficeSessionCommand::ClearSelection));

    let delta = update.diff_from(&baseline);

    assert!(delta.has_changed(OfficeSessionStatusField::Sequence));
    assert!(delta.has_changed(OfficeSessionStatusField::LastActivity));
    assert!(delta.has_changed(OfficeSessionStatusField::SaveState));
    assert!(delta.has_changed(OfficeSessionStatusField::PendingOperations));
    assert!(delta.has_changed(OfficeSessionStatusField::OperationLog));
    assert!(delta.has_changed(OfficeSessionStatusField::Events));
    assert!(delta.selection_changed());
    assert!(delta.status_signal_changed());
    assert!(delta.command_state_changed());
    assert!(!delta.has_changed(OfficeSessionStatusField::History));
    assert!(delta.command_delta.was_enabled(OfficeSessionCommand::Save));
    assert!(delta
        .command_delta
        .was_enabled(OfficeSessionCommand::SyncPendingChanges));
    assert!(delta
        .command_delta
        .was_enabled(OfficeSessionCommand::ClearSelection));
    assert_eq!(delta.command_delta.enabled_commands().len(), 3);
    assert!(update.snapshot.diff_from(&update.snapshot).is_empty());

    let delta_value = serde_json::to_value(&delta).unwrap();

    assert!(delta_value["changed"]
        .as_array()
        .unwrap()
        .contains(&serde_json::json!("commands")));

    let restored_delta: OfficeSessionStatusDelta = serde_json::from_value(delta_value).unwrap();

    assert_eq!(restored_delta, delta);

    assert_eq!(update.events.batch.len(), 1);
    assert_eq!(
        update.events.batch.events[0].category(),
        OfficeSessionEventCategory::Selection
    );
    assert_eq!(observer.event_cursor(), OfficeSessionEventCursor::new(2));
    assert!(!update.event_cursor_was_reset());

    let value = serde_json::to_value(&observer).unwrap();

    assert_eq!(
        value["event_observer"]["cursor"]["event_index"],
        serde_json::json!(2)
    );

    let restored: OfficeSessionStatusObserver = serde_json::from_value(value).unwrap();

    assert_eq!(restored, observer);
}

#[test]
fn session_status_tracker_hydrates_then_reports_incremental_delta() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let policy = OfficeSessionDiagnosticsPolicy::quiet()
        .with_flag_dirty_sessions(true)
        .with_pending_operation_warning_threshold(Some(1));
    let mut tracker = OfficeSessionStatusTracker::category(OfficeSessionEventCategory::Selection)
        .with_diagnostics_policy(policy);

    let initial = tracker.poll(&session).unwrap();

    assert!(initial.is_initial());
    assert!(initial.delta.is_none());
    assert!(!initial.has_incremental_changes());
    assert_eq!(tracker.last_snapshot(), Some(initial.snapshot()));

    let unchanged = tracker.poll(&session).unwrap();

    assert!(!unchanged.is_initial());
    assert!(!unchanged.has_incremental_changes());
    assert!(unchanged.delta.as_ref().unwrap().is_empty());

    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(
        OfficeSelection::Grid(GridSelection::cell(GridPosition::new(2, 3))),
        2_500,
    );

    let changed = tracker.poll(&session).unwrap();
    let delta = changed.delta.as_ref().unwrap();

    assert!(!changed.is_initial());
    assert!(changed.has_incremental_changes());
    assert!(delta.has_changed(OfficeSessionStatusField::Sequence));
    assert!(delta.has_changed(OfficeSessionStatusField::SaveState));
    assert!(delta.selection_changed());
    assert!(delta.command_delta.was_enabled(OfficeSessionCommand::Save));
    assert!(delta
        .command_delta
        .was_enabled(OfficeSessionCommand::SyncPendingChanges));
    assert!(delta
        .command_delta
        .was_enabled(OfficeSessionCommand::ClearSelection));
    assert_eq!(changed.update.events.batch.len(), 1);
    assert_eq!(tracker.event_cursor(), OfficeSessionEventCursor::new(2));
    assert_eq!(tracker.last_snapshot().unwrap().diagnostics.sequence, 1);

    let value = serde_json::to_value(&tracker).unwrap();

    assert_eq!(
        value["observer"]["event_observer"]["cursor"]["event_index"],
        serde_json::json!(2)
    );
    assert_eq!(
        value["last_snapshot"]["diagnostics"]["sequence"],
        serde_json::json!(1)
    );

    let restored: OfficeSessionStatusTracker = serde_json::from_value(value).unwrap();

    assert_eq!(restored, tracker);

    let mut seeded = OfficeSessionStatusTracker::all_events();
    seeded.seed_last_snapshot(changed.update.snapshot.clone());
    assert!(seeded.last_snapshot().is_some());
    seeded.reset_last_snapshot();
    assert!(seeded.last_snapshot().is_none());
}

#[test]
fn session_status_tracker_executes_command_and_reports_delta() {
    let transaction = OperationTransaction::builder("tx-1")
        .operation_pair(
            operation(1, TestEdit::Add(5)),
            operation_with_id("inverse-op-1", 1, TestEdit::Add(-5)),
        )
        .build_undoable()
        .unwrap();
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.apply_transaction(transaction).unwrap();

    let mut tracker = OfficeSessionStatusTracker::all_events();
    let initial = tracker.poll(&session).unwrap();

    assert!(initial.is_initial());

    let result = tracker
        .execute_command(&mut session, OfficeSessionCommandRequest::undo(2_000))
        .unwrap();

    assert_eq!(result.command.command, OfficeSessionCommand::Undo);
    assert_eq!(result.command.operation_outcomes, vec![0]);
    assert_eq!(result.command.sequence_after, 2);
    assert!(result.has_incremental_changes());
    assert!(!result.event_cursor_was_reset());
    assert_eq!(session.state().value, 0);
    assert_eq!(tracker.last_snapshot().unwrap().diagnostics.sequence, 2);

    let delta = result.status.delta.as_ref().unwrap();

    assert!(delta.has_changed(OfficeSessionStatusField::Sequence));
    assert!(delta.has_changed(OfficeSessionStatusField::History));
    assert!(delta.command_delta.was_enabled(OfficeSessionCommand::Redo));
    assert!(delta.command_delta.was_disabled(OfficeSessionCommand::Undo));

    let value = serde_json::to_value(&result).unwrap();

    assert_eq!(value["command"]["command"], serde_json::json!("undo"));

    let restored: OfficeSessionTrackedCommandResult<i64> = serde_json::from_value(value).unwrap();

    assert_eq!(restored, result);
}

#[test]
fn session_status_tracker_reports_command_errors_without_polling_status() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let mut tracker = OfficeSessionStatusTracker::all_events();
    let initial = tracker.poll(&session).unwrap();

    assert_eq!(tracker.last_snapshot(), Some(initial.snapshot()));

    let err = tracker
        .execute_command(&mut session, OfficeSessionCommandRequest::undo(2_000))
        .unwrap_err();

    assert_eq!(
        err,
        OfficeSessionTrackedCommandError::Command(OfficeSessionCommandExecutionError::Disabled {
            command: OfficeSessionCommand::Undo,
        },),
    );
    assert_eq!(tracker.last_snapshot(), Some(initial.snapshot()));
}

#[test]
fn session_status_tracker_saves_and_reports_delta() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut coordinator = OfficeSaveCoordinator::for_session(&session);
    let mut tracker = OfficeSessionStatusTracker::all_events();
    let initial = tracker.poll(&session).unwrap();

    assert!(initial.snapshot().can(OfficeSessionCommand::Save));
    assert!(initial
        .snapshot()
        .can(OfficeSessionCommand::SyncPendingChanges));

    let mut store = InMemoryOfficeStore::new();
    let result = tracker
        .save_now(&mut coordinator, &mut session, &mut store, 9_000)
        .unwrap();

    assert!(result.is_saved());
    assert_eq!(
        result.save.receipt().unwrap(),
        &OfficeSaveReceipt {
            trigger: OfficeSaveTrigger::Manual,
            sequence: 1,
            timestamp_ms: 9_000,
            dirty_sequence_range: Some((1, 1)),
            pending_operation_count: 1,
        }
    );
    assert!(result.has_incremental_changes());
    assert!(!result.event_cursor_was_reset());
    assert!(!session.is_dirty());
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Saved {
            sequence: 1,
            timestamp_ms: 9_000,
        }
    );

    let delta = result.status.delta.as_ref().unwrap();

    assert!(delta.has_changed(OfficeSessionStatusField::SaveState));
    assert!(delta.has_changed(OfficeSessionStatusField::PendingOperations));
    assert!(delta.has_changed(OfficeSessionStatusField::Events));
    assert!(delta.command_delta.was_disabled(OfficeSessionCommand::Save));
    assert!(delta
        .command_delta
        .was_disabled(OfficeSessionCommand::SyncPendingChanges));
    assert_eq!(result.status.update.events.batch.len(), 2);
    assert_eq!(tracker.last_snapshot().unwrap().diagnostics.sequence, 1);

    let saved = store
        .load_snapshot(&DocumentId::new("doc-1"))
        .unwrap()
        .unwrap();

    assert_eq!(saved.sequence, 1);
    assert_eq!(saved.timestamp_ms, 9_000);

    let serializable = OfficeSessionTrackedSaveResult::<SaveTestError>::new(
        OfficeSaveOutcome::Saved(result.save.receipt().unwrap().clone()),
        result.status.clone(),
    );
    let value = serde_json::to_value(&serializable).unwrap();

    assert_eq!(value["save"]["outcome"], serde_json::json!("saved"));

    let restored: OfficeSessionTrackedSaveResult<SaveTestError> =
        serde_json::from_value(value).unwrap();

    assert_eq!(restored, serializable);
}

#[test]
fn session_status_tracker_autosave_skip_reports_status_event() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut coordinator = OfficeSaveCoordinator::for_session(&session);
    let mut tracker = OfficeSessionStatusTracker::all_events();
    tracker.poll(&session).unwrap();

    let mut store = InMemoryOfficeStore::new();
    let result = tracker
        .autosave_if_needed(
            &mut coordinator,
            &mut session,
            &mut store,
            &OfficeAutosavePolicy::disabled(),
            9_000,
        )
        .unwrap();

    assert!(result.is_skipped());
    assert_eq!(
        result.save.skip().unwrap(),
        &OfficeSaveSkip {
            trigger: None,
            reason: OfficeSaveSkipReason::Autosave(OfficeAutosaveSkipReason::Disabled),
            sequence: 1,
            timestamp_ms: 9_000,
        }
    );
    assert!(result.has_incremental_changes());
    assert!(session.is_dirty());
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Dirty {
            sequence: 1,
            pending_operation_count: 1,
        }
    );

    let delta = result.status.delta.as_ref().unwrap();

    assert!(delta.has_changed(OfficeSessionStatusField::Events));
    assert!(!delta.has_changed(OfficeSessionStatusField::SaveState));
    assert!(delta.command_delta.is_empty());
    assert_eq!(result.status.update.events.batch.len(), 1);
    assert!(matches!(
        result.status.update.events.batch.events[0].kind,
        OfficeSessionEventKind::SaveSkipped {
            trigger: None,
            reason: OfficeSaveSkipReason::Autosave(OfficeAutosaveSkipReason::Disabled),
        }
    ));
}

#[test]
fn session_status_tracker_prepares_sync_pending_changes_and_reports_delta() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let mut sync_coordinator = OfficeSyncCoordinator::document_start("counter", "doc-1");
    let mut tracker = OfficeSessionStatusTracker::all_events();

    tracker.poll(&session).unwrap();

    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();

    let result = tracker
        .prepare_sync_pending_changes(&mut sync_coordinator, &session, 9_000)
        .unwrap();

    assert!(result.is_prepared());
    assert!(result.has_incremental_changes());
    assert_eq!(
        result.sync.prepared().unwrap().batch.base,
        OfficeSyncCursor::document_start("counter", "doc-1")
    );
    assert_eq!(
        result.sync.prepared().unwrap().batch.target,
        OfficeSyncCursor::new("counter", "doc-1", 1)
    );
    assert_eq!(result.sync.prepared().unwrap().pending_operation_count, 1);
    assert_eq!(
        sync_coordinator.status(),
        &OfficeSyncState::Pending {
            target: OfficeSyncCursor::new("counter", "doc-1", 1),
            pending_operation_count: 1,
            timestamp_ms: 9_000,
        }
    );

    let delta = result.status.delta.as_ref().unwrap();

    assert!(delta.has_changed(OfficeSessionStatusField::Sequence));
    assert!(delta.has_changed(OfficeSessionStatusField::PendingOperations));
    assert!(delta.has_changed(OfficeSessionStatusField::Events));
    assert!(delta
        .command_delta
        .was_enabled(OfficeSessionCommand::SyncPendingChanges));
    assert_eq!(result.status.update.events.batch.len(), 1);

    let value = serde_json::to_value(&result).unwrap();

    assert_eq!(value["sync"]["outcome"], serde_json::json!("prepared"));

    let restored: OfficeSessionTrackedSyncResult<TestEdit> = serde_json::from_value(value).unwrap();

    assert_eq!(restored, result);
}

#[test]
fn session_status_tracker_marks_synced_and_reports_receipt() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let mut sync_coordinator = OfficeSyncCoordinator::document_start("counter", "doc-1");
    let mut tracker = OfficeSessionStatusTracker::all_events();

    tracker.poll(&session).unwrap();
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();

    let prepared = tracker
        .prepare_sync_pending_changes(&mut sync_coordinator, &session, 9_000)
        .unwrap();
    let target = prepared.sync.prepared().unwrap().batch.target.clone();
    let receipt = tracker
        .mark_synced(&mut sync_coordinator, &session, target, 10_000)
        .unwrap();

    assert!(receipt.acknowledged_sequences());
    assert_eq!(
        receipt.receipt,
        OfficeSyncReceipt {
            previous: OfficeSyncCursor::document_start("counter", "doc-1"),
            target: OfficeSyncCursor::new("counter", "doc-1", 1),
            acknowledged_sequence_count: 1,
            timestamp_ms: 10_000,
        }
    );
    assert_eq!(
        sync_coordinator.acknowledged_cursor(),
        &OfficeSyncCursor::new("counter", "doc-1", 1)
    );
    assert_eq!(
        sync_coordinator.status(),
        &OfficeSyncState::Synced {
            target: OfficeSyncCursor::new("counter", "doc-1", 1),
            acknowledged_sequence_count: 1,
            timestamp_ms: 10_000,
        }
    );
    assert!(!receipt.has_incremental_changes());
    assert!(receipt.status.delta.as_ref().unwrap().is_empty());
    assert_eq!(receipt.status.update.events.batch.len(), 0);

    let value = serde_json::to_value(&receipt).unwrap();

    assert_eq!(value["receipt"]["target"]["sequence"], serde_json::json!(1));

    let restored: OfficeSessionTrackedSyncReceipt = serde_json::from_value(value).unwrap();

    assert_eq!(restored, receipt);

    let snapshot = tracker.last_snapshot().cloned();
    let err = tracker
        .mark_synced(
            &mut sync_coordinator,
            &session,
            OfficeSyncCursor::document_start("counter", "doc-1"),
            11_000,
        )
        .unwrap_err();

    assert_eq!(
        err,
        OfficeSessionTrackedSyncReceiptError::Sync(OfficeSyncError::TargetSequenceBehindBase {
            base_sequence: 1,
            target_sequence: 0,
        })
    );
    assert_eq!(tracker.last_snapshot().cloned(), snapshot);
}

#[test]
fn session_status_tracker_applies_remote_batch_and_reports_delta() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let mut tracker = OfficeSessionStatusTracker::all_events();

    tracker.poll(&session).unwrap();

    let batch = OfficeOperationBatch::new(
        OfficeSyncCursor::document_start("counter", "doc-1"),
        OfficeSyncCursor::new("counter", "doc-1", 2),
        vec![
            operation_with_id("remote-op-1", 1, TestEdit::Add(5)),
            operation_with_id("remote-op-2", 2, TestEdit::Set(9)),
        ],
    );
    let result = tracker.apply_remote_batch(&mut session, batch).unwrap();

    assert_eq!(result.remote_batch.operation_outcomes, vec![5, 9]);
    assert_eq!(
        result.remote_batch.base,
        OfficeSyncCursor::document_start("counter", "doc-1")
    );
    assert_eq!(
        result.remote_batch.target,
        OfficeSyncCursor::new("counter", "doc-1", 2)
    );
    assert_eq!(result.remote_batch.operation_count, 2);
    assert!(result.sequence_changed());
    assert!(result.has_incremental_changes());
    assert_eq!(session.state().value, 9);
    assert_eq!(session.sequence(), 2);
    assert_eq!(session.history().committed_len(), 0);

    let delta = result.status.delta.as_ref().unwrap();

    assert!(delta.has_changed(OfficeSessionStatusField::Sequence));
    assert!(delta.has_changed(OfficeSessionStatusField::PendingOperations));
    assert!(delta.has_changed(OfficeSessionStatusField::Events));
    assert!(delta
        .command_delta
        .was_enabled(OfficeSessionCommand::SyncPendingChanges));
    assert_eq!(result.status.update.events.batch.len(), 3);

    let value = serde_json::to_value(&result).unwrap();

    assert_eq!(
        value["remote_batch"]["operation_count"],
        serde_json::json!(2)
    );
    assert_eq!(
        value["remote_batch"]["operation_outcomes"],
        serde_json::json!([5, 9])
    );

    let restored: OfficeSessionTrackedRemoteBatchResult<i64> =
        serde_json::from_value(value).unwrap();

    assert_eq!(restored, result);
}

#[test]
fn session_status_tracker_reports_remote_batch_errors_without_polling_status() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    let mut tracker = OfficeSessionStatusTracker::all_events();
    let initial = tracker.poll(&session).unwrap();

    let stale_batch = OfficeOperationBatch::new(
        OfficeSyncCursor::document_start("counter", "doc-1"),
        OfficeSyncCursor::new("counter", "doc-1", 2),
        vec![operation_with_id("remote-op-2", 2, TestEdit::Set(9))],
    );
    let err = tracker
        .apply_remote_batch(&mut session, stale_batch)
        .unwrap_err();

    match err {
        OfficeSessionTrackedRemoteBatchError::RemoteBatch(OfficeSessionError::Sync(
            OfficeSyncError::BatchBaseMismatch { expected, actual },
        )) => {
            assert_eq!(expected, OfficeSyncCursor::new("counter", "doc-1", 1));
            assert_eq!(actual, OfficeSyncCursor::document_start("counter", "doc-1"));
        }
        _ => panic!("expected tracked remote batch base mismatch"),
    }
    assert_eq!(tracker.last_snapshot(), Some(initial.snapshot()));
    assert_eq!(session.state().value, 5);
    assert_eq!(session.sequence(), 1);
}

#[test]
fn session_status_observer_resyncs_event_cursor_after_retention() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 1_500);
    session
        .apply_operation(operation(2, TestEdit::Add(8)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(8)), 2_500);
    session.prune_events(&OfficeSessionEventRetentionPolicy::max_events(2));

    let mut observer = OfficeSessionStatusObserver::all_events();
    let update = observer.poll(&session).unwrap();

    assert!(update.event_cursor_was_reset());
    assert_eq!(
        update.events.reset_cursor,
        Some(OfficeSessionEventCursor::new(2))
    );
    assert_eq!(
        update.events.batch.base_cursor,
        OfficeSessionEventCursor::new(2)
    );
    assert_eq!(
        update.events.batch.next_cursor,
        OfficeSessionEventCursor::new(4)
    );
    assert_eq!(update.events.batch.len(), 2);
    assert_eq!(observer.event_cursor(), OfficeSessionEventCursor::new(4));
    assert_eq!(update.snapshot.diagnostics.event_pruned_through_index, 2);
    assert!(update
        .snapshot
        .signal
        .has_flag(OfficeSessionDiagnosticFlag::EventQueuePruned));
}

#[test]
fn session_prunes_only_saved_operations_from_operation_log() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    session
        .apply_operation(operation(2, TestEdit::Add(4)))
        .unwrap();
    session.mark_saved(2_000);
    session
        .apply_operation(operation(3, TestEdit::Add(1)))
        .unwrap();

    let report = session.prune_saved_operations_through(3);

    assert_eq!(
        report,
        OfficeSessionLogPruneReport {
            document_id: DocumentId::new("doc-1"),
            requested_sequence: 3,
            pruned_through_sequence: 2,
            original_operation_count: 3,
            retained_operation_count: 1,
            pruned_operation_count: 2,
            retained_sequence_range: Some((3, 3)),
        }
    );
    assert!(report.pruned_operations());
    assert_eq!(session.sequence(), 3);
    assert_eq!(session.operation_log_pruned_through_sequence(), 2);
    assert_eq!(session.operation_log().len(), 1);
    assert_eq!(session.operation_log().operations[0].sequence, 3);
    assert_eq!(session.dirty_sequence_range(), Some((3, 3)));
    assert_eq!(session.pending_operation_count(), 1);
    assert!(matches!(
        &session.events().last().unwrap().kind,
        OfficeSessionEventKind::OperationLogPruned {
            pruned_through_sequence,
            pruned_operation_count,
            retained_operation_count,
            retained_sequence_range,
        } if *pruned_through_sequence == 2
            && *pruned_operation_count == 2
            && *retained_operation_count == 1
            && *retained_sequence_range == Some((3, 3))
    ));
}

#[test]
fn session_autosave_policy_skips_clean_sessions() {
    let session = OfficeDocumentSession::<CounterState, TestEdit>::new(
        "counter",
        "doc-1",
        CounterState::default(),
    );
    let policy = OfficeAutosavePolicy::immediate();

    assert_eq!(session.pending_operation_count(), 0);
    assert_eq!(
        session.autosave_decision(&policy, 1_000),
        OfficeAutosaveDecision::Skip(OfficeAutosaveSkipReason::Clean)
    );
    assert!(!session.should_autosave(&policy, 1_000));
}

#[test]
fn session_autosave_policy_waits_for_idle_window() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let policy = OfficeAutosavePolicy::default()
        .with_min_interval_ms(0)
        .with_idle_after_ms(500)
        .with_max_pending_operations(10);

    assert_eq!(
        session.autosave_decision(&policy, 1_200),
        OfficeAutosaveDecision::Skip(OfficeAutosaveSkipReason::WaitingForIdle {
            elapsed_ms: 199,
            required_ms: 500,
        })
    );

    let decision = session.autosave_decision(&policy, 1_600);

    assert!(decision.should_save());
    assert_eq!(
        decision.save_request().unwrap(),
        &OfficeAutosaveRequest {
            reason: OfficeAutosaveReason::Idle,
            dirty_sequence_range: (1, 1),
            pending_operation_count: 1,
            elapsed_since_save_ms: 1_600,
            elapsed_since_edit_ms: 599,
        }
    );
}

#[test]
fn session_autosave_policy_respects_min_save_interval() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let policy = OfficeAutosavePolicy::default()
        .with_min_interval_ms(5_000)
        .with_idle_after_ms(0)
        .with_max_pending_operations(10);

    assert_eq!(
        session.autosave_decision(&policy, 2_000),
        OfficeAutosaveDecision::Skip(OfficeAutosaveSkipReason::WaitingForSaveInterval {
            elapsed_ms: 2_000,
            required_ms: 5_000,
        })
    );
    assert!(session.should_autosave(&policy, 5_000));
}

#[test]
fn session_autosave_policy_saves_when_pending_operation_limit_is_reached() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    session
        .apply_operation(operation(2, TestEdit::Add(4)))
        .unwrap();
    let policy = OfficeAutosavePolicy::default()
        .with_min_interval_ms(60_000)
        .with_idle_after_ms(60_000)
        .with_max_pending_operations(2);

    let decision = session.autosave_decision(&policy, 1_003);

    assert_eq!(session.pending_operation_count(), 2);
    assert_eq!(
        decision.save_request().unwrap(),
        &OfficeAutosaveRequest {
            reason: OfficeAutosaveReason::PendingOperationLimit,
            dirty_sequence_range: (1, 2),
            pending_operation_count: 2,
            elapsed_since_save_ms: 1_003,
            elapsed_since_edit_ms: 1,
        }
    );
}

#[test]
fn save_coordinator_saves_dirty_session_and_updates_status() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let mut coordinator = OfficeSaveCoordinator::for_session(&session);

    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Clean {
            sequence: 0,
            timestamp_ms: 0,
        }
    );

    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();

    assert_eq!(
        coordinator.refresh_from_session(&session),
        &OfficeSaveState::Dirty {
            sequence: 1,
            pending_operation_count: 1,
        }
    );

    let mut store = InMemoryOfficeStore::new();
    let outcome = coordinator.save_now(&mut session, &mut store, 9_000);

    assert!(outcome.is_saved());
    assert_eq!(
        outcome.receipt().unwrap(),
        &OfficeSaveReceipt {
            trigger: OfficeSaveTrigger::Manual,
            sequence: 1,
            timestamp_ms: 9_000,
            dirty_sequence_range: Some((1, 1)),
            pending_operation_count: 1,
        }
    );
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Saved {
            sequence: 1,
            timestamp_ms: 9_000,
        }
    );
    assert!(!session.is_dirty());
    assert!(matches!(
        &session.events()[1].kind,
        OfficeSessionEventKind::DocumentSaved {
            sequence,
            timestamp_ms,
            operation_count,
            persist_mode,
        } if *sequence == 1
            && *timestamp_ms == 9_000
            && *operation_count == 1
            && *persist_mode == crate::OfficeDocumentPersistMode::Atomic
    ));

    let snapshot = store
        .load_snapshot(&DocumentId::new("doc-1"))
        .unwrap()
        .unwrap();
    assert_eq!(snapshot.sequence, 1);
    assert_eq!(snapshot.timestamp_ms, 9_000);
}

#[test]
fn save_coordinator_skips_clean_manual_save() {
    let mut session = OfficeDocumentSession::<CounterState, TestEdit>::new(
        "counter",
        "doc-1",
        CounterState::default(),
    );
    let mut coordinator = OfficeSaveCoordinator::for_session(&session);
    let mut store = InMemoryOfficeStore::new();

    let outcome = coordinator.save_now(&mut session, &mut store, 9_000);

    assert!(outcome.is_skipped());
    assert_eq!(
        outcome.skip().unwrap(),
        &OfficeSaveSkip {
            trigger: Some(OfficeSaveTrigger::Manual),
            reason: OfficeSaveSkipReason::Clean,
            sequence: 0,
            timestamp_ms: 9_000,
        }
    );
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Clean {
            sequence: 0,
            timestamp_ms: 0,
        }
    );
    assert!(matches!(
        &session.events().last().unwrap().kind,
        OfficeSessionEventKind::SaveSkipped {
            trigger: Some(OfficeSaveTrigger::Manual),
            reason: OfficeSaveSkipReason::Clean,
        }
    ));
}

#[test]
fn save_coordinator_runs_autosave_when_policy_requests_save() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut coordinator = OfficeSaveCoordinator::for_session(&session);
    let mut store = InMemoryOfficeStore::new();
    let policy = OfficeAutosavePolicy::default()
        .with_min_interval_ms(0)
        .with_idle_after_ms(0)
        .with_max_pending_operations(10);

    let outcome = coordinator.autosave_if_needed(&mut session, &mut store, &policy, 9_000);

    assert_eq!(
        outcome.receipt().unwrap(),
        &OfficeSaveReceipt {
            trigger: OfficeSaveTrigger::Autosave(OfficeAutosaveReason::Idle),
            sequence: 1,
            timestamp_ms: 9_000,
            dirty_sequence_range: Some((1, 1)),
            pending_operation_count: 1,
        }
    );
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Saved {
            sequence: 1,
            timestamp_ms: 9_000,
        }
    );
    assert!(!session.is_dirty());
}

#[test]
fn save_coordinator_keeps_dirty_status_when_autosave_skips() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut coordinator = OfficeSaveCoordinator::for_session(&session);
    let mut store = InMemoryOfficeStore::new();

    let outcome = coordinator.autosave_if_needed(
        &mut session,
        &mut store,
        &OfficeAutosavePolicy::disabled(),
        9_000,
    );

    assert!(outcome.is_skipped());
    assert_eq!(
        outcome.skip().unwrap(),
        &OfficeSaveSkip {
            trigger: None,
            reason: OfficeSaveSkipReason::Autosave(OfficeAutosaveSkipReason::Disabled),
            sequence: 1,
            timestamp_ms: 9_000,
        }
    );
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Dirty {
            sequence: 1,
            pending_operation_count: 1,
        }
    );
    assert!(session.is_dirty());
    assert!(matches!(
        &session.events().last().unwrap().kind,
        OfficeSessionEventKind::SaveSkipped {
            trigger: None,
            reason: OfficeSaveSkipReason::Autosave(OfficeAutosaveSkipReason::Disabled),
        }
    ));
}

#[test]
fn save_coordinator_preserves_dirty_state_after_failure_and_allows_retry() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut coordinator = OfficeSaveCoordinator::for_session(&session);
    let mut failing_store = FailingSaveStore;

    let failed = coordinator.save_now(&mut session, &mut failing_store, 9_000);

    assert!(failed.is_failed());
    assert_eq!(
        failed.failure().unwrap(),
        &OfficeSaveFailure {
            trigger: OfficeSaveTrigger::Manual,
            sequence: 1,
            timestamp_ms: 9_000,
            dirty_sequence_range: Some((1, 1)),
            pending_operation_count: 1,
            error: SaveTestError::OperationLogWriteFailed,
        }
    );
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Failed {
            sequence: 1,
            pending_operation_count: 1,
        }
    );
    assert!(session.is_dirty());

    let mut store = InMemoryOfficeStore::new();
    let retry = coordinator.save_now(&mut session, &mut store, 10_000);

    assert!(retry.is_saved());
    assert_eq!(
        coordinator.status(),
        &OfficeSaveState::Saved {
            sequence: 1,
            timestamp_ms: 10_000,
        }
    );
    assert!(!session.is_dirty());
}

#[test]
fn recovery_replays_operation_log_after_snapshot_and_marks_clean_by_default() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 1, 1_001, CounterState { value: 8 })
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        operation(2, TestEdit::Add(4)),
        operation(3, TestEdit::Add(1)),
    ]);

    let recovered = recover_session_from_snapshot_and_log(
        snapshot,
        operation_log,
        OfficeRecoveryPolicy::default(),
    )
    .unwrap();

    assert_eq!(recovered.session.state().value, 13);
    assert_eq!(recovered.session.sequence(), 3);
    assert_eq!(recovered.session.operation_log().len(), 3);
    assert!(!recovered.session.is_dirty());
    assert_eq!(recovered.session.events().len(), 1);
    assert!(matches!(
        &recovered.session.events()[0].kind,
        OfficeSessionEventKind::RecoveryCompleted {
            snapshot_sequence,
            recovered_sequence,
            replayed_operation_count,
        } if *snapshot_sequence == 1 && *recovered_sequence == 3 && *replayed_operation_count == 2
    ));
    assert_eq!(
        recovered.session.save_checkpoint(),
        &OfficeSessionCheckpoint::new(3, 1_003)
    );
    assert_eq!(
        recovered.report,
        OfficeRecoveryReport {
            snapshot_sequence: 1,
            recovered_sequence: 3,
            baseline_operation_count: 1,
            replayed_operation_count: 2,
            latest_replayed_timestamp_ms: Some(1_003),
            save_checkpoint: OfficeSessionCheckpoint::new(3, 1_003),
        }
    );
    assert_eq!(recovered.report.replayed_sequence_range(), Some((2, 3)));
    assert!(recovered.report.replayed_operations());
}

#[test]
fn recovery_can_keep_replayed_operations_dirty_for_snapshot_compaction() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 1, 1_001, CounterState { value: 8 })
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        operation(2, TestEdit::Add(4)),
    ]);

    let recovered = recover_session_from_snapshot_and_log(
        snapshot,
        operation_log,
        OfficeRecoveryPolicy::keep_replayed_operations_dirty(),
    )
    .unwrap();

    assert_eq!(recovered.session.state().value, 12);
    assert_eq!(recovered.session.sequence(), 2);
    assert!(recovered.session.is_dirty());
    assert_eq!(recovered.session.dirty_sequence_range(), Some((2, 2)));
    assert_eq!(
        recovered.report.save_checkpoint,
        OfficeSessionCheckpoint::new(1, 1_001)
    );
    assert_eq!(recovered.report.replayed_sequence_range(), Some((2, 2)));
}

#[test]
fn recovery_rejects_invalid_snapshot_before_replay() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 0, 1_000, CounterState::default())
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));

    let err = recover_session_from_snapshot_and_log(
        snapshot,
        OperationLog::new(),
        OfficeRecoveryPolicy::default(),
    )
    .unwrap_err();

    match err {
        OfficeSessionError::Validation(report) => {
            assert!(report.issues().iter().any(|issue| {
                issue.code == "snapshot.operation.sequence_after_snapshot"
                    && issue.path.as_deref() == Some("operation_log.operations[0]")
            }));
        }
        _ => panic!("expected snapshot validation error"),
    }
}

#[test]
fn recovery_rejects_operation_log_for_different_document() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 1, 1_001, CounterState { value: 8 })
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        OperationEnvelope::new(
            "counter",
            "op-2",
            "other-doc",
            "actor-1",
            2,
            1_002,
            TestEdit::Add(4),
        ),
    ]);

    let err = recover_session_from_snapshot_and_log(
        snapshot,
        operation_log,
        OfficeRecoveryPolicy::default(),
    )
    .unwrap_err();

    assert_eq!(
        err,
        OfficeSessionError::Sync(OfficeSyncError::OperationDocumentMismatch {
            sequence: 2,
            expected: DocumentId::new("doc-1"),
            actual: DocumentId::new("other-doc"),
        })
    );
}

#[test]
fn recovery_from_store_returns_none_when_snapshot_is_missing() {
    let store: InMemoryOfficeStore<CounterState, TestEdit> = InMemoryOfficeStore::new();

    let recovered = recover_session_from_store(
        &store,
        &DocumentId::new("doc-1"),
        OfficeRecoveryPolicy::default(),
    )
    .unwrap();

    assert!(recovered.is_none());
}

#[test]
fn recovery_from_store_replays_newer_operation_log() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 1, 1_001, CounterState { value: 8 })
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        operation(2, TestEdit::Add(4)),
    ]);
    let mut store = InMemoryOfficeStore::new();
    store.save_snapshot(snapshot).unwrap();
    store
        .save_operation_log(DocumentId::new("doc-1"), operation_log)
        .unwrap();

    let recovered = recover_session_from_store(
        &store,
        &DocumentId::new("doc-1"),
        OfficeRecoveryPolicy::default(),
    )
    .unwrap()
    .unwrap();

    assert_eq!(recovered.session.state().value, 12);
    assert_eq!(recovered.session.sequence(), 2);
    assert_eq!(recovered.report.replayed_operation_count, 1);
    assert_eq!(recovered.report.replayed_sequence_range(), Some((2, 2)));
    assert!(!recovered.session.is_dirty());
}

#[test]
fn recovery_from_store_falls_back_to_snapshot_operation_log() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 1, 1_001, CounterState { value: 8 })
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));
    let mut store = InMemoryOfficeStore::new();
    store.save_snapshot(snapshot).unwrap();
    store
        .delete_operation_log(&DocumentId::new("doc-1"))
        .unwrap();

    let recovered = recover_session_from_store(
        &store,
        &DocumentId::new("doc-1"),
        OfficeRecoveryPolicy::default(),
    )
    .unwrap()
    .unwrap();

    assert_eq!(recovered.session.state().value, 8);
    assert_eq!(recovered.session.sequence(), 1);
    assert_eq!(recovered.report.baseline_operation_count, 1);
    assert_eq!(recovered.report.replayed_operation_count, 0);
    assert_eq!(recovered.report.replayed_sequence_range(), None);
}

#[test]
fn recovery_from_store_preserves_store_errors() {
    let store = FailingLoadStore;

    let err = recover_session_from_store(
        &store,
        &DocumentId::new("doc-1"),
        OfficeRecoveryPolicy::default(),
    )
    .unwrap_err();

    assert_eq!(
        err,
        OfficeRecoveryStoreError::Store(SaveTestError::SnapshotLoadFailed)
    );
}

#[test]
fn compaction_prunes_operations_at_or_before_snapshot_sequence() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 2, 1_002, CounterState { value: 12 })
        .with_operation_log(OperationLog::from_operations(vec![
            operation(1, TestEdit::Add(8)),
            operation(2, TestEdit::Add(4)),
        ]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        operation(2, TestEdit::Add(4)),
        operation(3, TestEdit::Add(1)),
    ]);

    let compacted =
        compact_snapshot_and_log(snapshot, operation_log, OfficeCompactionPolicy::default())
            .unwrap();

    assert_eq!(compacted.snapshot.operation_log.len(), 0);
    assert_eq!(compacted.operation_log.len(), 1);
    assert_eq!(compacted.operation_log.operations[0].sequence, 3);
    assert_eq!(
        compacted.report,
        OfficeCompactionReport {
            document_id: DocumentId::new("doc-1"),
            snapshot_sequence: 2,
            original_operation_count: 3,
            retained_operation_count: 1,
            removed_operation_count: 2,
            snapshot_operation_count: 0,
            retained_sequence_range: Some((3, 3)),
        }
    );
    assert!(compacted.report.removed_operations());
    assert!(compacted.report.compacted_operations());
    assert!(compacted.report.retained_operations());

    let recovered = recover_session_from_snapshot_and_log(
        compacted.snapshot,
        compacted.operation_log,
        OfficeRecoveryPolicy::default(),
    )
    .unwrap();

    assert_eq!(recovered.session.state().value, 13);
    assert_eq!(recovered.session.sequence(), 3);
    assert!(!recovered.session.is_dirty());
}

#[test]
fn compaction_policy_can_retain_snapshot_operation_log() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 2, 1_002, CounterState { value: 12 })
        .with_operation_log(OperationLog::from_operations(vec![
            operation(1, TestEdit::Add(8)),
            operation(2, TestEdit::Add(4)),
        ]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        operation(2, TestEdit::Add(4)),
    ]);

    let compacted = compact_snapshot_and_log(
        snapshot,
        operation_log,
        OfficeCompactionPolicy::retain_snapshot_operation_log(),
    )
    .unwrap();

    assert_eq!(compacted.snapshot.operation_log.len(), 2);
    assert!(compacted.operation_log.is_empty());
    assert_eq!(compacted.report.snapshot_operation_count, 2);
    assert_eq!(compacted.report.retained_sequence_range, None);
    assert!(!compacted.report.retained_operations());
}

#[test]
fn compaction_rejects_operation_log_for_different_document() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 1, 1_001, CounterState { value: 8 })
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        OperationEnvelope::new(
            "counter",
            "op-2",
            "other-doc",
            "actor-1",
            2,
            1_002,
            TestEdit::Add(4),
        ),
    ]);

    let err = compact_snapshot_and_log(snapshot, operation_log, OfficeCompactionPolicy::default())
        .unwrap_err();

    assert_eq!(
        err,
        OfficeCompactionError::Sync(OfficeSyncError::OperationDocumentMismatch {
            sequence: 2,
            expected: DocumentId::new("doc-1"),
            actual: DocumentId::new("other-doc"),
        })
    );
}

#[test]
fn compaction_in_store_saves_compacted_snapshot_and_log() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 2, 1_002, CounterState { value: 12 })
        .with_operation_log(OperationLog::from_operations(vec![
            operation(1, TestEdit::Add(8)),
            operation(2, TestEdit::Add(4)),
        ]));
    let operation_log = OperationLog::from_operations(vec![
        operation(1, TestEdit::Add(8)),
        operation(2, TestEdit::Add(4)),
        operation(3, TestEdit::Add(1)),
    ]);
    let document_id = DocumentId::new("doc-1");
    let mut store = InMemoryOfficeStore::new();
    store.save_snapshot(snapshot).unwrap();
    store
        .save_operation_log(document_id.clone(), operation_log)
        .unwrap();

    let report =
        compact_document_in_store(&mut store, &document_id, OfficeCompactionPolicy::default())
            .unwrap()
            .unwrap();

    assert_eq!(report.removed_operation_count, 2);
    assert_eq!(report.retained_sequence_range, Some((3, 3)));
    let stored_snapshot = store.load_snapshot(&document_id).unwrap().unwrap();
    let stored_operation_log = store.load_operation_log(&document_id).unwrap().unwrap();
    assert_eq!(stored_snapshot.operation_log.len(), 0);
    assert_eq!(stored_operation_log.len(), 1);
    assert_eq!(stored_operation_log.operations[0].sequence, 3);

    let recovered =
        recover_session_from_store(&store, &document_id, OfficeRecoveryPolicy::default())
            .unwrap()
            .unwrap();
    assert_eq!(recovered.session.state().value, 13);
    assert_eq!(recovered.session.sequence(), 3);
    assert_eq!(recovered.report.replayed_sequence_range(), Some((3, 3)));
}

#[test]
fn compaction_in_store_returns_none_when_snapshot_is_missing() {
    let mut store: InMemoryOfficeStore<CounterState, TestEdit> = InMemoryOfficeStore::new();

    let report = compact_document_in_store(
        &mut store,
        &DocumentId::new("doc-1"),
        OfficeCompactionPolicy::default(),
    )
    .unwrap();

    assert!(report.is_none());
}

#[test]
fn maintenance_profiles_resolve_to_reusable_policy_presets() {
    assert_eq!(
        OfficeMaintenanceProfile::InteractiveEditor.policy(),
        OfficeMaintenancePolicy::interactive_editor()
    );
    assert_eq!(
        OfficeMaintenancePolicy::from_profile(OfficeMaintenanceProfile::LargeDocument),
        OfficeMaintenancePolicy::large_document()
    );

    let interactive = OfficeMaintenancePolicy::interactive_editor();
    assert!(interactive.compact_after_save);
    assert_eq!(interactive.autosave_policy.idle_after_ms, 2_000);
    assert_eq!(interactive.autosave_policy.min_interval_ms, 15_000);
    assert_eq!(interactive.autosave_policy.max_pending_operations, 25);
    assert_eq!(interactive.min_operations_before_compaction, 250);

    let large = OfficeMaintenancePolicy::large_document();
    assert!(large.compact_after_save);
    assert_eq!(large.autosave_policy.idle_after_ms, 3_000);
    assert_eq!(large.autosave_policy.min_interval_ms, 20_000);
    assert_eq!(large.autosave_policy.max_pending_operations, 40);
    assert_eq!(large.min_operations_before_compaction, 75);

    let low_memory = OfficeMaintenancePolicy::low_memory_device();
    assert!(low_memory.compact_after_save);
    assert_eq!(low_memory.autosave_policy.idle_after_ms, 1_000);
    assert_eq!(low_memory.autosave_policy.min_interval_ms, 5_000);
    assert_eq!(low_memory.autosave_policy.max_pending_operations, 10);
    assert_eq!(low_memory.min_operations_before_compaction, 25);

    let collaborative = OfficeMaintenancePolicy::collaborative_session();
    assert!(collaborative.compact_after_save);
    assert_eq!(collaborative.autosave_policy.idle_after_ms, 500);
    assert_eq!(collaborative.autosave_policy.min_interval_ms, 3_000);
    assert_eq!(collaborative.autosave_policy.max_pending_operations, 5);
    assert_eq!(collaborative.min_operations_before_compaction, 1_000);
}

#[test]
fn maintenance_profile_serializes_as_stable_settings_value() {
    let json = serde_json::to_string(&OfficeMaintenanceProfile::LowMemoryDevice).unwrap();
    let restored: OfficeMaintenanceProfile = serde_json::from_str(&json).unwrap();

    assert_eq!(json, "\"low_memory_device\"");
    assert_eq!(restored, OfficeMaintenanceProfile::LowMemoryDevice);
    assert_eq!(
        restored.policy(),
        OfficeMaintenancePolicy::low_memory_device()
    );
}

#[test]
fn maintenance_save_compacts_after_success_when_enabled() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    session
        .apply_operation(operation(2, TestEdit::Add(4)))
        .unwrap();
    let mut store = InMemoryOfficeStore::new();
    let policy =
        OfficeMaintenancePolicy::autosave_and_compact().with_min_operations_before_compaction(1);
    let mut coordinator = OfficeMaintenanceCoordinator::for_session(&session);

    let outcome = coordinator.save_now(&mut session, &mut store, &policy, 9_000);

    assert!(outcome.is_saved());
    assert!(outcome.compacted());
    assert!(!session.is_dirty());
    assert_eq!(
        coordinator.save_status(),
        &OfficeSaveState::Saved {
            sequence: 2,
            timestamp_ms: 9_000,
        }
    );
    match &outcome.compaction {
        OfficeMaintenanceCompactionOutcome::Compacted(receipt) => {
            let report = &receipt.persistence;
            assert_eq!(report.snapshot_sequence, 2);
            assert_eq!(report.original_operation_count, 2);
            assert_eq!(report.removed_operation_count, 2);
            assert_eq!(report.retained_operation_count, 0);
            assert!(receipt.pruned_session_log());
            assert_eq!(
                receipt.session_log_prune,
                OfficeSessionLogPruneReport {
                    document_id: DocumentId::new("doc-1"),
                    requested_sequence: 2,
                    pruned_through_sequence: 2,
                    original_operation_count: 2,
                    retained_operation_count: 0,
                    pruned_operation_count: 2,
                    retained_sequence_range: None,
                }
            );
        }
        _ => panic!("expected compaction report"),
    }
    assert_eq!(session.operation_log().len(), 0);
    assert!(matches!(
        &session.events()[4].kind,
        OfficeSessionEventKind::OperationLogPruned {
            pruned_through_sequence,
            pruned_operation_count,
            retained_operation_count,
            retained_sequence_range,
        } if *pruned_through_sequence == 2
            && *pruned_operation_count == 2
            && *retained_operation_count == 0
            && *retained_sequence_range == None
    ));
    assert!(matches!(
        &session.events()[5].kind,
        OfficeSessionEventKind::CompactionCompleted {
            snapshot_sequence,
            removed_operation_count,
            retained_operation_count,
            retained_sequence_range,
        } if *snapshot_sequence == 2
            && *removed_operation_count == 2
            && *retained_operation_count == 0
            && *retained_sequence_range == None
    ));

    let document_id = DocumentId::new("doc-1");
    let stored_snapshot = store.load_snapshot(&document_id).unwrap().unwrap();
    let stored_operation_log = store.load_operation_log(&document_id).unwrap().unwrap();
    assert_eq!(stored_snapshot.sequence, 2);
    assert_eq!(stored_snapshot.state.value, 12);
    assert_eq!(stored_snapshot.operation_log.len(), 0);
    assert_eq!(stored_operation_log.len(), 0);

    let recovered =
        recover_session_from_store(&store, &document_id, OfficeRecoveryPolicy::default())
            .unwrap()
            .unwrap();
    assert_eq!(recovered.session.state().value, 12);
    assert_eq!(recovered.session.sequence(), 2);
    assert_eq!(recovered.report.replayed_operation_count, 0);
}

#[test]
fn maintenance_compacted_recovery_resumes_sync_from_retained_floor() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    session
        .apply_operation(operation(2, TestEdit::Add(4)))
        .unwrap();
    session
        .apply_operation(operation(3, TestEdit::Add(1)))
        .unwrap();
    let mut store = InMemoryOfficeStore::new();
    let policy =
        OfficeMaintenancePolicy::autosave_and_compact().with_min_operations_before_compaction(1);
    let mut coordinator = OfficeMaintenanceCoordinator::for_session(&session);

    let outcome = coordinator.save_now(&mut session, &mut store, &policy, 9_000);

    assert!(outcome.is_saved());
    assert!(outcome.compacted());
    assert_eq!(session.state().value, 13);
    assert_eq!(session.operation_log().len(), 0);
    assert_eq!(session.operation_log_pruned_through_sequence(), 3);

    let document_id = DocumentId::new("doc-1");
    let mut recovered =
        recover_session_from_store(&store, &document_id, OfficeRecoveryPolicy::default())
            .unwrap()
            .unwrap();

    assert_eq!(recovered.session.state().value, 13);
    assert_eq!(recovered.session.sequence(), 3);
    assert_eq!(recovered.session.operation_log().len(), 0);
    assert_eq!(recovered.session.operation_log_pruned_through_sequence(), 3);
    assert_eq!(recovered.report.snapshot_sequence, 3);
    assert_eq!(recovered.report.replayed_operation_count, 0);

    let stale = recovered
        .session
        .operations_after(OfficeSyncCursor::new("counter", "doc-1", 0))
        .unwrap_err();
    assert_eq!(
        stale,
        OfficeSyncError::OperationLogCompacted {
            requested_sequence: 0,
            available_after_sequence: 3,
        }
    );

    recovered
        .session
        .apply_operation(operation(4, TestEdit::Add(2)))
        .unwrap();
    let batch = recovered
        .session
        .operations_after(OfficeSyncCursor::new("counter", "doc-1", 3))
        .unwrap();

    assert_eq!(recovered.session.state().value, 15);
    assert_eq!(batch.base, OfficeSyncCursor::new("counter", "doc-1", 3));
    assert_eq!(batch.target, OfficeSyncCursor::new("counter", "doc-1", 4));
    assert_eq!(batch.len(), 1);
    assert_eq!(batch.operations[0].sequence, 4);
}

#[test]
fn maintenance_autosave_skip_does_not_compact() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut store = InMemoryOfficeStore::new();
    let policy = OfficeMaintenancePolicy::autosave_and_compact()
        .with_autosave_policy(OfficeAutosavePolicy::disabled())
        .with_min_operations_before_compaction(1);
    let mut coordinator = OfficeMaintenanceCoordinator::for_session(&session);

    let outcome = coordinator.autosave_if_needed(&mut session, &mut store, &policy, 9_000);

    assert!(outcome.save.is_skipped());
    match &outcome.compaction {
        OfficeMaintenanceCompactionOutcome::Skipped(skip) => {
            assert_eq!(
                skip.reason,
                OfficeMaintenanceCompactionSkipReason::SaveDidNotPersist
            );
            assert_eq!(skip.sequence, 1);
        }
        _ => panic!("expected compaction skip"),
    }
    assert_eq!(session.operation_log().len(), 1);
    assert!(!store.contains_snapshot(&DocumentId::new("doc-1")));
    assert!(!store.contains_operation_log(&DocumentId::new("doc-1")));
}

#[test]
fn maintenance_respects_compaction_operation_threshold() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut store = InMemoryOfficeStore::new();
    let policy =
        OfficeMaintenancePolicy::autosave_and_compact().with_min_operations_before_compaction(2);
    let mut coordinator = OfficeMaintenanceCoordinator::for_session(&session);

    let outcome = coordinator.save_now(&mut session, &mut store, &policy, 9_000);

    assert!(outcome.is_saved());
    match &outcome.compaction {
        OfficeMaintenanceCompactionOutcome::Skipped(skip) => {
            assert_eq!(
                skip.reason,
                OfficeMaintenanceCompactionSkipReason::OperationThresholdNotReached {
                    operation_count: 1,
                    required_count: 2,
                }
            );
        }
        _ => panic!("expected compaction threshold skip"),
    }
    let document_id = DocumentId::new("doc-1");
    let stored_snapshot = store.load_snapshot(&document_id).unwrap().unwrap();
    let stored_operation_log = store.load_operation_log(&document_id).unwrap().unwrap();
    assert_eq!(session.operation_log().len(), 1);
    assert_eq!(stored_snapshot.operation_log.len(), 1);
    assert_eq!(stored_operation_log.len(), 1);
}

#[test]
fn maintenance_collaborative_profile_saves_without_eager_compaction() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    for sequence in 1..=5 {
        session
            .apply_operation(operation(sequence, TestEdit::Add(1)))
            .unwrap();
    }
    let mut store = InMemoryOfficeStore::new();
    let policy = OfficeMaintenancePolicy::collaborative_session();
    let mut coordinator = OfficeMaintenanceCoordinator::for_session(&session);

    let outcome = coordinator.save_now(&mut session, &mut store, &policy, 9_000);

    assert!(outcome.is_saved());
    match &outcome.compaction {
        OfficeMaintenanceCompactionOutcome::Skipped(skip) => {
            assert_eq!(
                skip.reason,
                OfficeMaintenanceCompactionSkipReason::OperationThresholdNotReached {
                    operation_count: 5,
                    required_count: 1_000,
                }
            );
        }
        _ => panic!("expected collaborative threshold skip"),
    }
    assert_eq!(session.operation_log().len(), 5);
    assert_eq!(session.operation_log_pruned_through_sequence(), 0);
}

#[test]
fn session_loads_from_snapshot_store() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(3)), 2_000);
    let mut store = InMemoryOfficeStore::new();
    session.persist_to(&mut store, 9_000).unwrap();

    let restored = OfficeDocumentSession::<CounterState, TestEdit>::load_from_store(
        &store,
        &DocumentId::new("doc-1"),
    )
    .unwrap()
    .unwrap();

    assert_eq!(restored.engine().as_str(), "counter");
    assert_eq!(restored.document_id().as_str(), "doc-1");
    assert_eq!(restored.state().value, 8);
    assert_eq!(restored.sequence(), 1);
    assert_eq!(restored.last_timestamp_ms(), 9_000);
    assert_eq!(
        restored.save_checkpoint(),
        &OfficeSessionCheckpoint::new(1, 9_000)
    );
    assert!(!restored.is_dirty());
    assert_eq!(restored.operation_log().len(), 1);
    assert_eq!(
        restored.selection(),
        &OfficeSelection::Text(TextSelection::caret(3))
    );
    assert_eq!(restored.history().committed_len(), 0);
    assert!(restored.events().is_empty());
}

#[test]
fn session_persist_and_mark_saved_updates_checkpoint() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut store = InMemoryOfficeStore::new();

    session
        .persist_and_mark_saved_to(&mut store, 9_000)
        .unwrap();

    assert!(!session.is_dirty());
    assert_eq!(
        session.save_checkpoint(),
        &OfficeSessionCheckpoint::new(1, 9_000)
    );
    assert!(matches!(
        &session.events().last().unwrap().kind,
        OfficeSessionEventKind::CheckpointSaved {
            sequence,
            timestamp_ms,
        } if *sequence == 1 && *timestamp_ms == 9_000
    ));

    let document_id = DocumentId::new("doc-1");
    let snapshot = store.load_snapshot(&document_id).unwrap().unwrap();
    assert_eq!(snapshot.sequence, 1);
    assert_eq!(snapshot.timestamp_ms, 9_000);
    assert_eq!(snapshot.state.value, 8);
}

#[test]
fn session_saves_operation_log_without_snapshot() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(8)))
        .unwrap();
    let mut store: InMemoryOfficeStore<CounterState, TestEdit> = InMemoryOfficeStore::new();

    session.save_operation_log_to(&mut store).unwrap();

    let document_id = DocumentId::new("doc-1");
    assert!(store.load_snapshot(&document_id).unwrap().is_none());
    let operation_log = store.load_operation_log(&document_id).unwrap().unwrap();
    assert_eq!(operation_log.len(), 1);
    assert_eq!(operation_log.operations[0].operation_id, "op-1");
}

#[test]
fn session_reports_sync_cursor_and_operations_after_cursor() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session
        .apply_operation(operation(2, TestEdit::Set(9)))
        .unwrap();

    assert_eq!(
        session.sync_cursor(),
        OfficeSyncCursor::new("counter", "doc-1", 2)
    );

    let batch = session
        .operations_after(OfficeSyncCursor::new("counter", "doc-1", 1))
        .unwrap();

    assert_eq!(batch.base, OfficeSyncCursor::new("counter", "doc-1", 1));
    assert_eq!(batch.target, OfficeSyncCursor::new("counter", "doc-1", 2));
    assert_eq!(batch.len(), 1);
    assert_eq!(batch.operations[0].operation_id, "op-2");
}

#[test]
fn sync_coordinator_prepares_pending_changes_and_acknowledges_target() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let mut coordinator = OfficeSyncCoordinator::document_start("counter", "doc-1");

    let empty = coordinator.prepare_pending_changes(&session, 1_000);

    assert!(empty.is_skipped());
    assert_eq!(
        empty.skip().unwrap(),
        &OfficeSyncSkip {
            reason: OfficeSyncSkipReason::UpToDate,
            cursor: OfficeSyncCursor::document_start("counter", "doc-1"),
            timestamp_ms: 1_000,
        }
    );
    assert_eq!(coordinator.status(), &OfficeSyncState::Idle);

    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session
        .apply_operation(operation(2, TestEdit::Set(9)))
        .unwrap();

    let prepared = coordinator.prepare_pending_changes(&session, 2_000);

    assert!(prepared.is_prepared());
    assert_eq!(prepared.prepared().unwrap().pending_operation_count, 2);
    assert_eq!(
        prepared.prepared().unwrap().batch.base,
        OfficeSyncCursor::document_start("counter", "doc-1")
    );
    assert_eq!(
        prepared.prepared().unwrap().batch.target,
        OfficeSyncCursor::new("counter", "doc-1", 2)
    );
    assert_eq!(
        coordinator.status(),
        &OfficeSyncState::Pending {
            target: OfficeSyncCursor::new("counter", "doc-1", 2),
            pending_operation_count: 2,
            timestamp_ms: 2_000,
        }
    );

    let value = serde_json::to_value(&prepared).unwrap();

    assert_eq!(value["outcome"], serde_json::json!("prepared"));

    let restored: OfficeSyncOutcome<TestEdit> = serde_json::from_value(value).unwrap();

    assert_eq!(restored, prepared);

    let receipt = coordinator
        .mark_synced(prepared.prepared().unwrap().batch.target.clone(), 3_000)
        .unwrap();

    assert_eq!(
        receipt,
        OfficeSyncReceipt {
            previous: OfficeSyncCursor::document_start("counter", "doc-1"),
            target: OfficeSyncCursor::new("counter", "doc-1", 2),
            acknowledged_sequence_count: 2,
            timestamp_ms: 3_000,
        }
    );
    assert_eq!(
        coordinator.acknowledged_cursor(),
        &OfficeSyncCursor::new("counter", "doc-1", 2)
    );
    assert_eq!(
        coordinator.status(),
        &OfficeSyncState::Synced {
            target: OfficeSyncCursor::new("counter", "doc-1", 2),
            acknowledged_sequence_count: 2,
            timestamp_ms: 3_000,
        }
    );

    let up_to_date = coordinator.prepare_pending_changes(&session, 4_000);

    assert!(up_to_date.is_skipped());
    assert_eq!(
        up_to_date.skip().unwrap().cursor,
        OfficeSyncCursor::new("counter", "doc-1", 2)
    );
}

#[test]
fn session_rejects_operations_after_cursor_before_pruned_log_floor() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session
        .apply_operation(operation(2, TestEdit::Set(9)))
        .unwrap();
    session.mark_saved(2_000);
    session
        .apply_operation(operation(3, TestEdit::Add(1)))
        .unwrap();
    session.prune_saved_operations_to_checkpoint();

    let stale = session
        .operations_after(OfficeSyncCursor::new("counter", "doc-1", 1))
        .unwrap_err();
    assert_eq!(
        stale,
        OfficeSyncError::OperationLogCompacted {
            requested_sequence: 1,
            available_after_sequence: 2,
        }
    );

    let available = session
        .operations_after(OfficeSyncCursor::new("counter", "doc-1", 2))
        .unwrap();
    assert_eq!(available.base, OfficeSyncCursor::new("counter", "doc-1", 2));
    assert_eq!(
        available.target,
        OfficeSyncCursor::new("counter", "doc-1", 3)
    );
    assert_eq!(available.len(), 1);
    assert_eq!(available.operations[0].sequence, 3);
}

#[test]
fn session_rejects_sync_cursor_for_other_document_or_future_sequence() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();

    let wrong_document = session
        .operations_after(OfficeSyncCursor::new("counter", "other-doc", 0))
        .unwrap_err();
    assert_eq!(
        wrong_document,
        OfficeSyncError::CursorDocumentMismatch {
            expected: "doc-1".into(),
            actual: "other-doc".into(),
        }
    );

    let ahead = session
        .operations_after(OfficeSyncCursor::new("counter", "doc-1", 5))
        .unwrap_err();
    assert_eq!(
        ahead,
        OfficeSyncError::TargetSequenceBehindBase {
            base_sequence: 5,
            target_sequence: 1,
        }
    );
}

#[test]
fn session_applies_remote_batch_without_committing_undo_history() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let batch = OfficeOperationBatch::new(
        OfficeSyncCursor::document_start("counter", "doc-1"),
        OfficeSyncCursor::new("counter", "doc-1", 2),
        vec![
            operation_with_id("remote-op-1", 1, TestEdit::Add(5)),
            operation_with_id("remote-op-2", 2, TestEdit::Set(9)),
        ],
    );

    let outcomes = session.apply_remote_batch(batch).unwrap();

    assert_eq!(outcomes, vec![5, 9]);
    assert_eq!(session.state().value, 9);
    assert_eq!(session.sequence(), 2);
    assert_eq!(session.last_timestamp_ms(), 1_002);
    assert_eq!(session.operation_log().len(), 2);
    assert_eq!(session.history().committed_len(), 0);
    assert!(!session.can_undo());
    assert_eq!(session.events().len(), 3);
    assert!(matches!(
        &session.events()[2].kind,
        OfficeSessionEventKind::RemoteBatchApplied {
            base_sequence,
            target_sequence,
            operation_count,
        } if *base_sequence == 0 && *target_sequence == 2 && *operation_count == 2
    ));
}

#[test]
fn session_rejects_remote_batch_with_stale_base_cursor() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    let batch = OfficeOperationBatch::new(
        OfficeSyncCursor::document_start("counter", "doc-1"),
        OfficeSyncCursor::new("counter", "doc-1", 2),
        vec![operation(2, TestEdit::Set(9))],
    );

    let err = session.apply_remote_batch(batch).unwrap_err();

    match err {
        OfficeSessionError::Sync(OfficeSyncError::BatchBaseMismatch { expected, actual }) => {
            assert_eq!(expected, OfficeSyncCursor::new("counter", "doc-1", 1));
            assert_eq!(actual, OfficeSyncCursor::new("counter", "doc-1", 0));
        }
        _ => panic!("expected sync base mismatch"),
    }
    assert_eq!(session.state().value, 5);
    assert_eq!(session.sequence(), 1);
    assert_eq!(session.operation_log().len(), 1);
}

#[test]
fn session_rejects_invalid_snapshot_during_hydration() {
    let snapshot = OfficeSnapshot::new("counter", "doc-1", 0, 2_000, CounterState::default())
        .with_operation_log(OperationLog::from_operations(vec![operation(
            1,
            TestEdit::Add(8),
        )]));

    let report = OfficeDocumentSession::try_from_snapshot(snapshot).unwrap_err();

    assert!(report.issues().iter().any(|issue| {
        issue.code == "snapshot.operation.sequence_after_snapshot"
            && issue.path.as_deref() == Some("operation_log.operations[0]")
    }));
}

#[test]
fn session_tracks_and_clears_selection() {
    let mut session: OfficeDocumentSession<CounterState, TestEdit> =
        OfficeDocumentSession::new("counter", "doc-1", CounterState::default()).with_selection(
            OfficeSelection::Grid(GridSelection::cell(GridPosition::new(1, 2))),
        );

    assert_eq!(
        session.selection(),
        &OfficeSelection::Grid(GridSelection::cell(GridPosition::new(1, 2)))
    );

    session.clear_selection();

    assert_eq!(session.selection(), &OfficeSelection::None);
}

#[test]
fn session_records_and_drains_selection_events() {
    let mut session: OfficeDocumentSession<CounterState, TestEdit> =
        OfficeDocumentSession::new("counter", "doc-1", CounterState::default());

    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 2_000);
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 2_001);

    assert_eq!(session.events().len(), 1);
    assert_eq!(session.events()[0].timestamp_ms, 2_000);
    assert_eq!(session.events()[0].sequence, 0);
    assert_eq!(
        session.events()[0].kind,
        OfficeSessionEventKind::SelectionChanged
    );

    let events = session.drain_events();

    assert_eq!(events.len(), 1);
    assert!(session.events().is_empty());

    session.clear_selection();

    assert_eq!(session.events().len(), 1);
    assert_eq!(
        session.events()[0].kind,
        OfficeSessionEventKind::SelectionChanged
    );
}

#[test]
fn session_filters_and_drains_events_by_category() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 1_500);

    let mut store = InMemoryOfficeStore::new();
    session
        .persist_and_mark_saved_with_receipt_to(&mut store, 2_000)
        .unwrap();

    let persistence_filter =
        OfficeSessionEventFilter::category(OfficeSessionEventCategory::Persistence);
    let persistence_events = session.events_matching(&persistence_filter);

    assert_eq!(persistence_events.len(), 2);
    assert!(persistence_events
        .iter()
        .all(|event| event.category() == OfficeSessionEventCategory::Persistence));
    assert_eq!(persistence_events[0].event_index, 3);
    assert_eq!(persistence_events[1].event_index, 4);
    assert!(matches!(
        persistence_events[0].kind,
        OfficeSessionEventKind::DocumentSaved { .. }
    ));
    assert!(matches!(
        persistence_events[1].kind,
        OfficeSessionEventKind::CheckpointSaved { .. }
    ));

    let recent_persistence_filter =
        OfficeSessionEventFilter::category(OfficeSessionEventCategory::Persistence)
            .with_min_event_index(3)
            .with_min_sequence(1)
            .with_min_timestamp_ms(2_000);

    assert_eq!(session.events_matching(&recent_persistence_filter).len(), 2);

    let drained_events = session.drain_events_matching(&persistence_filter);

    assert_eq!(drained_events.len(), 2);
    assert_eq!(session.events().len(), 2);
    assert_eq!(
        session.events()[0].category(),
        OfficeSessionEventCategory::Edit
    );
    assert_eq!(
        session.events()[1].category(),
        OfficeSessionEventCategory::Selection
    );
}

#[test]
fn session_event_cursor_reads_new_events_without_draining() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());

    assert_eq!(session.event_cursor(), OfficeSessionEventCursor::start());

    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();

    let after_first_event = OfficeSessionEventCursor::after(&session.events()[0]);

    assert_eq!(after_first_event, OfficeSessionEventCursor::new(1));

    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 1_500);

    let events_after_first =
        session.events_after(after_first_event, &OfficeSessionEventFilter::all());

    assert_eq!(events_after_first.len(), 1);
    assert_eq!(events_after_first[0].event_index, 2);
    assert_eq!(
        events_after_first[0].category(),
        OfficeSessionEventCategory::Selection
    );
    assert_eq!(session.event_cursor(), OfficeSessionEventCursor::new(2));
    assert!(session
        .events_after(session.event_cursor(), &OfficeSessionEventFilter::all())
        .is_empty());
    assert_eq!(session.events().len(), 2);
}

#[test]
fn session_event_batch_advances_cursor_past_unmatched_events() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let start_cursor = session.event_cursor();
    let persistence_filter =
        OfficeSessionEventFilter::category(OfficeSessionEventCategory::Persistence);

    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 1_500);

    let empty_batch = session.event_batch_after(start_cursor, &persistence_filter);

    assert!(empty_batch.is_empty());
    assert_eq!(empty_batch.base_cursor, OfficeSessionEventCursor::start());
    assert_eq!(empty_batch.next_cursor, OfficeSessionEventCursor::new(2));
    assert_eq!(session.events().len(), 2);

    let mut store = InMemoryOfficeStore::new();
    session
        .persist_and_mark_saved_with_receipt_to(&mut store, 2_000)
        .unwrap();

    let batch = session.event_batch_after(empty_batch.next_cursor, &persistence_filter);

    assert_eq!(batch.len(), 2);
    assert_eq!(batch.base_cursor, OfficeSessionEventCursor::new(2));
    assert_eq!(batch.next_cursor, session.event_cursor());
    assert_eq!(batch.events[0].event_index, 3);
    assert_eq!(batch.events[1].event_index, 4);
    assert!(batch
        .events
        .iter()
        .all(|event| event.category() == OfficeSessionEventCategory::Persistence));
    assert_eq!(session.events().len(), 4);

    let value = serde_json::to_value(&batch).unwrap();

    assert_eq!(value["base_cursor"]["event_index"], serde_json::json!(2));
    assert_eq!(value["next_cursor"]["event_index"], serde_json::json!(4));
    assert_eq!(value["events"][0]["event_index"], serde_json::json!(3));
    assert_eq!(value["events"][1]["event_index"], serde_json::json!(4));

    let restored: OfficeSessionEventBatch = serde_json::from_value(value).unwrap();

    assert_eq!(restored, batch);
}

#[test]
fn session_prunes_events_by_retention_policy_and_rejects_stale_cursor() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 1_500);
    session
        .apply_operation(operation(2, TestEdit::Add(8)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(8)), 2_500);

    let policy = OfficeSessionEventRetentionPolicy::max_events(2);
    let report = session.prune_events(&policy);

    assert_eq!(
        report,
        OfficeSessionEventPruneReport {
            document_id: DocumentId::new("doc-1"),
            requested_policy: policy,
            pruned_through_event_index: 2,
            last_event_index: 4,
            original_event_count: 4,
            retained_event_count: 2,
            pruned_event_count: 2,
            retained_event_range: Some((3, 4)),
        }
    );
    assert!(report.pruned_events());
    assert_eq!(session.event_pruned_through_index(), 2);
    assert_eq!(session.event_cursor(), OfficeSessionEventCursor::new(4));
    assert_eq!(session.events().len(), 2);
    assert_eq!(session.events()[0].event_index, 3);
    assert_eq!(session.events()[1].event_index, 4);

    let err = session
        .try_event_batch_after(
            OfficeSessionEventCursor::start(),
            &OfficeSessionEventFilter::all(),
        )
        .unwrap_err();

    assert_eq!(
        err,
        OfficeSessionEventError::CursorCompacted {
            requested_event_index: 0,
            available_after_event_index: 2,
        }
    );

    let batch = session
        .try_event_batch_after(
            OfficeSessionEventCursor::new(2),
            &OfficeSessionEventFilter::all(),
        )
        .unwrap();

    assert_eq!(batch.len(), 2);
    assert_eq!(batch.base_cursor, OfficeSessionEventCursor::new(2));
    assert_eq!(batch.next_cursor, OfficeSessionEventCursor::new(4));
}

#[test]
fn session_prunes_events_by_timestamp_prefix() {
    let mut session: OfficeDocumentSession<CounterState, TestEdit> =
        OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(1)), 100);
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(2)), 200);
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(3)), 300);

    let report = session.prune_events(
        &OfficeSessionEventRetentionPolicy::unbounded().with_prune_before_timestamp_ms(250),
    );

    assert_eq!(report.pruned_through_event_index, 2);
    assert_eq!(report.pruned_event_count, 2);
    assert_eq!(report.retained_event_count, 1);
    assert_eq!(report.retained_event_range, Some((3, 3)));
    assert_eq!(session.event_pruned_through_index(), 2);
    assert_eq!(session.events().len(), 1);
    assert_eq!(session.events()[0].timestamp_ms, 300);
}

#[test]
fn session_event_retention_policy_roundtrips_as_stable_settings() {
    let policy = OfficeSessionEventRetentionPolicy::max_events(32)
        .with_prune_through_event_index(7)
        .with_prune_before_timestamp_ms(4_000);

    assert_eq!(policy.max_retained_events(), Some(32));
    assert_eq!(policy.prune_through_event_index(), Some(7));
    assert_eq!(policy.prune_before_timestamp_ms(), Some(4_000));

    let value = serde_json::to_value(&policy).unwrap();

    assert_eq!(value["max_retained_events"], serde_json::json!(32));
    assert_eq!(value["prune_through_event_index"], serde_json::json!(7));
    assert_eq!(value["prune_before_timestamp_ms"], serde_json::json!(4_000));

    let restored: OfficeSessionEventRetentionPolicy = serde_json::from_value(value).unwrap();

    assert_eq!(restored, policy);
}

#[test]
fn session_event_observer_polls_matching_batches_and_advances_cursor() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let mut observer = OfficeSessionEventObserver::category(OfficeSessionEventCategory::Selection);

    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 1_500);

    let batch = observer.poll(&session).unwrap();

    assert_eq!(batch.len(), 1);
    assert_eq!(batch.base_cursor, OfficeSessionEventCursor::start());
    assert_eq!(batch.next_cursor, OfficeSessionEventCursor::new(2));
    assert_eq!(
        batch.events[0].category(),
        OfficeSessionEventCategory::Selection
    );
    assert_eq!(observer.cursor(), OfficeSessionEventCursor::new(2));
    assert_eq!(
        observer.filter().categories_set(),
        OfficeSessionEventFilter::category(OfficeSessionEventCategory::Selection).categories_set()
    );

    let empty_batch = observer.poll(&session).unwrap();

    assert!(empty_batch.is_empty());
    assert_eq!(empty_batch.base_cursor, OfficeSessionEventCursor::new(2));
    assert_eq!(empty_batch.next_cursor, OfficeSessionEventCursor::new(2));
}

#[test]
fn session_event_observer_can_resync_after_retention_compacts_cursor() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(4)), 1_500);
    session
        .apply_operation(operation(2, TestEdit::Add(8)))
        .unwrap();
    session.set_selection_at(OfficeSelection::Text(TextSelection::caret(8)), 2_500);
    session.prune_events(&OfficeSessionEventRetentionPolicy::max_events(2));

    let mut observer = OfficeSessionEventObserver::all();
    let err = observer.poll(&session).unwrap_err();

    assert_eq!(
        err,
        OfficeSessionEventError::CursorCompacted {
            requested_event_index: 0,
            available_after_event_index: 2,
        }
    );
    assert_eq!(observer.cursor(), OfficeSessionEventCursor::start());

    let update = observer.poll_resyncing(&session).unwrap();

    assert!(update.cursor_was_reset());
    assert_eq!(update.reset_cursor, Some(OfficeSessionEventCursor::new(2)));
    assert_eq!(update.batch.base_cursor, OfficeSessionEventCursor::new(2));
    assert_eq!(update.batch.next_cursor, OfficeSessionEventCursor::new(4));
    assert_eq!(update.batch.len(), 2);
    assert_eq!(observer.cursor(), OfficeSessionEventCursor::new(4));

    let value = serde_json::to_value(&observer).unwrap();

    assert_eq!(value["cursor"]["event_index"], serde_json::json!(4));

    let restored: OfficeSessionEventObserver = serde_json::from_value(value).unwrap();

    assert_eq!(restored, observer);
}

#[test]
fn session_event_filter_roundtrips_as_stable_observer_settings() {
    let filter = OfficeSessionEventFilter::categories([
        OfficeSessionEventCategory::Maintenance,
        OfficeSessionEventCategory::Persistence,
    ])
    .with_min_event_index(7)
    .with_min_sequence(12)
    .with_min_timestamp_ms(3_400);

    assert!(filter
        .categories_set()
        .contains(&OfficeSessionEventCategory::Maintenance));
    assert_eq!(filter.min_event_index(), Some(7));
    assert_eq!(filter.min_sequence(), Some(12));
    assert_eq!(filter.min_timestamp_ms(), Some(3_400));

    let value = serde_json::to_value(&filter).unwrap();

    assert_eq!(
        value["categories"],
        serde_json::json!(["persistence", "maintenance"])
    );
    assert_eq!(value["min_event_index"], serde_json::json!(7));
    assert_eq!(value["min_sequence"], serde_json::json!(12));
    assert_eq!(value["min_timestamp_ms"], serde_json::json!(3_400));

    let restored: OfficeSessionEventFilter = serde_json::from_value(value).unwrap();

    assert_eq!(restored, filter);
}

#[test]
fn session_drains_operation_and_transaction_events_in_order() {
    let transaction = OperationTransaction::new("tx-1")
        .with_operation(operation(1, TestEdit::Add(5)))
        .with_operation(operation(2, TestEdit::Set(3)));
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());

    session.apply_transaction(transaction).unwrap();
    let events = session.drain_events();

    assert_eq!(events.len(), 3);
    assert!(session.events().is_empty());
    assert!(matches!(
        &events[0].kind,
        OfficeSessionEventKind::OperationApplied { operation_id }
            if operation_id.as_str() == "op-1"
    ));
    assert!(matches!(
        &events[1].kind,
        OfficeSessionEventKind::OperationApplied { operation_id }
            if operation_id.as_str() == "op-2"
    ));
    assert!(matches!(
        &events[2].kind,
        OfficeSessionEventKind::TransactionCommitted {
            transaction_id,
            operation_count,
        } if transaction_id.as_str() == "tx-1" && *operation_count == 2
    ));
}

#[test]
fn session_rejects_operation_for_different_document() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    let operation = OperationEnvelope::new(
        "counter",
        "op-1",
        "other-doc",
        "actor-1",
        1,
        1_001,
        TestEdit::Add(5),
    );

    let err = session.apply_operation(operation).unwrap_err();

    match err {
        OfficeSessionError::Validation(report) => {
            assert!(report.issues().iter().any(|issue| {
                issue.code == "session.operation.document_mismatch"
                    && issue.path.as_deref() == Some("document_id")
            }));
        }
        _ => panic!("expected validation error"),
    }
}

#[test]
fn session_rejects_stale_operation_sequence() {
    let mut session = OfficeDocumentSession::new("counter", "doc-1", CounterState::default());
    session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap();

    let err = session
        .apply_operation(operation(1, TestEdit::Add(5)))
        .unwrap_err();

    match err {
        OfficeSessionError::Validation(report) => {
            assert!(report.issues().iter().any(|issue| {
                issue.code == "session.operation.sequence_not_newer"
                    && issue.path.as_deref() == Some("sequence")
            }));
        }
        _ => panic!("expected validation error"),
    }
}

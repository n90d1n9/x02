use super::{OfficeSaveSkipReason, OfficeSaveTrigger};
use crate::{DocumentId, EngineId, OfficeDocumentPersistMode, OperationId, TransactionId};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::{collections::BTreeMap, fmt};

/// Describes a durable session lifecycle event emitted by the Office core engine.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum OfficeSessionEventKind {
    OperationApplied {
        operation_id: OperationId,
    },
    TransactionCommitted {
        transaction_id: TransactionId,
        operation_count: usize,
    },
    UndoApplied {
        transaction_id: TransactionId,
        operation_count: usize,
    },
    RedoApplied {
        transaction_id: TransactionId,
        operation_count: usize,
    },
    RemoteBatchApplied {
        base_sequence: u64,
        target_sequence: u64,
        operation_count: usize,
    },
    CheckpointSaved {
        sequence: u64,
        timestamp_ms: u64,
    },
    DocumentSaved {
        sequence: u64,
        timestamp_ms: u64,
        operation_count: usize,
        persist_mode: OfficeDocumentPersistMode,
    },
    SaveSkipped {
        trigger: Option<OfficeSaveTrigger>,
        reason: OfficeSaveSkipReason,
    },
    RecoveryCompleted {
        snapshot_sequence: u64,
        recovered_sequence: u64,
        replayed_operation_count: usize,
    },
    CompactionCompleted {
        snapshot_sequence: u64,
        removed_operation_count: usize,
        retained_operation_count: usize,
        retained_sequence_range: Option<(u64, u64)>,
    },
    OperationLogPruned {
        pruned_through_sequence: u64,
        pruned_operation_count: usize,
        retained_operation_count: usize,
        retained_sequence_range: Option<(u64, u64)>,
    },
    SelectionChanged,
}

/// Tracks the last observed session event for non-destructive event polling.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct OfficeSessionEventCursor {
    pub event_index: u64,
}

impl OfficeSessionEventCursor {
    pub fn start() -> Self {
        Self { event_index: 0 }
    }

    pub fn new(event_index: u64) -> Self {
        Self { event_index }
    }

    pub fn after(event: &OfficeSessionEvent) -> Self {
        Self::new(event.event_index)
    }
}

/// Reports event polling failures that a consumer can recover from by resetting its cursor.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum OfficeSessionEventError {
    CursorCompacted {
        requested_event_index: u64,
        available_after_event_index: u64,
    },
}

impl fmt::Display for OfficeSessionEventError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            OfficeSessionEventError::CursorCompacted {
                requested_event_index,
                available_after_event_index,
            } => write!(
                f,
                "event cursor {requested_event_index} was compacted; events are available after {available_after_event_index}"
            ),
        }
    }
}

impl std::error::Error for OfficeSessionEventError {}

/// Captures an ordered, document-scoped event that product shells can observe or drain.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSessionEvent {
    #[serde(default)]
    pub event_index: u64,
    pub engine: EngineId,
    pub document_id: DocumentId,
    pub sequence: u64,
    pub timestamp_ms: u64,
    pub kind: OfficeSessionEventKind,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub metadata: BTreeMap<String, Value>,
}

impl OfficeSessionEvent {
    pub fn new(
        engine: impl Into<EngineId>,
        document_id: impl Into<DocumentId>,
        sequence: u64,
        timestamp_ms: u64,
        kind: OfficeSessionEventKind,
    ) -> Self {
        Self {
            event_index: 0,
            engine: engine.into(),
            document_id: document_id.into(),
            sequence,
            timestamp_ms,
            kind,
            metadata: BTreeMap::new(),
        }
    }

    pub fn with_event_index(mut self, event_index: u64) -> Self {
        self.event_index = event_index;
        self
    }

    pub fn with_metadata_text(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.metadata
            .insert(key.into(), Value::String(value.into()));
        self
    }

    pub fn with_metadata_value(mut self, key: impl Into<String>, value: Value) -> Self {
        self.metadata.insert(key.into(), value);
        self
    }
}

/// Bundles newly observed session events with the cursor a consumer should persist.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSessionEventBatch {
    pub base_cursor: OfficeSessionEventCursor,
    pub next_cursor: OfficeSessionEventCursor,
    pub events: Vec<OfficeSessionEvent>,
}

impl OfficeSessionEventBatch {
    pub fn new(
        base_cursor: OfficeSessionEventCursor,
        next_cursor: OfficeSessionEventCursor,
        events: Vec<OfficeSessionEvent>,
    ) -> Self {
        Self {
            base_cursor,
            next_cursor,
            events,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.events.is_empty()
    }

    pub fn len(&self) -> usize {
        self.events.len()
    }
}

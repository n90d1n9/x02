use super::{OfficeSessionCheckpoint, OfficeSessionEvent};
use crate::{DocumentId, EngineId, OfficeSelection, OperationLog, TransactionHistory};

mod diagnostics;
mod events;
mod lifecycle;
mod log_prune;
mod operations;
mod persistence;
mod save_state;
mod selection;
mod sync;
mod validation;

pub use log_prune::OfficeSessionLogPruneReport;

#[derive(Debug, Clone, PartialEq)]
pub struct OfficeDocumentSession<State, Edit> {
    engine: EngineId,
    document_id: DocumentId,
    state: State,
    operation_log: OperationLog<Edit>,
    history: TransactionHistory<Edit>,
    selection: OfficeSelection,
    events: Vec<OfficeSessionEvent>,
    last_event_index: u64,
    event_pruned_through_index: u64,
    sequence: u64,
    last_timestamp_ms: u64,
    save_checkpoint: OfficeSessionCheckpoint,
    operation_log_pruned_through_sequence: u64,
}

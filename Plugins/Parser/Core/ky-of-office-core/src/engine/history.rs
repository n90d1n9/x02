use crate::{OperationEnvelope, OperationTransaction, TransactionError, TransactionId};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum OfficeHistoryAction {
    Undo,
    Redo,
}

impl OfficeHistoryAction {
    fn as_str(self) -> &'static str {
        match self {
            Self::Undo => "undo",
            Self::Redo => "redo",
        }
    }

    fn operation_id(self, transaction_id: &TransactionId, sequence: u64) -> String {
        format!("{}-{}-{sequence}", self.as_str(), transaction_id.as_str())
    }
}

pub(crate) fn issue_undo_operations<Edit>(
    transaction: &OperationTransaction<Edit>,
    current_sequence: u64,
    timestamp_ms: u64,
) -> Result<Vec<OperationEnvelope<Edit>>, TransactionError>
where
    Edit: Clone,
{
    let operations = transaction.undo_operations()?;
    Ok(issue_history_operations(
        OfficeHistoryAction::Undo,
        transaction,
        operations,
        current_sequence,
        timestamp_ms,
    ))
}

pub(crate) fn issue_redo_operations<Edit>(
    transaction: &OperationTransaction<Edit>,
    current_sequence: u64,
    timestamp_ms: u64,
) -> Vec<OperationEnvelope<Edit>>
where
    Edit: Clone,
{
    issue_history_operations(
        OfficeHistoryAction::Redo,
        transaction,
        transaction.operations().to_vec(),
        current_sequence,
        timestamp_ms,
    )
}

fn issue_history_operations<Edit>(
    action: OfficeHistoryAction,
    transaction: &OperationTransaction<Edit>,
    operations: Vec<OperationEnvelope<Edit>>,
    current_sequence: u64,
    timestamp_ms: u64,
) -> Vec<OperationEnvelope<Edit>> {
    operations
        .into_iter()
        .enumerate()
        .map(|(index, operation)| {
            let sequence = current_sequence + index as u64 + 1;
            reissue_history_operation(action, transaction, operation, sequence, timestamp_ms)
        })
        .collect()
}

fn reissue_history_operation<Edit>(
    action: OfficeHistoryAction,
    transaction: &OperationTransaction<Edit>,
    operation: OperationEnvelope<Edit>,
    sequence: u64,
    timestamp_ms: u64,
) -> OperationEnvelope<Edit> {
    let OperationEnvelope {
        engine,
        operation_id,
        document_id,
        actor_id,
        edit,
        mut metadata,
        ..
    } = operation;

    metadata.insert("history_action".into(), action.as_str().into());
    metadata.insert(
        "history_transaction_id".into(),
        transaction.transaction_id.as_str().into(),
    );
    metadata.insert(
        "history_source_operation_id".into(),
        operation_id.as_str().into(),
    );

    OperationEnvelope {
        engine,
        operation_id: action
            .operation_id(&transaction.transaction_id, sequence)
            .into(),
        document_id,
        actor_id,
        sequence,
        timestamp_ms,
        edit,
        metadata,
    }
}

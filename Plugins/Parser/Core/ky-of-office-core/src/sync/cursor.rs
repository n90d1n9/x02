use crate::{DocumentId, EngineId, OfficeSnapshot, OperationEnvelope};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSyncCursor {
    pub engine: EngineId,
    pub document_id: DocumentId,
    pub sequence: u64,
}

impl OfficeSyncCursor {
    pub fn new(
        engine: impl Into<EngineId>,
        document_id: impl Into<DocumentId>,
        sequence: u64,
    ) -> Self {
        Self {
            engine: engine.into(),
            document_id: document_id.into(),
            sequence,
        }
    }

    pub fn document_start(engine: impl Into<EngineId>, document_id: impl Into<DocumentId>) -> Self {
        Self::new(engine, document_id, 0)
    }

    pub fn from_snapshot<State, Edit>(snapshot: &OfficeSnapshot<State, Edit>) -> Self {
        Self {
            engine: snapshot.engine.clone(),
            document_id: snapshot.document_id.clone(),
            sequence: snapshot.sequence,
        }
    }

    pub fn advance_to(&self, sequence: u64) -> Self {
        Self {
            engine: self.engine.clone(),
            document_id: self.document_id.clone(),
            sequence,
        }
    }

    pub fn matches_operation<Edit>(&self, operation: &OperationEnvelope<Edit>) -> bool {
        operation.engine == self.engine && operation.document_id == self.document_id
    }
}

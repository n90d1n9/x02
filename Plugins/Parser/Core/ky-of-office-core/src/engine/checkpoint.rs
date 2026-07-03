use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionCheckpoint {
    pub sequence: u64,
    pub timestamp_ms: u64,
}

impl OfficeSessionCheckpoint {
    pub fn new(sequence: u64, timestamp_ms: u64) -> Self {
        Self {
            sequence,
            timestamp_ms,
        }
    }

    pub fn document_start() -> Self {
        Self::new(0, 0)
    }

    pub fn is_dirty(&self, current_sequence: u64) -> bool {
        current_sequence > self.sequence
    }
}

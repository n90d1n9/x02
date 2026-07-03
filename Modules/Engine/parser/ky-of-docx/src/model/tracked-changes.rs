use serde::{Deserialize, Serialize};


// ---------------------------------------------------------------------------
// Tracked changes
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrackedChange {
    pub id: String,
    pub change_type: ChangeType,
    pub author: String,
    pub date: Option<String>,
    pub text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ChangeType {
    Insertion,
    Deletion,
    FormatChange,
}

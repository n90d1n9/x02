use serde::{Deserialize, Serialize};




// ---------------------------------------------------------------------------
// Lists
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListInfo {
    /// Abstract numbering ID (used to group items into the same list).
    pub num_id: String,
    /// 0-based nesting level.
    pub level: u8,
    /// Whether the list uses ordered (numbered) or unordered (bulleted) style.
    pub list_type: ListType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ListType {
    Ordered,
    Unordered,
}

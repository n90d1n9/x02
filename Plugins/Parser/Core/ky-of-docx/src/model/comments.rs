use serde::{Deserialize, Serialize};


// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Comment {
    pub id: String,
    pub author: String,
    pub date: Option<String>,
    pub initials: Option<String>,
    pub paragraphs: Vec<Paragraph>,
    /// ID of the parent comment if this is a reply.
    pub parent_id: Option<String>,
}

impl Comment {
    pub fn text(&self) -> String {
        self.paragraphs.iter().map(|p| p.text()).collect::<Vec<_>>().join("\n")
    }
}
use serde::{Deserialize, Serialize};


// ---------------------------------------------------------------------------
// Block elements
// ---------------------------------------------------------------------------

/// A top-level content block in the document body.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum Block {
    Paragraph(Paragraph),
    Table(Table),
    /// A structural section break.
    SectionBreak,
}
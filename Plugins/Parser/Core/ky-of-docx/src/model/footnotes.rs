use serde::{Deserialize, Serialize};

// ---------------------------------------------------------------------------
// Footnotes & Endnotes
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Footnote {
    pub id: String,
    pub paragraphs: Vec<Paragraph>,
}

impl Footnote {
    pub fn text(&self) -> String {
        self.paragraphs.iter().map(|p| p.text()).collect::<Vec<_>>().join("\n")
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Endnote {
    pub id: String,
    pub paragraphs: Vec<Paragraph>,
}

impl Endnote {
    pub fn text(&self) -> String {
        self.paragraphs.iter().map(|p| p.text()).collect::<Vec<_>>().join("\n")
    }
}



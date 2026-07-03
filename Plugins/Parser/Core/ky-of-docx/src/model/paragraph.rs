use serde::{Deserialize, Serialize};


/// A paragraph with its inline runs.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Paragraph {
    /// Resolved style name (e.g. `"Heading 1"`, `"Normal"`).
    pub style: Option<String>,
    /// Heading level 1–9 if this paragraph is a heading, else `None`.
    pub heading_level: Option<u8>,
    /// List information if this paragraph belongs to a list.
    pub list_info: Option<ListInfo>,
    /// Inline content runs.
    pub runs: Vec<Run>,
    /// Paragraph-level alignment.
    pub alignment: Option<Alignment>,
    /// Spacing before/after in twips.
    pub spacing_before: Option<i32>,
    pub spacing_after: Option<i32>,
    /// Indentation in twips.
    pub indent_left: Option<i32>,
    pub indent_right: Option<i32>,
    /// Style-level border.
    pub border: Option<ParagraphBorder>,
}

impl Paragraph {
    /// Collect all text from runs, concatenated.
    pub fn text(&self) -> String {
        self.runs.iter().map(|r| r.text()).collect()
    }

    /// `true` if this paragraph has no runs or all runs are whitespace.
    pub fn is_empty(&self) -> bool {
        self.runs.iter().all(|r| r.text().trim().is_empty())
    }
}
use serde::{Deserialize, Serialize};





/// An inline text run with optional formatting.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Run {
    /// The text content (may be empty for pure formatting markers).
    pub text: String,
    /// Formatting applied to this run.
    pub formatting: RunFormatting,
    /// If this run is a hyperlink, contains the URL.
    pub hyperlink: Option<String>,
    /// If this run is a footnote reference, contains the footnote ID.
    pub footnote_ref: Option<String>,
    /// If this run is an endnote reference, contains the endnote ID.
    pub endnote_ref: Option<String>,
    /// If this run contains an inline image, the relationship ID.
    pub image_rel_id: Option<String>,
    /// If this run is a field code result (e.g. page number), the field text.
    pub field_text: Option<String>,
}

impl Run {
    pub fn text(&self) -> &str {
        &self.text
    }
}

/// Character formatting for a run.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RunFormatting {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub strikethrough: bool,
    pub superscript: bool,
    pub subscript: bool,
    pub small_caps: bool,
    pub all_caps: bool,
    pub highlight: Option<String>,
    pub color: Option<String>,
    /// Font size in half-points (divide by 2 for points).
    pub size: Option<u32>,
    pub font_ascii: Option<String>,
    pub font_east_asia: Option<String>,
    pub style: Option<String>,
    pub vertical_align: Option<VerticalAlign>,
}

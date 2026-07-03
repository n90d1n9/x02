use serde::{Deserialize, Serialize};



// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

/// A named style as defined in `word/styles.xml`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StyleDef {
    pub id: String,
    pub name: String,
    pub style_type: StyleType,
    pub based_on: Option<String>,
    pub next_style: Option<String>,
    pub paragraph_formatting: Option<ParagraphFormatting>,
    pub run_formatting: Option<RunFormatting>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum StyleType {
    Paragraph,
    Character,
    Table,
    Numbering,
    Unknown,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ParagraphFormatting {
    pub alignment: Option<Alignment>,
    pub spacing_before: Option<i32>,
    pub spacing_after: Option<i32>,
    pub line_spacing: Option<i32>,
    pub outline_level: Option<u8>,
    pub indent_left: Option<i32>,
    pub indent_right: Option<i32>,
    pub indent_hanging: Option<i32>,
    pub keep_lines: bool,
    pub keep_next: bool,
    pub page_break_before: bool,
}

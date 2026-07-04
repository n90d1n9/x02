use serde::{Deserialize, Serialize};


// ---------------------------------------------------------------------------
// Extraction options
// ---------------------------------------------------------------------------

/// Options controlling what `DocxReader::extract_text` returns.
#[derive(Debug, Clone)]
pub struct TextOptions {
    /// Include header text.
    pub include_headers: bool,
    /// Include footer text.
    pub include_footers: bool,
    /// Include footnotes inline after the paragraph that references them.
    pub include_footnotes: bool,
    /// Include endnotes at the end.
    pub include_endnotes: bool,
    /// Include comment text.
    pub include_comments: bool,
    /// Include deleted text from tracked changes (default: false).
    pub include_deletions: bool,
    /// Separator inserted between paragraphs.
    pub paragraph_separator: String,
    /// Separator inserted between table cells.
    pub table_cell_separator: String,
    /// Separator between table rows.
    pub table_row_separator: String,
}

impl Default for TextOptions {
    fn default() -> Self {
        Self {
            include_headers: false,
            include_footers: false,
            include_footnotes: true,
            include_endnotes: true,
            include_comments: false,
            include_deletions: false,
            paragraph_separator: "\n".into(),
            table_cell_separator: "\t".into(),
            table_row_separator: "\n".into(),
        }
    }
}

impl TextOptions {
    pub fn all() -> Self {
        Self {
            include_headers: true,
            include_footers: true,
            include_footnotes: true,
            include_endnotes: true,
            include_comments: true,
            include_deletions: false,
            paragraph_separator: "\n".into(),
            table_cell_separator: "\t".into(),
            table_row_separator: "\n".into(),
        }
    }
}

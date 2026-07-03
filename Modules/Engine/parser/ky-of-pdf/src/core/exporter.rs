use crate::{
    error::Result,
    models::{BookmarkNode, ExtractionResult},
};

/// Supported export formats.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExportFormat {
    /// Full structured JSON (all fields, images as base64).
    Json,
    /// Pretty-printed plain text: metadata header + page text.
    PlainText,
    /// Markdown document with headings, metadata table, and page sections.
    Markdown,
    /// Self-contained HTML document.
    Html,
    /// CSV with one row per page: page_number, word_count, char_count, text.
    Csv,
}

/// Dispatch export to the appropriate renderer.
pub fn export(result: &ExtractionResult, format: ExportFormat) -> Result<String> {
    match format {
        ExportFormat::Json => to_json(result),
        ExportFormat::PlainText => Ok(to_plain_text(result)),
        ExportFormat::Markdown => Ok(to_markdown(result)),
        ExportFormat::Html => Ok(to_html(result)),
        ExportFormat::Csv => Ok(to_csv(result)),
    }
}




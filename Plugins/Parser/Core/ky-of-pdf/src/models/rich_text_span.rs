

// ═══════════════════════════════════════════════
// Rich text spans
// ═══════════════════════════════════════════════

/// A single styled text run extracted from a PDF content stream.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RichSpan {
    pub page_index: usize,
    /// Display text.
    pub text: String,
    /// Font resource name (e.g. `"F1"`).
    pub font_name: String,
    /// Resolved base font name (e.g. `"Helvetica-Bold"`).
    pub base_font: Option<String>,
    /// Font size in user units.
    pub font_size: f64,
    /// RGB colour 0.0–1.0.
    pub color: [f64; 3],
    /// True if the base font name suggests bold.
    pub bold: bool,
    /// True if the base font name suggests italic / oblique.
    pub italic: bool,
    /// Approximate X position on the page.
    pub x: f64,
    /// Approximate Y position on the page (distance from bottom).
    pub y: f64,
}

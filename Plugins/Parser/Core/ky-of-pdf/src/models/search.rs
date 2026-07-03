

// ═══════════════════════════════════════════════
// Search
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchHit {
    pub page_index: usize,
    pub page_number: usize,
    /// Byte offset within the page's plain text.
    pub char_offset: usize,
    /// The matched text snippet.
    pub matched_text: String,
    /// Surrounding context (up to 80 chars).
    pub context: String,
}

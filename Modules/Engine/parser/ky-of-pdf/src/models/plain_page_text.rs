

// ═══════════════════════════════════════════════
// Plain page text
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageText {
    pub page_index: usize,
    pub page_number: usize,
    pub text: String,
    pub char_count: usize,
    pub word_count: usize,
}

impl PageText {
    pub(crate) fn new(page_index: usize, text: String) -> Self {
        let word_count = text.split_whitespace().count();
        let char_count = text.len();
        PageText {
            page_number: page_index + 1,
            page_index,
            word_count,
            char_count,
            text,
        }
    }
}
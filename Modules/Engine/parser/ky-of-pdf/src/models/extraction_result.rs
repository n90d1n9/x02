








// ═══════════════════════════════════════════════
// Aggregate result
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtractionResult {
    pub metadata: Metadata,
    pub pages: Vec<PageText>,
    pub bookmarks: Vec<BookmarkNode>,
    pub form_fields: Vec<FormField>,
    pub images: Vec<ImageInfo>,
    pub annotations: Vec<Annotation>,
    pub tables: Vec<TextTable>,
    pub total_word_count: usize,
    pub total_char_count: usize,
}

impl ExtractionResult {
    pub(crate) fn build(
        metadata: Metadata,
        pages: Vec<PageText>,
        bookmarks: Vec<BookmarkNode>,
        form_fields: Vec<FormField>,
        images: Vec<ImageInfo>,
        annotations: Vec<Annotation>,
        tables: Vec<TextTable>,
    ) -> Self {
        let total_word_count = pages.iter().map(|p| p.word_count).sum();
        let total_char_count = pages.iter().map(|p| p.char_count).sum();
        ExtractionResult {
            metadata,
            pages,
            bookmarks,
            form_fields,
            images,
            annotations,
            tables,
            total_word_count,
            total_char_count,
        }
    }
}

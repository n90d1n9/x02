


// ═══════════════════════════════════════════════
// Bookmarks
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BookmarkNode {
    pub title: String,
    pub page_index: Option<usize>,
    pub level: usize,
    pub children: Vec<BookmarkNode>,
}

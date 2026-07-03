

// ═══════════════════════════════════════════════
// Diff
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageDiff {
    pub page_index: usize,
    /// Lines only in the left document.
    pub only_in_left: Vec<String>,
    /// Lines only in the right document.
    pub only_in_right: Vec<String>,
    /// Whether both pages are textually identical.
    pub identical: bool,
}
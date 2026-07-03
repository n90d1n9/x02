use serde::{Deserialize, Serialize};


// ---------------------------------------------------------------------------
// Document-level
// ---------------------------------------------------------------------------

/// The complete parsed representation of a `.docx` document.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Document {
    /// Core document metadata (author, title, dates, …).
    pub metadata: Metadata,
    /// Ordered list of top-level block elements.
    pub body: Vec<Block>,
    /// Footnotes keyed by their numeric ID.
    pub footnotes: Vec<Footnote>,
    /// Endnotes keyed by their numeric ID.
    pub endnotes: Vec<Endnote>,
    /// Comments embedded in the document.
    pub comments: Vec<Comment>,
    /// Tracked insertions and deletions.
    pub tracked_changes: Vec<TrackedChange>,
    /// Embedded images (metadata only; bytes loaded on demand).
    pub images: Vec<ImageRef>,
    /// Named styles defined in the document.
    pub styles: Vec<StyleDef>,
    /// Per-section headers and footers.
    pub headers_footers: Vec<SectionHeaderFooter>,
}


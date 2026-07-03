


// ═══════════════════════════════════════════════
// Annotations
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum AnnotationKind {
    Text,
    FreeText,
    Highlight,
    Underline,
    StrikeOut,
    Squiggly,
    Link,
    Stamp,
    Ink,
    Widget,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Annotation {
    pub page_index: usize,
    pub kind: AnnotationKind,
    /// Annotation contents / comment text.
    pub contents: Option<String>,
    /// Author of the annotation.
    pub author: Option<String>,
    /// ISO-8601 creation date.
    pub date: Option<String>,
    /// Bounding rectangle [x1, y1, x2, y2].
    pub rect: Option<[f64; 4]>,
    /// URI for Link annotations.
    pub uri: Option<String>,
    /// RGBA colour [r, g, b, a] 0.0–1.0.
    pub color: Option<[f64; 4]>,
}
use serde::{Deserialize, Serialize};



// ---------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------

/// Lightweight reference to an embedded image (no raw bytes).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageRef {
    /// Relationship ID (e.g. `"rId5"`).
    pub rel_id: String,
    /// Target path inside the archive (e.g. `"word/media/image1.png"`).
    pub target: String,
    /// MIME type (e.g. `"image/png"`).
    pub content_type: String,
    /// Display width in EMUs (English Metric Units; 914400 = 1 inch).
    pub width_emu: Option<i64>,
    /// Display height in EMUs.
    pub height_emu: Option<i64>,
    /// Alt-text / description, if provided.
    pub description: Option<String>,
}

impl ImageRef {
    /// Width in inches (approximate).
    pub fn width_inches(&self) -> Option<f64> {
        self.width_emu.map(|w| w as f64 / 914400.0)
    }
    /// Height in inches (approximate).
    pub fn height_inches(&self) -> Option<f64> {
        self.height_emu.map(|h| h as f64 / 914400.0)
    }
    /// File extension derived from the target path.
    pub fn extension(&self) -> &str {
        self.target.rsplit('.').next().unwrap_or("bin")
    }
}

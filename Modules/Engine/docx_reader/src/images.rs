use serde::{Deserialize, Serialize};


use base64::{engine::general_purpose::STANDARD, Engine as _};

/// Raw image bytes plus metadata, returned by [`crate::extractor::DocxReader::image_bytes`].
#[derive(Debug, Clone)]
pub struct ImageData {
    /// The relationship ID (e.g. `"rId5"`).
    pub rel_id: String,
    /// Raw bytes of the image.
    pub bytes: Vec<u8>,
    /// MIME type (e.g. `"image/png"`).
    pub mime_type: String,
    /// File extension (e.g. `"png"`).
    pub extension: String,
}

impl ImageData {
    /// Length of the image in bytes.
    pub fn len(&self) -> usize {
        self.bytes.len()
    }

    /// `true` if the image data is empty (should not happen in practice).
    pub fn is_empty(&self) -> bool {
        self.bytes.is_empty()
    }

    /// Encode the bytes as a standard base64 string (useful for embedding in
    /// HTML `data:` URIs).
    pub fn to_base64(&self) -> String {
        STANDARD.encode(&self.bytes)
    }

    /// Build a data URI string suitable for use in an HTML `<img src="…">`.
    pub fn to_data_uri(&self) -> String {
        format!("data:{};base64,{}", self.mime_type, self.to_base64())
    }

    /// Save the image data to `path` on disk.
    pub fn save<P: AsRef<std::path::Path>>(&self, path: P) -> std::io::Result<()> {
        std::fs::write(path, &self.bytes)
    }
}

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

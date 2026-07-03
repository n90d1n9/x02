


// ═══════════════════════════════════════════════
// Images
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum ImageFormat {
    Jpeg,
    Png,
    Tiff,
    Jbig2,
    Ccitt,
    Raw,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageInfo {
    pub page_index: usize,
    pub image_index: usize,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub color_space: Option<String>,
    pub bits_per_component: Option<u32>,
    pub filters: Vec<String>,
    /// Detected/decoded image format.
    pub format: ImageFormat,
    #[serde(skip)]
    pub data: Vec<u8>,
    pub data_base64: String,
}

/// Fully decoded image with raw pixel data and a rendered PNG/JPEG payload.
#[derive(Debug, Clone)]
pub struct DecodedImage {
    pub info: ImageInfo,
    /// Ready-to-write PNG or JPEG bytes.
    pub encoded_bytes: Vec<u8>,
    /// MIME type: `"image/png"` or `"image/jpeg"`.
    pub mime_type: &'static str,
    /// Data URL: `"data:image/png;base64,..."`.
    pub data_url: String,
}
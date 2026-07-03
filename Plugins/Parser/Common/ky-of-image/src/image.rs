use serde::{Deserialize, Serialize};

/// Extracted image data from a PPTX file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageData {
    /// The relationship ID linking this image to a slide.
    pub relationship_id: String,
    /// Original filename of the image within the archive.
    pub filename: String,
    /// MIME type (e.g., "image/png", "image/jpeg", "image/svg+xml").
    pub mime_type: String,
    /// Image file extension (e.g., "png", "jpg", "gif", "emf", "wmf").
    pub extension: String,
    /// Raw image bytes.
    pub data: Vec<u8>,
    /// Image width in pixels (if determinable).
    pub width_px: Option<u32>,
    /// Image height in pixels (if determinable).
    pub height_px: Option<u32>,
    /// DPI (dots per inch) for raster images.
    pub dpi: Option<u32>,
    /// Whether this is a linked image (external) vs embedded.
    pub is_linked: bool,
    /// External URL if this is a linked image.
    pub external_url: Option<String>,
    /// Cropping applied to the image on the slide.
    pub crop: Option<ImageCrop>,
    /// Effects applied to the image.
    pub effects: Vec<ImageEffect>,
}

impl ImageData {
    /// Get image data as base64 encoded string.
    pub fn as_base64(&self) -> String {
        use base64::{Engine, engine::general_purpose::STANDARD};
        STANDARD.encode(&self.data)
    }

    /// Get as a data URI suitable for embedding in HTML/CSS.
    pub fn as_data_uri(&self) -> String {
        format!("data:{};base64,{}", self.mime_type, self.as_base64())
    }

    /// Get file size in bytes.
    pub fn file_size(&self) -> usize {
        self.data.len()
    }

    /// Check if the image is a vector format (SVG, EMF, WMF).
    pub fn is_vector(&self) -> bool {
        matches!(self.extension.to_lowercase().as_str(), "svg" | "emf" | "wmf" | "emz" | "wmz")
    }
}

/// Image cropping rectangle (all values are percentages, 0.0–100.0).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ImageCrop {
    pub top: f64,
    pub bottom: f64,
    pub left: f64,
    pub right: f64,
}

/// Effects applied to an image shape.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum ImageEffect {
    Shadow {
        blur: f64,
        distance: f64,
        direction: f64,
        color: crate::models::color::Color,
        alpha: f32,
    },
    Reflection {
        blur: f64,
        alpha: f32,
    },
    Glow {
        radius: f64,
        color: crate::models::color::Color,
        alpha: f32,
    },
    SoftEdge {
        radius: f64,
    },
    Brightness {
        brightness: f64, // -1.0 to 1.0
        contrast: f64,   // -1.0 to 1.0
    },
    Grayscale,
    BlackWhite { threshold: f64 },
    Blur { radius: f64, grow: bool },
}

/// Picture fill properties for a shape using an image.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PictureFill {
    pub relationship_id: String,
    pub content_type: Option<String>,
    pub stretch: bool,
    pub tile: Option<TileProperties>,
    pub crop: Option<ImageCrop>,
}

/// Tiling properties for a picture fill.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TileProperties {
    pub align: String,
    pub flip: String,
    pub sx: f64,
    pub sy: f64,
    pub tx: i64,
    pub ty: i64,
}

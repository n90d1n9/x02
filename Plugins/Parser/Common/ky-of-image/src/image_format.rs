//! Embedded worksheet images (PNG, JPEG, GIF, TIFF, EMF, WMF, BMP, SVG).

use crate::cell::CellAddress;
use crate::error::{Error, Result};
use base64::{engine::general_purpose::STANDARD as B64, Engine};
use std::io::Read;
use zip::ZipArchive;

#[cfg(feature = "serde-support")]
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



// ── ImageFormat ───────────────────────────────────────────────────────────────

/// File format of an embedded image.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub enum ImageFormat {
    Png,
    Jpeg,
    Gif,
    Tiff,
    Bmp,
    Emf, // Enhanced Metafile (vector)
    Wmf, // Windows Metafile (vector)
    Svg,
    WebP,
    Unknown(String),
}

impl ImageFormat {
    /// Derive format from a file extension (case-insensitive).
    pub fn from_ext(ext: &str) -> Self {
        match ext.to_ascii_lowercase().as_str() {
            "png" => Self::Png,
            "jpg" | "jpeg" => Self::Jpeg,
            "gif" => Self::Gif,
            "tif" | "tiff" => Self::Tiff,
            "bmp" => Self::Bmp,
            "emf" => Self::Emf,
            "wmf" => Self::Wmf,
            "svg" => Self::Svg,
            "webp" => Self::WebP,
            other => Self::Unknown(other.to_owned()),
        }
    }

    /// MIME type string.
    pub fn mime_type(&self) -> &'static str {
        match self {
            Self::Png => "image/png",
            Self::Jpeg => "image/jpeg",
            Self::Gif => "image/gif",
            Self::Tiff => "image/tiff",
            Self::Bmp => "image/bmp",
            Self::Emf => "image/x-emf",
            Self::Wmf => "image/x-wmf",
            Self::Svg => "image/svg+xml",
            Self::WebP => "image/webp",
            Self::Unknown(_) => "application/octet-stream",
        }
    }
}

// ── ImageAnchor ───────────────────────────────────────────────────────────────

/// How an image is anchored to the sheet grid.
#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub enum ImageAnchor {
    /// Two-cell anchor (image scales with rows/columns).
    TwoCell {
        from: CellAddress,
        to: CellAddress,
        /// Column offset in EMUs from the `from` cell left edge.
        from_col_offset: i64,
        /// Row offset in EMUs from the `from` cell top edge.
        from_row_offset: i64,
        to_col_offset: i64,
        to_row_offset: i64,
    },
    /// One-cell anchor (image moves but does not resize).
    OneCell {
        from: CellAddress,
        col_offset: i64,
        row_offset: i64,
    },
    /// Absolute anchor (fixed position on sheet, no cell reference).
    Absolute {
        /// X position in EMUs (1 cm = 360 000 EMU).
        x: i64,
        /// Y position in EMUs.
        y: i64,
        /// Width in EMUs.
        cx: i64,
        /// Height in EMUs.
        cy: i64,
    },
}

// ── EmbeddedImage ─────────────────────────────────────────────────────────────

/// An image embedded in a worksheet drawing.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct EmbeddedImage {
    /// Original filename inside the archive (e.g. `"image1.png"`).
    pub name: String,
    /// Detected image format.
    pub format: ImageFormat,
    /// Raw image bytes.
    #[cfg_attr(feature = "serde-support", serde(skip))]
    pub data: Vec<u8>,
    /// Base64-encoded image (useful for embedding in HTML/JSON).
    pub data_base64: String,
    /// Width in pixels (if determinable from header).
    pub width_px: Option<u32>,
    /// Height in pixels (if determinable from header).
    pub height_px: Option<u32>,
    /// Anchor / position on the sheet.
    pub anchor: Option<ImageAnchor>,
    /// Alt-text / description.
    pub description: Option<String>,
    /// Hyperlink attached to the image, if any.
    pub hyperlink: Option<String>,
}

impl EmbeddedImage {
    /// Build a `data:` URI suitable for `<img src="…">`.
    pub fn data_uri(&self) -> String {
        format!(
            "data:{};base64,{}",
            self.format.mime_type(),
            self.data_base64
        )
    }

    /// Save the image bytes to `path`.
    ///
    /// # Errors
    /// Propagates I/O errors.
    pub fn save(&self, path: impl AsRef<std::path::Path>) -> Result<()> {
        std::fs::write(path.as_ref(), &self.data).map_err(|e| Error::Io {
            path: path.as_ref().to_owned(),
            source: e,
        })
    }
}

// ── Internal loaders ─────────────────────────────────────────────────────────

/// Extract all images from a ZIP archive (walks `xl/media/`).
#[allow(dead_code)]
pub(crate) fn extract_images_from_zip<R: Read + std::io::Seek>(
    zip: &mut ZipArchive<R>,
) -> Vec<EmbeddedImage> {
    let names: Vec<String> = (0..zip.len())
        .filter_map(|i| zip.by_index(i).ok().map(|f| f.name().to_owned()))
        .filter(|n| n.starts_with("xl/media/"))
        .collect();

    names
        .iter()
        .filter_map(|name| {
            let mut file = zip.by_name(name).ok()?;
            let mut data = Vec::new();
            file.read_to_end(&mut data).ok()?;

            let ext = std::path::Path::new(name)
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("bin");

            let format = ImageFormat::from_ext(ext);
            let data_base64 = B64.encode(&data);
            let (width_px, height_px) = image_dimensions(&data, &format);
            let short_name = std::path::Path::new(name)
                .file_name()
                .and_then(|f| f.to_str())
                .unwrap_or(name)
                .to_owned();

            Some(EmbeddedImage {
                name: short_name,
                format,
                data,
                data_base64,
                width_px,
                height_px,
                anchor: None,
                description: None,
                hyperlink: None,
            })
        })
        .collect()
}

/// Try to read pixel dimensions from the raw image header.
#[allow(dead_code)]
fn image_dimensions(data: &[u8], fmt: &ImageFormat) -> (Option<u32>, Option<u32>) {
    match fmt {
        ImageFormat::Png => png_dims(data),
        ImageFormat::Jpeg => jpeg_dims(data),
        ImageFormat::Bmp => bmp_dims(data),
        _ => (None, None),
    }
}

/// PNG: width/height are at bytes 16-23 of the IHDR chunk.
#[allow(dead_code)]
fn png_dims(data: &[u8]) -> (Option<u32>, Option<u32>) {
    if data.len() >= 24 && data[1..4] == *b"PNG" {
        let w = u32::from_be_bytes([data[16], data[17], data[18], data[19]]);
        let h = u32::from_be_bytes([data[20], data[21], data[22], data[23]]);
        return (Some(w), Some(h));
    }
    (None, None)
}

/// JPEG: scan for SOF0/SOF2 markers.
#[allow(dead_code)]
fn jpeg_dims(data: &[u8]) -> (Option<u32>, Option<u32>) {
    let mut i = 2usize;
    while i + 8 < data.len() {
        if data[i] != 0xFF {
            break;
        }
        let marker = data[i + 1];
        let len = u16::from_be_bytes([data[i + 2], data[i + 3]]) as usize;
        if matches!(marker, 0xC0 | 0xC1 | 0xC2) && i + 7 < data.len() {
            let h = u16::from_be_bytes([data[i + 5], data[i + 6]]) as u32;
            let w = u16::from_be_bytes([data[i + 7], data[i + 8]]) as u32;
            return (Some(w), Some(h));
        }
        i += 2 + len;
    }
    (None, None)
}

/// BMP: width at offset 18, height at offset 22 (little-endian).
#[allow(dead_code)]
fn bmp_dims(data: &[u8]) -> (Option<u32>, Option<u32>) {
    if data.len() >= 26 && data[0] == b'B' && data[1] == b'M' {
        let w = u32::from_le_bytes([data[18], data[19], data[20], data[21]]);
        let h = u32::from_le_bytes([data[22], data[23], data[24], data[25]]);
        return (Some(w), Some(h));
    }
    (None, None)
}

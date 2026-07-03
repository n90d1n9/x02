use serde::{Deserialize, Serialize};

/// Represents an RGBA color value.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub a: u8, // 0 = fully transparent, 255 = fully opaque
}

impl Color {
    /// Create a fully opaque color from RGB values.
    pub fn from_rgb(r: u8, g: u8, b: u8) -> Self {
        Color { r, g, b, a: 255 }
    }

    /// Create a color from RGBA values.
    pub fn from_rgba(r: u8, g: u8, b: u8, a: u8) -> Self {
        Color { r, g, b, a }
    }

    /// Parse a hex color string (e.g., "FF0000" or "#FF0000").
    pub fn from_hex(hex: &str) -> Option<Self> {
        let hex = hex.trim_start_matches('#');
        if hex.len() == 6 {
            let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
            let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
            let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
            Some(Color::from_rgb(r, g, b))
        } else if hex.len() == 8 {
            let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
            let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
            let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
            let a = u8::from_str_radix(&hex[6..8], 16).ok()?;
            Some(Color::from_rgba(r, g, b, a))
        } else {
            None
        }
    }

    /// Convert to hex string (without #).
    pub fn to_hex(&self) -> String {
        format!("{:02X}{:02X}{:02X}", self.r, self.g, self.b)
    }

    /// Convert to CSS rgba() string.
    pub fn to_css(&self) -> String {
        format!("rgba({},{},{},{})", self.r, self.g, self.b, self.a as f32 / 255.0)
    }

    /// Black color constant.
    pub fn black() -> Self { Color::from_rgb(0, 0, 0) }

    /// White color constant.
    pub fn white() -> Self { Color::from_rgb(255, 255, 255) }

    /// Transparent color constant.
    pub fn transparent() -> Self { Color::from_rgba(0, 0, 0, 0) }
}

impl Default for Color {
    fn default() -> Self {
        Color::black()
    }
}

impl std::fmt::Display for Color {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "#{}", self.to_hex())
    }
}

/// Represents a theme color reference in OOXML.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ThemeColor {
    pub theme: String,
    pub tint: Option<f32>,  // -1.0 to 1.0
    pub shade: Option<f32>, // -1.0 to 1.0
    pub lum_mod: Option<f32>,
    pub lum_off: Option<f32>,
}

/// A color that may be a solid color or a theme reference.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum ColorSpec {
    Solid(Color),
    Theme(ThemeColor),
    Preset(String),
    None,
}

impl ColorSpec {
    /// Resolve to a concrete color, using a fallback if theme-dependent.
    pub fn resolve(&self) -> Option<&Color> {
        match self {
            ColorSpec::Solid(c) => Some(c),
            _ => None,
        }
    }
}

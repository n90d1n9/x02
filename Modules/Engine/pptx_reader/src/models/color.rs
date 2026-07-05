//! Color representation for PPTX elements

use serde::{Deserialize, Serialize};

/// Color specification supporting multiple color models
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Color {
    /// Alpha channel (0-255)
    pub a: u8,
    /// Red channel (0-255)
    pub r: u8,
    /// Green channel (0-255)
    pub g: u8,
    /// Blue channel (0-255)
    pub b: u8,
}

impl Color {
    /// Create a new color from RGBA values
    pub fn new(r: u8, g: u8, b: u8, a: u8) -> Self {
        Self { r, g, b, a }
    }
    
    /// Create a color from hex string (#RRGGBB or #RRGGBBAA)
    pub fn from_hex(hex: &str) -> Option<Self> {
        let hex = hex.trim_start_matches('#');
        match hex.len() {
            6 => {
                let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
                let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
                let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
                Some(Self::new(r, g, b, 255))
            }
            8 => {
                let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
                let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
                let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
                let a = u8::from_str_radix(&hex[6..8], 16).ok()?;
                Some(Self::new(r, g, b, a))
            }
            _ => None,
        }
    }
    
    /// Convert to hex string
    pub fn to_hex(&self) -> String {
        if self.a == 255 {
            format!("#{:02X}{:02X}{:02X}", self.r, self.g, self.b)
        } else {
            format!("#{:02X}{:02X}{:02X}{:02X}", self.r, self.g, self.b, self.a)
        }
    }
    
    /// Common colors
    pub const BLACK: Color = Color::new(0, 0, 0, 255);
    pub const WHITE: Color = Color::new(255, 255, 255, 255);
    pub const RED: Color = Color::new(255, 0, 0, 255);
    pub const GREEN: Color = Color::new(0, 255, 0, 255);
    pub const BLUE: Color = Color::new(0, 0, 255, 255);
    pub const TRANSPARENT: Color = Color::new(0, 0, 0, 0);
    
    /// Convert to EMU color value (ARGB as i64)
    pub fn to_emu(&self) -> i64 {
        ((self.a as i64) << 24) | 
        ((self.r as i64) << 16) | 
        ((self.g as i64) << 8) | 
        (self.b as i64)
    }
    
    /// Create from EMU color value
    pub fn from_emu(value: i64) -> Self {
        Self {
            a: ((value >> 24) & 0xFF) as u8,
            r: ((value >> 16) & 0xFF) as u8,
            g: ((value >> 8) & 0xFF) as u8,
            b: (value & 0xFF) as u8,
        }
    }
}

/// Theme color reference with optional tint/shade
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThemeColor {
    /// Theme color index
    pub theme_index: usize,
    /// Optional tint (0.0 - 1.0, lightens the color)
    pub tint: Option<f64>,
    /// Optional shade (0.0 - 1.0, darkens the color)
    pub shade: Option<f64>,
}

impl ThemeColor {
    pub fn new(theme_index: usize) -> Self {
        Self {
            theme_index,
            tint: None,
            shade: None,
        }
    }
    
    pub fn with_tint(mut self, tint: f64) -> Self {
        self.tint = Some(tint.clamp(0.0, 1.0));
        self
    }
    
    pub fn with_shade(mut self, shade: f64) -> Self {
        self.shade = Some(shade.clamp(0.0, 1.0));
        self
    }
}

/// Standard Office theme color indices
pub mod theme_colors {
    pub const BACKGROUND_1: usize = 0;
    pub const TEXT_1: usize = 1;
    pub const BACKGROUND_2: usize = 2;
    pub const TEXT_2: usize = 3;
    pub const ACCENT_1: usize = 4;
    pub const ACCENT_2: usize = 5;
    pub const ACCENT_3: usize = 6;
    pub const ACCENT_4: usize = 7;
    pub const ACCENT_5: usize = 8;
    pub const ACCENT_6: usize = 9;
    pub const HYPERLINK: usize = 10;
    pub const FOLLOWED_HYPERLINK: usize = 11;
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_color_from_hex() {
        let color = Color::from_hex("#FF0000").unwrap();
        assert_eq!(color.r, 255);
        assert_eq!(color.g, 0);
        assert_eq!(color.b, 0);
        assert_eq!(color.a, 255);
        
        let color = Color::from_hex("#80FF0000").unwrap();
        assert_eq!(color.a, 128);
    }
    
    #[test]
    fn test_color_to_hex() {
        let color = Color::new(255, 0, 0, 255);
        assert_eq!(color.to_hex(), "#FF0000");
        
        let color = Color::new(255, 0, 0, 128);
        assert_eq!(color.to_hex(), "#FF000080");
    }
    
    #[test]
    fn test_emu_conversion() {
        let color = Color::new(255, 128, 64, 200);
        let emu = color.to_emu();
        let restored = Color::from_emu(emu);
        assert_eq!(color, restored);
    }
}

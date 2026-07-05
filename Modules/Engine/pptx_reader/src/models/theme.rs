//! Theme model - defines colors, fonts, and effects

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Presentation Theme - defines color scheme, fonts, and effects
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    /// Unique identifier
    pub id: String,
    /// Theme name
    pub name: Option<String>,
    /// Color scheme (accent colors, background, text colors)
    pub colors: HashMap<String, String>,
    /// Font scheme (heading and body fonts)
    pub fonts: FontScheme,
    /// Effect scheme (shadow, glow, etc.)
    pub effects: Option<EffectScheme>,
}

impl Theme {
    pub fn new(id: &str) -> Self {
        Self {
            id: id.to_string(),
            name: None,
            colors: HashMap::new(),
            fonts: FontScheme::default(),
            effects: None,
        }
    }
    
    pub fn add_color(&mut self, name: &str, value: &str) {
        self.colors.insert(name.to_string(), value.to_string());
    }
    
    pub fn get_color(&self, name: &str) -> Option<&String> {
        self.colors.get(name)
    }
}

impl Default for Theme {
    fn default() -> Self {
        let mut theme = Self::new("default-theme");
        theme.name = Some("Default Theme".to_string());
        
        // Add default Office theme colors
        theme.add_color("dk1", "000000");  // Dark 1
        theme.add_color("lt1", "FFFFFF");  // Light 1
        theme.add_color("dk2", "1F497D");  // Dark 2
        theme.add_color("lt2", "EEECE1");  // Light 2
        theme.add_color("accent1", "4F81BD");  // Accent 1
        theme.add_color("accent2", "C0504D");  // Accent 2
        theme.add_color("accent3", "9BBB59");  // Accent 3
        theme.add_color("accent4", "8064A2");  // Accent 4
        theme.add_color("accent5", "4BACC6");  // Accent 5
        theme.add_color("accent6", "F79646");  // Accent 6
        
        theme
    }
}

/// Font Scheme - defines heading and body fonts
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FontScheme {
    /// Heading font family
    pub heading_font: String,
    /// Body font family
    pub body_font: String,
}

impl Default for FontScheme {
    fn default() -> Self {
        Self {
            heading_font: "Calibri Light".to_string(),
            body_font: "Calibri".to_string(),
        }
    }
}

/// Effect Scheme - defines visual effects
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EffectScheme {
    /// Shadow preset
    pub shadow: Option<String>,
    /// Glow preset
    pub glow: Option<String>,
    /// Reflection preset
    pub reflection: Option<String>,
    /// Soft edges preset
    pub soft_edges: Option<String>,
}

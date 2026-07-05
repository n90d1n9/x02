//! Text model - text frames, paragraphs, and runs

use serde::{Deserialize, Serialize};

/// Text Frame - container for text content in a shape
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TextFrame {
    /// Paragraphs in the text frame
    pub paragraphs: Vec<Paragraph>,
    /// Margins
    pub margin_left: f64,
    pub margin_right: f64,
    pub margin_top: f64,
    pub margin_bottom: f64,
    /// Word wrap enabled
    pub word_wrap: bool,
    /// Vertical alignment
    pub vertical_align: VerticalAlign,
}

impl TextFrame {
    pub fn new() -> Self {
        Self::default()
    }
    
    pub fn add_paragraph(&mut self, paragraph: Paragraph) {
        self.paragraphs.push(paragraph);
    }
    
    pub fn is_empty(&self) -> bool {
        self.paragraphs.is_empty()
    }
}

/// Paragraph - a paragraph of text
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Paragraph {
    /// Text runs in the paragraph
    pub runs: Vec<Run>,
    /// Alignment
    pub alignment: TextAlignment,
    /// Indentation
    pub indent_level: u32,
    /// Line spacing
    pub line_spacing: Option<f64>,
    /// Bullet properties
    pub bullet: Option<Bullet>,
}

impl Paragraph {
    pub fn new() -> Self {
        Self::default()
    }
    
    pub fn add_run(&mut self, run: Run) {
        self.runs.push(run);
    }
    
    pub fn get_text(&self) -> String {
        self.runs.iter().map(|r| r.text.clone()).collect()
    }
}

/// Run - a span of text with consistent formatting
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Run {
    /// Text content
    pub text: String,
    /// Font properties
    pub font: FontProperties,
    /// Hyperlink (if any)
    pub hyperlink: Option<String>,
}

impl Run {
    pub fn new(text: &str) -> Self {
        Self {
            text: text.to_string(),
            font: FontProperties::default(),
            hyperlink: None,
        }
    }
}

/// Font Properties
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FontProperties {
    /// Font family
    pub family: String,
    /// Font size in points
    pub size: f64,
    /// Bold
    pub bold: bool,
    /// Italic
    pub italic: bool,
    /// Underline
    pub underline: bool,
    /// Strikethrough
    pub strikethrough: bool,
    /// Text color
    pub color: Option<String>,
    /// Superscript
    pub superscript: bool,
    /// Subscript
    pub subscript: bool,
}

impl Default for FontProperties {
    fn default() -> Self {
        Self {
            family: "Calibri".to_string(),
            size: 18.0,
            bold: false,
            italic: false,
            underline: false,
            strikethrough: false,
            color: Some("#000000".to_string()),
            superscript: false,
            subscript: false,
        }
    }
}

/// Text Alignment
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TextAlignment {
    Left,
    Center,
    Right,
    Justify,
    Distributed,
}

impl Default for TextAlignment {
    fn default() -> Self {
        TextAlignment::Left
    }
}

/// Vertical Alignment
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum VerticalAlign {
    Top,
    Middle,
    Bottom,
}

impl Default for VerticalAlign {
    fn default() -> Self {
        VerticalAlign::Top
    }
}

/// Bullet Properties
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bullet {
    /// Bullet type
    pub bullet_type: BulletType,
    /// Character for character bullets
    pub character: Option<String>,
    /// Color
    pub color: Option<String>,
    /// Size relative to text
    pub size: Option<f64>,
}

/// Bullet Type
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum BulletType {
    None,
    Character,
    Numbered(NumberedStyle),
    Picture,
}

/// Numbered Style
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NumberedStyle {
    Arabic,      // 1, 2, 3
    AlphaLower,  // a, b, c
    AlphaUpper,  // A, B, C
    RomanLower,  // i, ii, iii
    RomanUpper,  // I, II, III
}

impl Default for Bullet {
    fn default() -> Self {
        Self {
            bullet_type: BulletType::None,
            character: None,
            color: None,
            size: None,
        }
    }
}

/// Text Properties (legacy alias)
pub type TextProperties = FontProperties;

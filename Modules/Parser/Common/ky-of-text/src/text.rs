use serde::{Deserialize, Serialize};
use crate::models::color::ColorSpec;

/// A complete text frame containing paragraphs.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TextFrame {
    pub paragraphs: Vec<Paragraph>,
    /// Word wrap setting.
    pub word_wrap: bool,
    /// Autofit behavior.
    pub autofit: AutofitType,
    /// Text body properties (margins, anchor, etc.).
    pub body_properties: BodyProperties,
}

impl TextFrame {
    /// Extract plain text, joining paragraphs with newlines.
    pub fn plain_text(&self) -> String {
        self.paragraphs
            .iter()
            .map(|p| p.plain_text())
            .collect::<Vec<_>>()
            .join("\n")
    }

    /// Check if the text frame has any non-empty content.
    pub fn is_empty(&self) -> bool {
        self.paragraphs.iter().all(|p| p.is_empty())
    }

    /// Get all hyperlinks within the text frame.
    pub fn hyperlinks(&self) -> Vec<&crate::models::hyperlink::Hyperlink> {
        self.paragraphs.iter().flat_map(|p| p.hyperlinks()).collect()
    }
}

/// A paragraph within a text frame.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Paragraph {
    pub runs: Vec<Run>,
    pub properties: ParagraphProperties,
    /// List level (0 = not a list item, 1-9 = list depth).
    pub list_level: u8,
}

impl Paragraph {
    /// Extract plain text from all runs.
    pub fn plain_text(&self) -> String {
        self.runs.iter().map(|r| r.text.as_str()).collect()
    }

    /// Check if the paragraph is empty.
    pub fn is_empty(&self) -> bool {
        self.runs.iter().all(|r| r.text.is_empty())
    }

    /// Collect hyperlinks from runs in this paragraph.
    pub fn hyperlinks(&self) -> Vec<&crate::models::hyperlink::Hyperlink> {
        self.runs.iter().filter_map(|r| r.hyperlink.as_ref()).collect()
    }
}

/// A text run (a contiguous run of text with the same formatting).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Run {
    pub text: String,
    pub properties: TextProperties,
    /// Optional hyperlink attached to this run.
    pub hyperlink: Option<crate::models::hyperlink::Hyperlink>,
    /// Whether this run is a field (e.g., slide number, date).
    pub field: Option<FieldType>,
}

/// Properties for a text run (rich text formatting).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TextProperties {
    /// Font family name.
    pub font_family: Option<String>,
    /// Font size in hundredths of a point (e.g., 2400 = 24pt).
    pub font_size: Option<i32>,
    pub bold: Option<bool>,
    pub italic: Option<bool>,
    pub underline: Option<UnderlineStyle>,
    pub strikethrough: Option<bool>,
    pub baseline: Option<i32>, // superscript/subscript in percent
    pub color: Option<ColorSpec>,
    pub highlight_color: Option<ColorSpec>,
    pub language: Option<String>,
    pub alt_language: Option<String>,
    pub kerning: Option<u32>,
    pub spacing: Option<i32>, // character spacing in hundredths of a point
    pub caps: Option<CapsStyle>,
    pub shadow: Option<ShadowEffect>,
    pub glow: Option<GlowEffect>,
    pub soft_edge: Option<f64>,
    pub reflection: Option<ReflectionEffect>,
}

impl TextProperties {
    /// Get font size in points.
    pub fn font_size_pt(&self) -> Option<f64> {
        self.font_size.map(|s| s as f64 / 100.0)
    }

    /// Check if text is superscript (baseline > 0).
    pub fn is_superscript(&self) -> bool {
        self.baseline.map(|b| b > 0).unwrap_or(false)
    }

    /// Check if text is subscript (baseline < 0).
    pub fn is_subscript(&self) -> bool {
        self.baseline.map(|b| b < 0).unwrap_or(false)
    }
}

/// Paragraph-level formatting properties.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ParagraphProperties {
    pub alignment: TextAlignment,
    pub indent: Option<i32>,     // EMU
    pub margin_left: Option<i32>, // EMU
    pub margin_right: Option<i32>, // EMU
    pub space_before: Option<SpacingSpec>,
    pub space_after: Option<SpacingSpec>,
    pub line_spacing: Option<SpacingSpec>,
    pub bullet: Option<BulletStyle>,
    pub tab_stops: Vec<TabStop>,
    /// Default run properties inherited by runs in this paragraph.
    pub default_run_props: Option<TextProperties>,
    pub rtl: bool,
}

/// Text body (frame) layout properties.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct BodyProperties {
    pub anchor: VerticalAnchor,
    pub anchor_ctr: bool,
    pub margin_top: Option<i32>,    // EMU
    pub margin_bottom: Option<i32>, // EMU
    pub margin_left: Option<i32>,   // EMU
    pub margin_right: Option<i32>,  // EMU
    pub columns: Option<u32>,
    pub column_spacing: Option<i32>,
    pub text_direction: TextDirection,
}

// --- Enumerations ---

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub enum TextAlignment {
    #[default]
    Left,
    Center,
    Right,
    Justify,
    JustifyLow,
    Distributed,
    ThaiDistributed,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub enum VerticalAnchor {
    #[default]
    Top,
    Middle,
    Bottom,
    TopCentered,
    MiddleCentered,
    BottomCentered,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub enum TextDirection {
    #[default]
    Horizontal,
    Vertical90,
    Vertical270,
    WordArtVertical,
    EastAsianVertical,
    MongolianVertical,
    WordArtVerticalRtl,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub enum AutofitType {
    #[default]
    None,
    Normal,
    ShapeAutofit,
    NormAutofit { font_scale: f32, line_space_reduction: f32 },
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum UnderlineStyle {
    Single,
    Double,
    Thick,
    Dotted,
    DottedHeavy,
    Dash,
    DashHeavy,
    DashLong,
    DashLongHeavy,
    DotDash,
    DotDashHeavy,
    DotDotDash,
    DotDotDashHeavy,
    Wavy,
    WavyHeavy,
    WavyDouble,
    Words,
    None,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum CapsStyle { None, Small, All }

/// Spacing spec - either in points or percent.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum SpacingSpec {
    /// Spacing in hundredths of a point.
    Points(i32),
    /// Spacing as percentage (100000 = 100%).
    Percent(i32),
}

/// Bullet/list style for a paragraph.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum BulletStyle {
    None,
    Char {
        char: String,
        color: Option<ColorSpec>,
        size: Option<BulletSize>,
        font: Option<String>,
    },
    Auto {
        type_: NumberingType,
        start_at: Option<i32>,
        color: Option<ColorSpec>,
        size: Option<BulletSize>,
    },
    Picture {
        relationship_id: String,
    },
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum BulletSize {
    Points(i32),
    Percent(i32),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum NumberingType {
    ArabicPeriod, ArabicParenR, RomanUcPeriod, RomanLcPeriod,
    AlphaUcPeriod, AlphaLcPeriod, AlphaUcParenR, AlphaLcParenR,
    Arabic1Minus, Arabic2Minus, Hebrew2Minus, ThaiAlphaPeriod,
    ThaiAlphaParenR, ThaiAlphaParenBoth, ThaiNumPeriod,
    ThaiNumParenR, ThaiNumParenBoth, HindiAlphaPeriod, HindiNumPeriod,
    HindiNumParenR, HindiAlpha1Period, CircleNumDbPlain,
    CircleNumWdBlackPlain, CircleNumWdWhitePlain,
    ArabicDbPeriod, ArabicDbPlain, Ea1ChsPeriod, Ea1ChsPlain,
    Ea1ChtPeriod, Ea1ChtPlain, Ea1JpnChsDbPeriod, Ea1JpnKorPlain,
    Ea1JpnKorPeriod,
}

/// Tab stop definition.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TabStop {
    pub position: i32, // EMU
    pub alignment: TabStopAlignment,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TabStopAlignment { Left, Center, Right, Decimal }

/// Shadow effect on text.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShadowEffect {
    pub blur_radius: f64,
    pub distance: f64,
    pub direction: f64,
    pub color: ColorSpec,
    pub alpha: f32,
}

/// Glow effect on text.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GlowEffect {
    pub radius: f64,
    pub color: ColorSpec,
    pub alpha: f32,
}

/// Reflection effect on text.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ReflectionEffect {
    pub blur_radius: f64,
    pub alpha: f32,
    pub start_pos: f64,
    pub end_pos: f64,
    pub distance: f64,
    pub direction: f64,
}

/// Field types for auto-updating text runs.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum FieldType {
    SlideNumber,
    SlideName,
    DateTime { format: String },
    Custom(String),
}

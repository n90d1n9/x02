//! Shape model definitions for Office documents.
//!
//! This module provides comprehensive shape data structures including geometry,
//! formatting, text content, and positioning information.

use serde::{Deserialize, Serialize};
use crate::types::ShapeType;

/// Represents a shape in an Office document.
///
/// A shape is a versatile object that can represent various visual elements
/// including basic shapes, arrows, flowchart symbols, callouts, and more.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Shape {
    /// Unique identifier for the shape within the document.
    pub id: String,
    
    /// The type of shape (rectangle, ellipse, arrow, etc.).
    pub shape_type: ShapeType,
    
    /// Position and size of the shape (in EMUs - English Metric Units).
    pub geometry: ShapeGeometry,
    
    /// Optional text content within the shape.
    pub text: Option<ShapeText>,
    
    /// Fill properties for the shape.
    pub fill: Option<ShapeFill>,
    
    /// Outline/line properties for the shape.
    pub outline: Option<ShapeOutline>,
    
    /// Effect properties (shadow, glow, reflection, etc.).
    pub effects: Option<ShapeEffects>,
    
    /// 3D properties for the shape.
    pub three_d: Option<Shape3D>,
    
    /// Text transformation/warp effects.
    pub text_transform: Option<TextTransform>,
    
    /// Whether the shape is locked.
    pub locked: bool,
    
    /// Alternative text for accessibility.
    pub alt_text: Option<String>,
    
    /// Name of the shape.
    pub name: Option<String>,
    
    /// Z-order position (layering).
    pub z_order: u32,
    
    /// Whether the shape is hidden.
    pub hidden: bool,
    
    /// Rotation angle in degrees.
    pub rotation: f64,
    
    /// Horizontal flip.
    pub flip_horizontal: bool,
    
    /// Vertical flip.
    pub flip_vertical: bool,
}

/// Geometry information for a shape including position and size.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShapeGeometry {
    /// X coordinate of the top-left corner (in EMUs).
    pub x: i64,
    
    /// Y coordinate of the top-left corner (in EMUs).
    pub y: i64,
    
    /// Width of the shape (in EMUs).
    pub width: i64,
    
    /// Height of the shape (in EMUs).
    pub height: i64,
    
    /// Optional adjustment values for customizing shape geometry.
    /// These control handles and shape-specific parameters.
    pub adjustments: Vec<f64>,
    
    /// Connection points for connectors.
    pub connection_sites: Vec<ConnectionSite>,
}

/// A connection site on a shape where connectors can attach.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConnectionSite {
    /// Index of the connection site.
    pub index: u32,
    
    /// X position relative to shape bounds (0.0-1.0).
    pub x: f64,
    
    /// Y position relative to shape bounds (0.0-1.0).
    pub y: f64,
    
    /// Direction of the connection (angle in degrees).
    pub direction: f64,
}

/// Text content within a shape.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShapeText {
    /// The plain text content.
    pub content: String,
    
    /// Rich text formatting runs.
    pub runs: Vec<TextRun>,
    
    /// Paragraph properties.
    pub paragraphs: Vec<ParagraphProperties>,
    
    /// Text anchoring (top, center, bottom, etc.).
    pub anchor: TextAnchor,
    
    /// Whether text is wrapped within the shape.
    pub wrap_text: bool,
    
    /// Margins inside the shape (left, right, top, bottom in EMUs).
    pub margins: TextMargins,
    
    /// Text direction (horizontal, vertical, etc.).
    pub direction: TextDirection,
}

/// A run of text with specific formatting.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TextRun {
    /// The text content of this run.
    pub text: String,
    
    /// Font properties.
    pub font: FontProperties,
    
    /// Highlight color.
    pub highlight: Option<String>,
    
    /// Language ID.
    pub language_id: Option<String>,
}

/// Font properties for text.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FontProperties {
    /// Font family name.
    pub family: String,
    
    /// Font size in points.
    pub size: f64,
    
    /// Whether the text is bold.
    pub bold: bool,
    
    /// Whether the text is italic.
    pub italic: bool,
    
    /// Whether the text is underlined.
    pub underline: bool,
    
    /// Underline style.
    pub underline_style: UnderlineStyle,
    
    /// Text color.
    pub color: String,
    
    /// Strikethrough.
    pub strikethrough: bool,
    
    /// Superscript/subscript (-1 for subscript, 1 for superscript, 0 for none).
    pub baseline_offset: i8,
}

/// Underline styles.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum UnderlineStyle {
    None,
    Single,
    Double,
    Thick,
    Dotted,
    Dash,
    DotDash,
    DotDotDash,
    Wave,
    HeavyWave,
    LongDash,
}

/// Paragraph properties.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ParagraphProperties {
    /// Alignment (left, center, right, justify).
    pub alignment: ParagraphAlignment,
    
    /// Left indent (in EMUs).
    pub left_indent: i64,
    
    /// Right indent (in EMUs).
    pub right_indent: i64,
    
    /// First line indent (in EMUs).
    pub first_line_indent: i64,
    
    /// Line spacing.
    pub line_spacing: LineSpacing,
    
    /// Space before paragraph (in EMUs).
    pub space_before: i64,
    
    /// Space after paragraph (in EMUs).
    pub space_after: i64,
    
    /// Bullet or numbering information.
    pub bullet: Option<BulletInfo>,
}

/// Paragraph alignment options.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ParagraphAlignment {
    Left,
    Center,
    Right,
    Justify,
    Distribute,
    ThaiDistribute,
}

/// Line spacing information.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LineSpacing {
    /// Type of line spacing (auto, exact, atLeast).
    pub line_rule: LineRule,
    
    /// Spacing value.
    pub value: i64,
}

/// Line spacing rules.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum LineRule {
    Auto,
    Exact,
    AtLeast,
}

/// Bullet information.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BulletInfo {
    /// Type of bullet (none, autoNumbered, char, pic, blip).
    pub bullet_type: BulletType,
    
    /// Character for character bullets.
    pub character: Option<char>,
    
    /// Font for the bullet character.
    pub font: Option<String>,
    
    /// Auto-numbering scheme.
    pub auto_number_scheme: Option<AutoNumberScheme>,
    
    /// Starting number for auto-numbering.
    pub start_at: Option<u32>,
}

/// Bullet types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum BulletType {
    None,
    AutoNumbered,
    Char,
    Pic,
    Blip,
}

/// Auto-numbering schemes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AutoNumberScheme {
    AlphaLcParenBoth,
    AlphaUcParenBoth,
    AlphaLcPeriod,
    AlphaUcPeriod,
    ArabicParenBoth,
    ArabicPeriod,
    ArabicPlain,
    RomanLcParenBoth,
    RomanUcParenBoth,
    RomanLcPeriod,
    RomanUcPeriod,
    CircleNumWhtBlackPlain,
    CircleNumWhtBlackCircle,
    CircleNumBlackWhitePlain,
    CircleNumBlackWhiteCircle,
    ArabicAlphaDash,
    ArabicAbjadDash,
    HebrewAlphaDash,
    KanjiKoreanPlain,
    KanjiKoreanPeriod,
    ArabicDBPlain,
    ArabicDBPeriod,
    ThaiAlphaPeriod,
    ThaiAlphaParenBoth,
    ThaiAlphaParenR,
    ThaiAlphaParenL,
    ThaiNumericPeriod,
    HindiNumericPeriod,
    HindiAlphaPeriod,
    HindiArabicPeriod,
    HindiChickletPeriod,
    HindiChickletParenR,
    HindiOnePeriod,
    ThaiOnePeriod,
}

/// Text anchoring options.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TextAnchor {
    Top,
    Center,
    Bottom,
    Justified,
    Distributed,
}

/// Text margins within a shape.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TextMargins {
    /// Left margin (in EMUs).
    pub left: i64,
    /// Right margin (in EMUs).
    pub right: i64,
    /// Top margin (in EMUs).
    pub top: i64,
    /// Bottom margin (in EMUs).
    pub bottom: i64,
}

/// Text direction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TextDirection {
    Horizontal,
    Vertical,
    Stacked,
    Vertical270,
    Vertical90,
    WordArtVertical,
}

/// Text transformation effects.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TextTransform {
    /// Transform type (arch, wave, circle, etc.).
    pub transform_type: TransformType,
    
    /// Additional parameters for the transform.
    pub parameters: Vec<f64>,
}

/// Text transform types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum TransformType {
    Plain,
    ArchUp,
    ArchDown,
    Circle,
    Button,
    CurveUp,
    CurveDown,
    CanUp,
    CanDown,
    Wave1,
    Wave2,
    DoubleWave1,
    DoubleWave2,
    Inflate,
    Deflate,
    InflateBottom,
    DeflateBottom,
    InflateTop,
    DeflateTop,
    DeflateInflate,
    DeflateInflateDeflate,
    FadeRight,
    FadeLeft,
    FadeUp,
    FadeDown,
    SlantUp,
    SlantDown,
    CascadeUp,
    CascadeDown,
    Stop,
    TriangleUp,
    TriangleDown,
    ChevronUp,
    ChevronDown,
    RingInside,
    RingOutside,
    ArchUpPour,
    ArchDownPour,
    CirclePour,
    ButtonPour,
    CurveUpPour,
    CurveDownPour,
    CanUpPour,
    CanDownPour,
    Wave1Pour,
    Wave2Pour,
}

/// Shape fill properties.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShapeFill {
    /// Fill type (solid, gradient, pattern, picture, etc.).
    pub fill_type: FillType,
    
    /// Solid color (if applicable).
    pub solid_color: Option<SolidFill>,
    
    /// Gradient fill (if applicable).
    pub gradient: Option<GradientFill>,
    
    /// Pattern fill (if applicable).
    pub pattern: Option<PatternFill>,
    
    /// Picture fill (if applicable).
    pub picture: Option<PictureFill>,
    
    /// Transparency (0.0-1.0).
    pub transparency: f64,
}

/// Fill types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum FillType {
    None,
    Solid,
    Gradient,
    Pattern,
    Picture,
    Blip,
    Group,
}

/// Solid color fill.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SolidFill {
    /// Color value (RGB or theme reference).
    pub color: ColorRef,
}

/// Color reference (can be RGB or theme-based).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(untagged)]
pub enum ColorRef {
    /// RGB color in hex format (e.g., "FF0000" for red).
    Rgb(String),
    /// Theme color reference.
    Theme(ThemeColor),
    /// Scheme color.
    Scheme(SchemeColor),
}

/// Theme color reference.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ThemeColor {
    /// Theme color index.
    pub theme_index: u32,
    /// Optional tint/shade (-1.0 to 1.0).
    pub tint: Option<f64>,
}

/// Scheme color reference.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum SchemeColor {
    Background1,
    Text1,
    Background2,
    Text2,
    Accent1,
    Accent2,
    Accent3,
    Accent4,
    Accent5,
    Accent6,
    Hyperlink,
    FollowedHyperlink,
    PhLight1,
    PhDark1,
    PhLight2,
    PhDark2,
}

/// Gradient fill.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GradientFill {
    /// Gradient direction.
    pub direction: GradientDirection,
    
    /// Gradient stops.
    pub stops: Vec<GradientStop>,
    
    /// Gradient path shape.
    pub path: GradientPath,
    
    /// Angle in degrees.
    pub angle: f64,
    
    /// Scale factor.
    pub scale: f64,
    
    /// Whether to align with the shape.
    pub align_with_shape: bool,
}

/// Gradient direction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum GradientDirection {
    FromCorner,
    FromCenter,
    Horizontal,
    Vertical,
    Diagonal,
    DiagonalDown,
    DiagonalUp,
}

/// Gradient stop.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GradientStop {
    /// Position along the gradient (0.0-1.0).
    pub position: f64,
    
    /// Color at this stop.
    pub color: ColorRef,
    
    /// Transparency at this stop (0.0-1.0).
    pub transparency: f64,
}

/// Gradient path shapes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum GradientPath {
    Shape,
    Circle,
    Rectangle,
}

/// Pattern fill.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PatternFill {
    /// Pattern type.
    pub pattern_type: PatternType,
    
    /// Foreground color.
    pub foreground_color: ColorRef,
    
    /// Background color.
    pub background_color: ColorRef,
}

/// Pattern types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum PatternType {
    None,
    DarkHorizontal,
    DarkVertical,
    DarkDownDiagonal,
    DarkUpDiagonal,
    DarkGrid,
    DarkTrellis,
    LightHorizontal,
    LightVertical,
    LightDownDiagonal,
    LightUpDiagonal,
    LightGrid,
    LightTrellis,
    GrayHorizontal,
    GrayVertical,
    GrayDownDiagonal,
    GrayUpDiagonal,
    GrayGrid,
    GrayTrellis,
}

/// Picture fill.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PictureFill {
    /// Image data or reference.
    pub image_ref: String,
    
    /// How to stretch/crop the image.
    pub stretch: StretchMode,
    
    /// Tile settings (if tiling).
    pub tile: Option<TileSettings>,
    
    /// DPI settings.
    pub dpi: Option<DpiSettings>,
}

/// Stretch modes for picture fills.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum StretchMode {
    Fill,
    Fit,
    Normal,
    None,
}

/// Tile settings for picture fills.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TileSettings {
    /// Tile offset X.
    pub offset_x: f64,
    /// Tile offset Y.
    pub offset_y: f64,
    /// Tile scale X.
    pub scale_x: f64,
    /// Tile scale Y.
    pub scale_y: f64,
    /// Tile flip mode.
    pub flip: TileFlip,
    /// Alignment.
    pub alignment: TileAlignment,
}

/// Tile flip modes.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TileFlip {
    None,
    Horizontal,
    Vertical,
    Both,
}

/// Tile alignment.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TileAlignment {
    TopLeft,
    Top,
    TopRight,
    Left,
    Center,
    Right,
    BottomLeft,
    Bottom,
    BottomRight,
}

/// DPI settings.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct DpiSettings {
    /// Horizontal DPI.
    pub dpi_x: u32,
    /// Vertical DPI.
    pub dpi_y: u32,
}

/// Shape outline (line) properties.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShapeOutline {
    /// Color of the outline.
    pub color: ColorRef,
    
    /// Width of the outline (in EMUs).
    pub width: i64,
    
    /// Line style (solid, dash, etc.).
    pub line_style: LineStyle,
    
    /// Cap type (flat, round, square).
    pub cap_type: CapType,
    
    /// Join type (round, bevel, miter).
    pub join_type: JoinType,
    
    /// Dash pattern (if dashed).
    pub dash_pattern: Option<DashPattern>,
    
    /// Arrowhead at start.
    pub start_arrow: Option<ArrowHead>,
    
    /// Arrowhead at end.
    pub end_arrow: Option<ArrowHead>,
    
    /// Transparency (0.0-1.0).
    pub transparency: f64,
    
    /// Compound line type.
    pub compound_type: CompoundType,
}

/// Line styles.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LineStyle {
    Single,
    ThinThin,
    ThinThick,
    ThickThin,
    ThickBetweenThin,
}

/// Cap types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum CapType {
    Flat,
    Square,
    Round,
}

/// Join types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum JoinType {
    Round,
    Bevel,
    Miter,
}

/// Dash patterns.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DashPattern {
    /// Dash type.
    pub dash_type: DashType,
    /// Custom dash lengths (if custom).
    pub custom_dashes: Option<Vec<i64>>,
}

/// Dash types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum DashType {
    Solid,
    RoundDot,
    SquareDot,
    Dash,
    SysDash,
    SysDot,
    SysDashDot,
    SysDashDotDot,
    DashDot,
    DashDotDot,
    DashLong,
    DashLongDot,
    DashLongDashDotDot,
    Custom,
}

/// Arrowhead definition.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ArrowHead {
    /// Arrowhead type.
    pub arrow_type: ArrowType,
    
    /// Arrowhead length.
    pub length: ArrowLength,
    
    /// Arrowhead width.
    pub width: ArrowWidth,
}

/// Arrow types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ArrowType {
    None,
    Triangle,
    Stealth,
    Diamond,
    Oval,
    Arrow,
}

/// Arrow lengths.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ArrowLength {
    Small,
    Medium,
    Large,
}

/// Arrow widths.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ArrowWidth {
    Small,
    Medium,
    Large,
}

/// Compound line types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum CompoundType {
    Single,
    Double,
    ThickBetweenThin,
    ThinThick,
    ThickThin,
    Triple,
}

/// Shape effects (shadow, glow, reflection, soft edges, 3D).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShapeEffects {
    /// Shadow effect.
    pub shadow: Option<ShadowEffect>,
    
    /// Glow effect.
    pub glow: Option<GlowEffect>,
    
    /// Reflection effect.
    pub reflection: Option<ReflectionEffect>,
    
    /// Soft edge effect.
    pub soft_edge: Option<SoftEdgeEffect>,
    
    /// Bevel effect.
    pub bevel: Option<BevelEffect>,
    
    /// 3D rotation.
    pub rotation_3d: Option<Rotation3D>,
    
    /// Scene lighting.
    pub lighting: Option<Lighting>,
}

/// Shadow effect.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShadowEffect {
    /// Shadow type (outer, inner, perspective).
    pub shadow_type: ShadowType,
    
    /// Blur radius (in EMUs).
    pub blur_radius: i64,
    
    /// Distance from shape (in EMUs).
    pub distance: i64,
    
    /// Direction in degrees.
    pub direction: f64,
    
    /// Shadow color.
    pub color: ColorRef,
    
    /// Transparency (0.0-1.0).
    pub transparency: f64,
    
    /// Size scale.
    pub size_scale: f64,
    
    /// Whether shadow is aligned with shape.
    pub align_with_shape: bool,
}

/// Shadow types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ShadowType {
    Outer,
    Inner,
    Perspective,
}

/// Glow effect.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GlowEffect {
    /// Glow radius (in EMUs).
    pub radius: i64,
    
    /// Glow color.
    pub color: ColorRef,
}

/// Reflection effect.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ReflectionEffect {
    /// Start position (0.0-1.0).
    pub start_pos: f64,
    
    /// End position (0.0-1.0).
    pub end_pos: f64,
    
    /// Direction in degrees.
    pub direction: f64,
    
    /// Distance from shape (in EMUs).
    pub distance: i64,
    
    /// Blur radius (in EMUs).
    pub blur_radius: i64,
    
    /// Size scale.
    pub size_scale: f64,
    
    /// Transparency at start (0.0-1.0).
    pub start_transparency: f64,
    
    /// Transparency at end (0.0-1.0).
    pub end_transparency: f64,
    
    /// Rotate shadow with shape.
    pub rotate_shadow_with_shape: bool,
}

/// Soft edge effect.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SoftEdgeEffect {
    /// Soft edge radius (in EMUs).
    pub radius: i64,
}

/// Bevel effect.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BevelEffect {
    /// Top bevel.
    pub top: Option<Bevel>,
    
    /// Bottom bevel.
    pub bottom: Option<Bevel>,
    
    /// Extrusion height (in EMUs).
    pub extrusion_height: i64,
    
    /// Extrusion color.
    pub extrusion_color: Option<ColorRef>,
    
    /// Contour width (in EMUs).
    pub contour_width: i64,
    
    /// Contour color.
    pub contour_color: Option<ColorRef>,
}

/// Bevel definition.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Bevel {
    /// Bevel type.
    pub bevel_type: BevelType,
    
    /// Width (in EMUs).
    pub width: i64,
    
    /// Height (in EMUs).
    pub height: i64,
}

/// Bevel types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum BevelType {
    None,
    RelaxedInset,
    Circle,
    Slope,
    Cross,
    Angle,
    SoftRound,
    Convex,
    CoolSlant,
    Divot,
    Riblet,
    HardEdge,
}

/// 3D rotation.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Rotation3D {
    /// Rotation around X axis (in 60000ths of a degree).
    pub rot_x: i64,
    
    /// Rotation around Y axis (in 60000ths of a degree).
    pub rot_y: i64,
    
    /// Rotation around Z axis (in 60000ths of a degree).
    pub rot_z: i64,
    
    /// Field of view (in 60000ths of a degree).
    pub field_of_view: i64,
    
    /// Perspective type.
    pub perspective: PerspectiveType,
    
    /// Keep text flat (not rotated in 3D).
    pub keep_text_flat: bool,
}

/// Perspective types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PerspectiveType {
    Off,
    Front,
    OpposingFront,
    Left,
    Right,
    Above,
    Below,
    ObliqueTop,
    ObliqueBottom,
    ObliqueLeft,
    ObliqueRight,
    IsometricTopUp,
    IsometricTopDown,
    IsometricBottomUp,
    IsometricBottomDown,
    IsometricLeftUp,
    IsometricLeftDown,
    IsometricRightUp,
    IsometricRightDown,
    IsometricOffAxis1Left,
    IsometricOffAxis1Right,
    IsometricOffAxis1Top,
    IsometricOffAxis2Left,
    IsometricOffAxis2Right,
    IsometricOffAxis2Top,
    IsometricOffAxis3Left,
    IsometricOffAxis3Right,
    IsometricOffAxis3Bottom,
    IsometricOffAxis4Left,
    IsometricOffAxis4Right,
    IsometricOffAxis4Bottom,
}

/// Lighting for 3D effects.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Lighting {
    LegacyFlat1,
    LegacyFlat2,
    LegacyFlat3,
    LegacyFlat4,
    LegacyHarsh1,
    LegacyHarsh2,
    LegacyHarsh3,
    LegacyHarsh4,
    LegacyNormal1,
    LegacyNormal2,
    LegacyNormal3,
    LegacyNormal4,
    ThreePoint,
    Balanced,
    Soft,
    Harsh,
    Flat,
    TwoPoint,
    Glow,
    BrightRoom,
    Chilly,
    Freezing,
    Morning,
    Sunset,
    Horizon,
    BlueSpotlight,
    GreenSpotlight,
    RedSpotlight,
    TwoSpotlight,
    ThreeSpotlight,
}

/// 3D properties for shapes.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Shape3D {
    /// Depth (extrusion) in EMUs.
    pub depth: i64,
    
    /// Depth color.
    pub depth_color: Option<ColorRef>,
    
    /// Whether to use the shape's fill color for extrusion.
    pub extrude_color_use_shape_fill: bool,
    
    /// Shading method.
    pub shading_method: ShadingMethod,
    
    /// Camera type.
    pub camera: CameraType,
    
    /// Light rig.
    pub light_rig: Lighting,
    
    /// 3D rotation.
    pub rotation: Rotation3D,
    
    /// Contour properties.
    pub contour: Option<ContourProperties>,
}

/// Shading methods.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ShadingMethod {
    Linear,
    ColorGradient,
    TrueGouraud,
}

/// Camera types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum CameraType {
    OrthographicFront,
    IsometricTopUp,
    IsometricTopDown,
    IsometricBottomUp,
    IsometricBottomDown,
    IsometricLeftUp,
    IsometricLeftDown,
    IsometricRightUp,
    IsometricRightDown,
    IsometricOffAxis1Left,
    IsometricOffAxis1Right,
    IsometricOffAxis1Top,
    IsometricOffAxis2Left,
    IsometricOffAxis2Right,
    IsometricOffAxis2Top,
    IsometricOffAxis3Left,
    IsometricOffAxis3Right,
    IsometricOffAxis3Bottom,
    IsometricOffAxis4Left,
    IsometricOffAxis4Right,
    IsometricOffAxis4Bottom,
    PerspectiveFront,
    PerspectiveLeft,
    PerspectiveRight,
    PerspectiveAbove,
    PerspectiveBelow,
    PerspectiveContrastingLeft,
    PerspectiveContrastingRight,
    PerspectiveHeroicLeft,
    PerspectiveHeroicRight,
    PerspectiveHeroicExtremeLeft,
    PerspectiveHeroicExtremeRight,
    PerspectiveRelaxed,
    PerspectiveRelaxedModerately,
}

/// Contour properties.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ContourProperties {
    /// Contour width (in EMUs).
    pub width: i64,
    
    /// Contour color.
    pub color: ColorRef,
}

impl Shape {
    /// Creates a new shape with default properties.
    pub fn new(id: String, shape_type: ShapeType, x: i64, y: i64, width: i64, height: i64) -> Self {
        Shape {
            id,
            shape_type,
            geometry: ShapeGeometry {
                x,
                y,
                width,
                height,
                adjustments: Vec::new(),
                connection_sites: Vec::new(),
            },
            text: None,
            fill: Some(ShapeFill {
                fill_type: FillType::Solid,
                solid_color: Some(SolidFill {
                    color: ColorRef::Rgb("FFFFFF".to_string()),
                }),
                gradient: None,
                pattern: None,
                picture: None,
                transparency: 0.0,
            }),
            outline: Some(ShapeOutline {
                color: ColorRef::Rgb("000000".to_string()),
                width: 12700, // 1 point in EMUs
                line_style: LineStyle::Single,
                cap_type: CapType::Flat,
                join_type: JoinType::Round,
                dash_pattern: None,
                start_arrow: None,
                end_arrow: None,
                transparency: 0.0,
                compound_type: CompoundType::Single,
            }),
            effects: None,
            three_d: None,
            text_transform: None,
            locked: false,
            alt_text: None,
            name: None,
            z_order: 0,
            hidden: false,
            rotation: 0.0,
            flip_horizontal: false,
            flip_vertical: false,
        }
    }

    /// Sets the alternative text for accessibility.
    pub fn with_alt_text(mut self, alt_text: String) -> Self {
        self.alt_text = Some(alt_text);
        self
    }

    /// Sets the shape name.
    pub fn with_name(mut self, name: String) -> Self {
        self.name = Some(name);
        self
    }

    /// Sets the rotation angle.
    pub fn with_rotation(mut self, rotation: f64) -> Self {
        self.rotation = rotation;
        self
    }

    /// Checks if the shape contains text.
    pub fn has_text(&self) -> bool {
        self.text.is_some() && !self.text.as_ref().unwrap().content.is_empty()
    }

    /// Gets the bounding box of the shape.
    pub fn bounding_box(&self) -> (i64, i64, i64, i64) {
        (self.geometry.x, self.geometry.y, self.geometry.width, self.geometry.height)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_rectangle() {
        let shape = Shape::new(
            "rect1".to_string(),
            ShapeType::Rectangle,
            100000,
            100000,
            200000,
            100000,
        );
        
        assert_eq!(shape.id, "rect1");
        assert_eq!(shape.shape_type, ShapeType::Rectangle);
        assert_eq!(shape.geometry.x, 100000);
        assert_eq!(shape.geometry.y, 100000);
        assert!(!shape.has_text());
    }

    #[test]
    fn test_shape_with_alt_text() {
        let shape = Shape::new(
            "arrow1".to_string(),
            ShapeType::RightArrow,
            0,
            0,
            100000,
            50000,
        )
        .with_alt_text("Right arrow pointing to next step".to_string())
        .with_name("NextButton".to_string());
        
        assert_eq!(shape.alt_text, Some("Right arrow pointing to next step".to_string()));
        assert_eq!(shape.name, Some("NextButton".to_string()));
    }

    #[test]
    fn test_bounding_box() {
        let shape = Shape::new(
            "box1".to_string(),
            ShapeType::Diamond,
            50000,
            75000,
            150000,
            100000,
        );
        
        let (x, y, w, h) = shape.bounding_box();
        assert_eq!(x, 50000);
        assert_eq!(y, 75000);
        assert_eq!(w, 150000);
        assert_eq!(h, 100000);
    }
}

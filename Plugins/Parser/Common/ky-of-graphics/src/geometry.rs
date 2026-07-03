use serde::{Deserialize, Serialize};

/// Position and size of a shape on a slide.
/// All values are in EMUs (English Metric Units).
/// 1 inch = 914400 EMUs, 1 cm = 360000 EMUs, 1 pt = 12700 EMUs.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub struct Geometry {
    /// X position from left edge of slide (EMU).
    pub x: i64,
    /// Y position from top edge of slide (EMU).
    pub y: i64,
    /// Width of the shape (EMU).
    pub width: i64,
    /// Height of the shape (EMU).
    pub height: i64,
    /// Rotation in degrees (clockwise, 0-360).
    pub rotation: f64,
    /// Whether the shape is flipped horizontally.
    pub flip_h: bool,
    /// Whether the shape is flipped vertically.
    pub flip_v: bool,
}

impl Geometry {
    pub fn new(x: i64, y: i64, width: i64, height: i64) -> Self {
        Geometry { x, y, width, height, rotation: 0.0, flip_h: false, flip_v: false }
    }

    /// Convert X position to inches.
    pub fn x_inches(&self) -> f64 { self.x as f64 / 914400.0 }
    /// Convert Y position to inches.
    pub fn y_inches(&self) -> f64 { self.y as f64 / 914400.0 }
    /// Convert width to inches.
    pub fn width_inches(&self) -> f64 { self.width as f64 / 914400.0 }
    /// Convert height to inches.
    pub fn height_inches(&self) -> f64 { self.height as f64 / 914400.0 }

    /// Convert X position to centimeters.
    pub fn x_cm(&self) -> f64 { self.x as f64 / 360000.0 }
    /// Convert Y position to centimeters.
    pub fn y_cm(&self) -> f64 { self.y as f64 / 360000.0 }
    /// Convert width to centimeters.
    pub fn width_cm(&self) -> f64 { self.width as f64 / 360000.0 }
    /// Convert height to centimeters.
    pub fn height_cm(&self) -> f64 { self.height as f64 / 360000.0 }

    /// Convert X position to points.
    pub fn x_pt(&self) -> f64 { self.x as f64 / 12700.0 }
    /// Convert Y position to points.
    pub fn y_pt(&self) -> f64 { self.y as f64 / 12700.0 }
    /// Convert width to points.
    pub fn width_pt(&self) -> f64 { self.width as f64 / 12700.0 }
    /// Convert height to points.
    pub fn height_pt(&self) -> f64 { self.height as f64 / 12700.0 }
}

/// Predefined shape geometry type (DrawingML preset geometries).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum PresetGeometry {
    Rectangle,
    RoundedRectangle,
    Ellipse,
    Triangle,
    RightTriangle,
    Diamond,
    Arrow,
    Star,
    Callout,
    Line,
    Custom,
    Other(String),
}

impl PresetGeometry {
    pub fn from_str(s: &str) -> Self {
        match s {
            "rect" => PresetGeometry::Rectangle,
            "roundRect" => PresetGeometry::RoundedRectangle,
            "ellipse" => PresetGeometry::Ellipse,
            "triangle" => PresetGeometry::Triangle,
            "rtTriangle" => PresetGeometry::RightTriangle,
            "diamond" => PresetGeometry::Diamond,
            "rightArrow" | "leftArrow" | "upArrow" | "downArrow" => PresetGeometry::Arrow,
            "star4" | "star5" | "star6" | "star7" | "star8" | "star10" | "star12" | "star16" | "star24" | "star32" => PresetGeometry::Star,
            "wedgeRectCallout" | "wedgeRoundRectCallout" | "wedgeEllipseCallout" => PresetGeometry::Callout,
            "line" | "straightConnector1" => PresetGeometry::Line,
            _ => PresetGeometry::Other(s.to_string()),
        }
    }
}

/// Describes a fill style for a shape.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum FillType {
    None,
    Solid { color: crate::models::color::ColorSpec },
    Gradient { stops: Vec<GradientStop>, angle: f64 },
    Pattern { fg_color: crate::models::color::ColorSpec, bg_color: crate::models::color::ColorSpec, pattern: String },
    Picture { relationship_id: String },
    Background,
}

/// A gradient stop with position and color.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct GradientStop {
    pub position: f64, // 0.0 to 100.0 (percent)
    pub color: crate::models::color::ColorSpec,
}

/// Line/border properties for a shape.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct LineProperties {
    pub width: Option<u32>, // in EMU
    pub color: Option<crate::models::color::ColorSpec>,
    pub dash_style: LineDashStyle,
    pub cap_type: LineCapType,
    pub join_type: LineJoinType,
    pub head_arrow: Option<ArrowHead>,
    pub tail_arrow: Option<ArrowHead>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum LineDashStyle {
    Solid, Dash, Dot, DashDot, DashDotDot, LongDash, LongDashDot, None,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum LineCapType { Flat, Round, Square }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum LineJoinType { Round, Bevel, Miter }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ArrowHead {
    pub arrow_type: String,
    pub size: String,
    pub width: String,
}

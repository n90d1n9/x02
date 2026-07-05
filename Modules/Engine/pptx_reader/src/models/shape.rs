//! Shape model - visual elements on slides

use serde::{Deserialize, Serialize};
use crate::models::text::TextFrame;
use crate::models::image::ImageData;
use crate::models::geometry::Geometry;

/// Shape - a visual element on a slide
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Shape {
    /// Unique identifier
    pub id: String,
    /// Optional name
    pub name: Option<String>,
    /// Shape type (rectangle, ellipse, etc.)
    pub shape_type: Option<String>,
    /// Geometry definition
    pub geometry: Geometry,
    /// Fill color or pattern
    pub fill: Option<ShapeFill>,
    /// Outline/stroke
    pub stroke: Option<ShapeStroke>,
    /// Text content (if any)
    pub text_frame: Option<TextFrame>,
    /// Image data (if image shape)
    #[serde(skip_serializing, skip_deserializing)]
    pub image_data: Option<ImageData>,
    /// Transform (position, rotation, scale)
    pub transform: ShapeTransform,
}

impl Shape {
    pub fn new(id: &str) -> Self {
        Self {
            id: id.to_string(),
            name: None,
            shape_type: None,
            geometry: Geometry::default(),
            fill: None,
            stroke: None,
            text_frame: None,
            image_data: None,
            transform: ShapeTransform::default(),
        }
    }
    
    pub fn validate(&self) -> Result<(), crate::error::PptxValidationError> {
        // Basic validation
        if self.id.is_empty() {
            return Err(crate::error::PptxValidationError::InvalidShape(
                "Shape ID cannot be empty".to_string()
            ));
        }
        Ok(())
    }
}

impl Default for Shape {
    fn default() -> Self {
        Self::new("shape-1")
    }
}

/// Shape Fill - color, gradient, or pattern
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShapeFill {
    /// Solid color (hex)
    pub color: Option<String>,
    /// Gradient fill
    pub gradient: Option<GradientFill>,
    /// Pattern fill
    pub pattern: Option<PatternFill>,
    /// Transparency (0.0 - 1.0)
    pub transparency: f64,
}

impl Default for ShapeFill {
    fn default() -> Self {
        Self {
            color: None,
            gradient: None,
            pattern: None,
            transparency: 0.0,
        }
    }
}

/// Gradient Fill
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradientFill {
    /// Gradient type (linear, radial)
    pub gradient_type: String,
    /// Angle in degrees
    pub angle: f64,
    /// Gradient stops
    pub stops: Vec<GradientStop>,
}

/// Gradient Stop
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradientStop {
    /// Position (0.0 - 1.0)
    pub position: f64,
    /// Color
    pub color: String,
}

/// Pattern Fill
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatternFill {
    /// Pattern type
    pub pattern_type: String,
    /// Foreground color
    pub fg_color: String,
    /// Background color
    pub bg_color: String,
}

/// Shape Stroke/Outline
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShapeStroke {
    /// Color
    pub color: String,
    /// Width in points
    pub width: f64,
    /// Dash pattern
    pub dash: Option<StrokeDash>,
    /// Cap style
    pub cap: String,
}

impl Default for ShapeStroke {
    fn default() -> Self {
        Self {
            color: "#000000".to_string(),
            width: 1.0,
            dash: None,
            cap: "flat".to_string(),
        }
    }
}

/// Stroke Dash Pattern
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StrokeDash {
    /// Dash lengths
    pub dashes: Vec<f64>,
    /// Gap length
    pub gap: f64,
}

/// Shape Transform
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShapeTransform {
    /// X position
    pub x: f64,
    /// Y position
    pub y: f64,
    /// Width
    pub width: f64,
    /// Height
    pub height: f64,
    /// Rotation angle in degrees
    pub rotation: f64,
    /// Horizontal flip
    pub flip_h: bool,
    /// Vertical flip
    pub flip_v: bool,
}

impl Default for ShapeTransform {
    fn default() -> Self {
        Self {
            x: 0.0,
            y: 0.0,
            width: 100.0,
            height: 100.0,
            rotation: 0.0,
            flip_h: false,
            flip_v: false,
        }
    }
}

/// Shape Type enumeration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ShapeType {
    Rectangle,
    Ellipse,
    Triangle,
    RoundedRectangle,
    Parallelogram,
    Trapezoid,
    Diamond,
    Pentagon,
    Hexagon,
    Octagon,
    Star,
    Arrow,
    Callout,
    TextBox,
    Image,
    Chart,
    Table,
    SmartArt,
    Custom,
}

impl Default for ShapeType {
    fn default() -> Self {
        ShapeType::Rectangle
    }
}

/// Shape Geometry types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ShapeGeometry {
    Rectangle { x: f64, y: f64, width: f64, height: f64 },
    Ellipse { x: f64, y: f64, width: f64, height: f64 },
    Path { path_data: String },
}

impl Default for ShapeGeometry {
    fn default() -> Self {
        ShapeGeometry::Rectangle {
            x: 0.0,
            y: 0.0,
            width: 100.0,
            height: 100.0,
        }
    }
}

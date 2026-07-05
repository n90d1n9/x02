//! Geometry types for shapes and paths

use serde::{Deserialize, Serialize};

/// 2D point
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Point2D {
    pub x: f64,
    pub y: f64,
}

impl Point2D {
    pub fn new(x: f64, y: f64) -> Self { Self { x, y } }
    pub fn origin() -> Self { Self { x: 0.0, y: 0.0 } }
}

/// Path drawing commands
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PathCommand {
    MoveTo { x: f64, y: f64 },
    LineTo { x: f64, y: f64 },
    CurveTo { x1: f64, y1: f64, x2: f64, y2: f64, x: f64, y: f64 },
    ArcTo { rx: f64, ry: f64, rotation: f64, large_arc: bool, sweep: bool, x: f64, y: f64 },
    ClosePath,
}

/// Shape geometry definition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Geometry {
    Rectangle { width: f64, height: f64 },
    Ellipse { radius_x: f64, radius_y: f64 },
    Circle { radius: f64 },
    Triangle { points: [Point2D; 3] },
    Polygon { points: Vec<Point2D> },
    Path { commands: Vec<PathCommand> },
    Preset { name: String, parameters: Vec<f64> },
}

impl Geometry {
    pub fn rectangle(width: f64, height: f64) -> Self {
        Geometry::Rectangle { width, height }
    }
    
    pub fn circle(radius: f64) -> Self {
        Geometry::Circle { radius }
    }
}

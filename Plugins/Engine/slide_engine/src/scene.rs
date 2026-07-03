/// A 2-D point in slide-space (unit = points, 0,0 = top-left of slide).
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Default, Serialize, Deserialize)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Default, Serialize, Deserialize)]
pub struct Size {
    pub width: f64,
    pub height: f64,
}

impl Size {
    pub fn new(width: f64, height: f64) -> Self {
        Self { width, height }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Default, Serialize, Deserialize)]
pub struct Rect {
    pub origin: Point,
    pub size: Size,
}

impl Rect {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        Self {
            origin: Point::new(x, y),
            size: Size::new(width, height),
        }
    }

    pub fn contains(&self, pt: Point) -> bool {
        pt.x >= self.origin.x
            && pt.x <= self.origin.x + self.size.width
            && pt.y >= self.origin.y
            && pt.y <= self.origin.y + self.size.height
    }

    pub fn centre(&self) -> Point {
        Point::new(
            self.origin.x + self.size.width / 2.0,
            self.origin.y + self.size.height / 2.0,
        )
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct Transform {
    pub a: f64,
    pub b: f64,
    pub c: f64,
    pub d: f64,
    pub tx: f64,
    pub ty: f64,
}

impl Default for Transform {
    fn default() -> Self {
        Self::identity()
    }
}

impl Transform {
    pub fn identity() -> Self {
        Self {
            a: 1.0,
            b: 0.0,
            c: 0.0,
            d: 1.0,
            tx: 0.0,
            ty: 0.0,
        }
    }

    pub fn translation(tx: f64, ty: f64) -> Self {
        Self {
            a: 1.0,
            b: 0.0,
            c: 0.0,
            d: 1.0,
            tx,
            ty,
        }
    }

    pub fn rotation_degrees(deg: f64) -> Self {
        let rad = deg.to_radians();
        let (s, c) = (rad.sin(), rad.cos());
        Self {
            a: c,
            b: s,
            c: -s,
            d: c,
            tx: 0.0,
            ty: 0.0,
        }
    }

    pub fn scale(sx: f64, sy: f64) -> Self {
        Self {
            a: sx,
            b: 0.0,
            c: 0.0,
            d: sy,
            tx: 0.0,
            ty: 0.0,
        }
    }

    pub fn then(&self, other: &Transform) -> Transform {
        Transform {
            a: self.a * other.a + self.b * other.c,
            b: self.a * other.b + self.b * other.d,
            c: self.c * other.a + self.d * other.c,
            d: self.c * other.b + self.d * other.d,
            tx: self.tx * other.a + self.ty * other.c + other.tx,
            ty: self.tx * other.b + self.ty * other.d + other.ty,
        }
    }

    pub fn apply(&self, p: Point) -> Point {
        Point {
            x: self.a * p.x + self.c * p.y + self.tx,
            y: self.b * p.x + self.d * p.y + self.ty,
        }
    }
}

#[derive(Debug, Default, Serialize, Deserialize, Clone)]
pub struct SceneGraph {
    pub z_order: Vec<String>,
}

impl SceneGraph {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn push(&mut self, id: impl Into<String>) {
        self.z_order.push(id.into());
    }

    pub fn remove(&mut self, id: &str) {
        self.z_order.retain(|s| s != id);
    }

    pub fn bring_to_front(&mut self, id: &str) {
        self.remove(id);
        self.z_order.push(id.to_owned());
    }

    pub fn send_to_back(&mut self, id: &str) {
        let owned = id.to_owned();
        self.remove(id);
        self.z_order.insert(0, owned);
    }

    pub fn move_forward(&mut self, id: &str) {
        if let Some(i) = self.z_order.iter().position(|s| s == id) {
            if i + 1 < self.z_order.len() {
                self.z_order.swap(i, i + 1);
            }
        }
    }

    pub fn move_backward(&mut self, id: &str) {
        if let Some(i) = self.z_order.iter().position(|s| s == id) {
            if i > 0 {
                self.z_order.swap(i, i - 1);
            }
        }
    }

    pub fn draw_order(&self) -> &[String] {
        &self.z_order
    }
}

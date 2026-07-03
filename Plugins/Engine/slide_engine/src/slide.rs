use crate::scene::{Point, SceneGraph, Size};
use crate::shape::Shape;
use rustc_hash::FxHashMap;
use serde::{Deserialize, Serialize};

/// Standard slide dimensions (points), matching Google Slides default.
pub const DEFAULT_SLIDE_WIDTH: f64 = 720.0;
pub const DEFAULT_SLIDE_HEIGHT: f64 = 405.0;

/// Represents a single slide in a presentation.
#[derive(Debug, Default, Serialize, Deserialize, Clone)]
pub struct Slide {
    pub id: String,
    pub title: Option<String>,
    pub size: Size,
    pub background: crate::shape::Fill,
    /// All shapes keyed by their id.
    pub shapes: FxHashMap<String, Shape>,
    /// Z-ordering for the scene.
    pub scene_graph: SceneGraph,
}

impl Slide {
    pub fn new(id: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            size: Size::new(DEFAULT_SLIDE_WIDTH, DEFAULT_SLIDE_HEIGHT),
            ..Default::default()
        }
    }

    /// Add a shape, placing it on top of the z-stack.
    pub fn add_shape(&mut self, shape: Shape) {
        let id = shape.id.clone();
        self.scene_graph.remove(&id);
        self.shapes.insert(id.clone(), shape);
        self.scene_graph.push(id);
    }

    /// Remove a shape by id. Returns the shape if it existed.
    pub fn remove_shape(&mut self, id: &str) -> Option<Shape> {
        self.scene_graph.remove(id);
        self.shapes.remove(id)
    }

    /// Bring a shape to the front (rendered last = on top visually).
    pub fn bring_to_front(&mut self, id: &str) {
        self.scene_graph.bring_to_front(id);
    }

    /// Send a shape to the back.
    pub fn send_to_back(&mut self, id: &str) {
        self.scene_graph.send_to_back(id);
    }

    /// Move one step forward.
    pub fn move_forward(&mut self, id: &str) {
        self.scene_graph.move_forward(id);
    }

    /// Move one step backward.
    pub fn move_backward(&mut self, id: &str) {
        self.scene_graph.move_backward(id);
    }

    /// Hit-test all shapes at `pt` (slide coords) and return their ids in
    /// descending z-order (topmost first).
    pub fn hit_test_all(&self, pt: Point) -> Vec<&str> {
        self.scene_graph
            .draw_order()
            .iter()
            .rev()
            .filter_map(|id| {
                let shape = self.shapes.get(id)?;
                if !shape.locked && shape.hit_test(pt) {
                    Some(id.as_str())
                } else {
                    None
                }
            })
            .collect()
    }

    /// Return shapes in draw order (bottom → top).
    pub fn shapes_in_draw_order(&self) -> Vec<&Shape> {
        self.scene_graph
            .draw_order()
            .iter()
            .filter_map(|id| self.shapes.get(id))
            .collect()
    }
}

// ── Presentation ──────────────────────────────────────────────────────────────

/// A full presentation consisting of multiple slides.
#[derive(Debug, Default, Serialize, Deserialize)]
pub struct Presentation {
    pub title: String,
    pub author: String,
    pub slides: Vec<Slide>,
    pub theme: Theme,
    #[serde(skip)]
    pub history: crate::history::UndoRedoManager,
}

/// Presentation-level theming (colours, default fonts).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    pub accent_color: String,
    pub background_color: String,
    pub font_family: String,
    pub heading_font_family: String,
}

impl Default for Theme {
    fn default() -> Self {
        Self {
            accent_color: "#5b8dee".into(),
            background_color: "#ffffff".into(),
            font_family: "Inter".into(),
            heading_font_family: "Inter".into(),
        }
    }
}

impl Presentation {
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            title: title.into(),
            ..Default::default()
        }
    }

    pub fn add_slide(&mut self, slide: Slide) {
        self.slides.push(slide);
    }

    /// Insert a blank slide after `after_index`.
    pub fn insert_slide(&mut self, after_index: usize, slide: Slide) {
        let idx = (after_index + 1).min(self.slides.len());
        self.slides.insert(idx, slide);
    }

    /// Remove the slide at `index`. Returns the removed slide if valid.
    pub fn remove_slide(&mut self, index: usize) -> Option<Slide> {
        if index < self.slides.len() {
            Some(self.slides.remove(index))
        } else {
            None
        }
    }

    /// Reorder slide from `from` position to `to` position.
    pub fn move_slide(&mut self, from: usize, to: usize) {
        if from < self.slides.len() && to < self.slides.len() && from != to {
            let slide = self.slides.remove(from);
            self.slides.insert(to, slide);
        }
    }

    pub fn slide_count(&self) -> usize {
        self.slides.len()
    }
}

impl Clone for Presentation {
    fn clone(&self) -> Self {
        Self {
            title: self.title.clone(),
            author: self.author.clone(),
            slides: self.slides.clone(),
            theme: self.theme.clone(),
            history: crate::history::UndoRedoManager::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::scene::{Point, Rect};

    #[test]
    fn slide_add_remove_shape_keeps_scene_graph_in_sync() {
        let mut slide = Slide::new("slide-1");
        slide.add_shape(Shape::rect(
            "shape-1",
            Rect::new(0.0, 0.0, 100.0, 50.0),
            "#ff0000",
        ));

        assert!(slide.shapes.contains_key("shape-1"));
        assert_eq!(slide.scene_graph.draw_order(), &["shape-1".to_string()]);

        let removed = slide.remove_shape("shape-1");
        assert!(removed.is_some());
        assert!(!slide.shapes.contains_key("shape-1"));
        assert!(slide.scene_graph.draw_order().is_empty());
    }

    #[test]
    fn hit_test_returns_topmost_unlocked_shape_first() {
        let mut slide = Slide::new("slide-1");
        slide.add_shape(Shape::rect(
            "bottom",
            Rect::new(0.0, 0.0, 100.0, 100.0),
            "#ff0000",
        ));
        slide.add_shape(Shape::rect(
            "top",
            Rect::new(0.0, 0.0, 100.0, 100.0),
            "#00ff00",
        ));

        assert_eq!(
            slide.hit_test_all(Point::new(10.0, 10.0)),
            vec!["top", "bottom"]
        );

        slide.shapes.get_mut("top").unwrap().locked = true;
        assert_eq!(slide.hit_test_all(Point::new(10.0, 10.0)), vec!["bottom"]);
    }

    #[test]
    fn presentation_serializes_roundtrip() {
        let mut presentation = Presentation::new("Deck");
        let mut slide = Slide::new("slide-1");
        slide.add_shape(Shape::rect(
            "shape-1",
            Rect::new(10.0, 20.0, 30.0, 40.0),
            "#123456",
        ));
        presentation.add_slide(slide);

        let json = serde_json::to_string(&presentation).unwrap();
        let restored: Presentation = serde_json::from_str(&json).unwrap();

        assert_eq!(restored.title, "Deck");
        assert_eq!(restored.slide_count(), 1);
        assert!(restored.slides[0].shapes.contains_key("shape-1"));
    }
}

//! Slide Layout model - defines specific layout within a master

use serde::{Deserialize, Serialize};
use crate::models::shape::Shape;

/// Slide Layout - a specific layout template within a slide master
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SlideLayout {
    /// Unique identifier
    pub id: String,
    /// Name of the layout (e.g., "Title Slide", "Content")
    pub name: Option<String>,
    /// Reference to parent master ID
    pub master_id: Option<String>,
    /// Background override
    pub background: Option<String>,
    /// Placeholder shapes defining content areas
    pub shapes: Vec<Shape>,
    /// Whether to show master background
    pub show_master_background: bool,
}

impl SlideLayout {
    pub fn new(id: &str) -> Self {
        Self {
            id: id.to_string(),
            name: None,
            master_id: None,
            background: None,
            shapes: Vec::new(),
            show_master_background: true,
        }
    }
    
    pub fn add_shape(&mut self, shape: Shape) {
        self.shapes.push(shape);
    }
    
    pub fn validate(&self) -> Result<(), crate::error::PptxValidationError> {
        // Validate all shapes
        for shape in &self.shapes {
            shape.validate()?;
        }
        
        Ok(())
    }
}

impl Default for SlideLayout {
    fn default() -> Self {
        Self::new("layout-1")
    }
}

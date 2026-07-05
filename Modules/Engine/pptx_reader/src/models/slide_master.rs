//! Slide Master model - defines template for slides

use serde::{Deserialize, Serialize};
use crate::models::shape::Shape;
use crate::models::slide_layout::SlideLayout;
use crate::models::theme::Theme;

/// Slide Master - template that defines the default layout and styling
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SlideMaster {
    /// Unique identifier
    pub id: String,
    /// Name of the master
    pub name: Option<String>,
    /// Background color or fill
    pub background: Option<String>,
    /// Shapes on the master (logos, footers, etc.)
    pub shapes: Vec<Shape>,
    /// Layouts associated with this master
    pub layouts: Vec<SlideLayout>,
    /// Theme override for this master
    pub theme: Option<Theme>,
}

impl SlideMaster {
    pub fn new(id: &str) -> Self {
        Self {
            id: id.to_string(),
            name: None,
            background: None,
            shapes: Vec::new(),
            layouts: Vec::new(),
            theme: None,
        }
    }
    
    pub fn add_shape(&mut self, shape: Shape) {
        self.shapes.push(shape);
    }
    
    pub fn add_layout(&mut self, layout: SlideLayout) {
        self.layouts.push(layout);
    }
    
    pub fn validate(&self) -> Result<(), crate::error::PptxValidationError> {
        // Validate all shapes
        for shape in &self.shapes {
            shape.validate()?;
        }
        
        // Validate all layouts
        for layout in &self.layouts {
            layout.validate()?;
        }
        
        Ok(())
    }
}

impl Default for SlideMaster {
    fn default() -> Self {
        Self::new("master-1")
    }
}

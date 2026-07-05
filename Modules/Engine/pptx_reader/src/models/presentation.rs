//! Presentation root model

use serde::{Deserialize, Serialize};
use crate::models::slide::Slide;
use crate::models::slide_master::SlideMaster;
use crate::models::theme::Theme;
use crate::models::metadata::PresentationMetadata;
use crate::models::media::MediaFile;
use crate::models::animation::Animation;
use crate::history::HistoryState;

/// Root presentation model containing all slides and metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Presentation {
    /// Presentation title/identifier
    pub title: String,
    /// All slides in the presentation
    pub slides: Vec<Slide>,
    /// Slide masters for template layouts
    pub masters: Vec<SlideMaster>,
    /// Theme defining colors, fonts, and effects
    pub theme: Option<Theme>,
    /// Core metadata (author, company, etc.)
    pub metadata: PresentationMetadata,
    /// All embedded media files
    #[serde(skip_serializing, skip_deserializing)]
    pub all_media: Vec<MediaFile>,
    /// Embedded font data
    #[serde(skip_serializing, skip_deserializing)]
    pub embedded_fonts: Vec<Vec<u8>>,
    /// History state for undo/redo
    #[serde(skip)]
    pub history: HistoryState,
    /// Default slide width in points
    pub default_width: f64,
    /// Default slide height in points
    pub default_height: f64,
}

impl Presentation {
    pub fn new(title: &str) -> Self {
        Self {
            title: title.to_string(),
            slides: Vec::new(),
            masters: Vec::new(),
            theme: None,
            metadata: PresentationMetadata::default(),
            all_media: Vec::new(),
            embedded_fonts: Vec::new(),
            history: HistoryState::default(),
            default_width: 960.0, // 1280px / 1.333
            default_height: 540.0, // 720px / 1.333
        }
    }
    
    pub fn from_parsed_data(
        metadata: PresentationMetadata,
        slides: Vec<Slide>,
        masters: Vec<SlideMaster>,
        theme: Option<Theme>,
    ) -> Self {
        let slide_count = slides.len();
        Self {
            title: metadata.title.clone().unwrap_or_else(|| "Presentation".to_string()),
            slides,
            masters,
            theme,
            metadata,
            all_media: Vec::new(),
            embedded_fonts: Vec::new(),
            history: HistoryState::default(),
            default_width: 960.0,
            default_height: 540.0,
        }
    }
    
    pub fn add_slide(&mut self, slide: Slide) {
        self.slides.push(slide);
    }
    
    pub fn remove_slide(&mut self, index: usize) -> Option<Slide> {
        if index < self.slides.len() {
            Some(self.slides.remove(index))
        } else {
            None
        }
    }
    
    pub fn get_slide(&self, index: usize) -> Option<&Slide> {
        self.slides.get(index)
    }
    
    pub fn get_slide_mut(&mut self, index: usize) -> Option<&mut Slide> {
        self.slides.get_mut(index)
    }
    
    pub fn slide_count(&self) -> usize {
        self.slides.len()
    }
    
    pub fn validate(&self) -> Result<(), crate::error::PptxValidationError> {
        // Validate each slide
        for slide in &self.slides {
            slide.validate()?;
        }
        
        // Validate masters
        for master in &self.masters {
            master.validate()?;
        }
        
        Ok(())
    }
}

impl Default for Presentation {
    fn default() -> Self {
        Self::new("Untitled Presentation")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_create_presentation() {
        let pres = Presentation::new("Test Deck");
        assert_eq!(pres.title, "Test Deck");
        assert_eq!(pres.slide_count(), 0);
    }
    
    #[test]
    fn test_add_and_remove_slides() {
        let mut pres = Presentation::new("Test");
        let slide = Slide::new("slide-1");
        pres.add_slide(slide);
        assert_eq!(pres.slide_count(), 1);
        
        let removed = pres.remove_slide(0);
        assert!(removed.is_some());
        assert_eq!(pres.slide_count(), 0);
    }
}

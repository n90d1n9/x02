use serde::{Deserialize, Serialize};
use crate::models::{
    slide::Slide,
    metadata::PresentationMetadata,
    image::ImageData,
    media::MediaFile,
};

/// The fully-extracted presentation, the root type returned by PptxReader.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Presentation {
    /// Document-level metadata (title, author, dates, etc.).
    pub metadata: PresentationMetadata,
    /// All slides in order.
    pub slides: Vec<Slide>,
    /// Slide width in EMU.
    pub slide_width: i64,
    /// Slide height in EMU.
    pub slide_height: i64,
    /// All embedded images across the whole presentation.
    pub all_images: Vec<ImageData>,
    /// All embedded media (audio/video) across the whole presentation.
    pub all_media: Vec<MediaFile>,
    /// Custom show definitions.
    pub custom_shows: Vec<CustomShow>,
    /// Section definitions (PowerPoint sections grouping slides).
    pub sections: Vec<Section>,
    /// Theme information.
    pub theme: Option<ThemeInfo>,
}

impl Presentation {
    /// Get total number of slides (including hidden).
    pub fn slide_count(&self) -> usize { self.slides.len() }

    /// Get number of visible slides.
    pub fn visible_slide_count(&self) -> usize {
        self.slides.iter().filter(|s| !s.hidden).count()
    }

    /// Get slide dimensions in inches.
    pub fn slide_dimensions_inches(&self) -> (f64, f64) {
        (self.slide_width as f64 / 914400.0, self.slide_height as f64 / 914400.0)
    }

    /// Get all text across the entire presentation as a flat string.
    pub fn all_text(&self) -> String {
        self.slides.iter()
            .map(|s| format!("--- Slide {} ---\n{}", s.index, s.all_text()))
            .collect::<Vec<_>>()
            .join("\n\n")
    }

    /// Get all speaker notes across all slides.
    pub fn all_notes(&self) -> Vec<(usize, String)> {
        self.slides.iter()
            .filter_map(|s| s.notes_text().map(|n| (s.index, n)))
            .collect()
    }

    /// Get all titles from all slides.
    pub fn all_titles(&self) -> Vec<(usize, String)> {
        self.slides.iter()
            .filter_map(|s| s.title().map(|t| (s.index, t)))
            .collect()
    }

    /// Serialize to JSON string.
    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string_pretty(self)
    }

    /// Check if any slide has animations.
    pub fn has_animations(&self) -> bool {
        self.slides.iter().any(|s| s.has_animations())
    }

    /// Find slide by name.
    pub fn find_slide_by_name(&self, name: &str) -> Option<&Slide> {
        self.slides.iter().find(|s| s.name.as_deref() == Some(name))
    }

    /// Find slide by 1-based index.
    pub fn slide(&self, index: usize) -> Option<&Slide> {
        self.slides.iter().find(|s| s.index == index)
    }
}

/// A custom show (subset of slides shown in a specific order).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CustomShow {
    pub id: u32,
    pub name: String,
    /// Slide indices (1-based) in the order they appear in the show.
    pub slide_indices: Vec<usize>,
}

/// A section grouping slides.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Section {
    pub id: String,
    pub name: String,
    /// Starting slide index (1-based, inclusive).
    pub start_slide: usize,
    /// Number of slides in this section.
    pub slide_count: usize,
}

/// Extracted theme color/font information.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThemeInfo {
    pub name: Option<String>,
    pub color_scheme: Vec<(String, crate::models::color::Color)>,
    pub major_font: Option<String>,
    pub minor_font: Option<String>,
}

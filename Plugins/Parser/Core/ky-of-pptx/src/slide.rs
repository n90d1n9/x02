use serde::{Deserialize, Serialize};
use crate::models::{
    shape::Shape,
    animation::SlideAnimations,
    transition::SlideTransition,
    image::ImageData,
    media::MediaFile,
    text::TextFrame,
};

/// A single slide in the presentation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Slide {
    /// 1-based slide index.
    pub index: usize,
    /// Slide name (from slide properties).
    pub name: Option<String>,
    /// All shapes on the slide (in z-order).
    pub shapes: Vec<Shape>,
    /// All animations defined on the slide.
    pub animations: SlideAnimations,
    /// Slide transition effect.
    pub transition: Option<SlideTransition>,
    /// Speaker notes for this slide.
    pub notes: Option<TextFrame>,
    /// Background fill of the slide.
    pub background: Option<SlideBackground>,
    /// Embedded images referenced in this slide.
    pub images: Vec<ImageData>,
    /// Embedded media (audio/video) referenced in this slide.
    pub media: Vec<MediaFile>,
    /// Whether this slide is hidden (skipped during show).
    pub hidden: bool,
    /// Show/hide slide number.
    pub show_slide_number: Option<bool>,
    /// Slide layout name.
    pub layout_name: Option<String>,
    /// Slide master name.
    pub master_name: Option<String>,
    /// Slide dimensions in EMU (inherited from presentation).
    pub width: i64,
    pub height: i64,
}

impl Slide {
    /// Extract all plain text from all shapes, joined by newlines.
    pub fn all_text(&self) -> String {
        self.shapes.iter()
            .filter_map(|s| s.plain_text())
            .filter(|t| !t.trim().is_empty())
            .collect::<Vec<_>>()
            .join("\n")
    }

    /// Get the title text (from the title placeholder).
    pub fn title(&self) -> Option<String> {
        self.shapes.iter()
            .find(|s| s.is_title())
            .and_then(|s| s.plain_text())
    }

    /// Get all images on the slide.
    pub fn images(&self) -> Vec<&ImageData> {
        self.shapes.iter()
            .filter_map(|s| s.image())
            .collect()
    }

    /// Get the speaker notes as plain text.
    pub fn notes_text(&self) -> Option<String> {
        self.notes.as_ref().map(|n| n.plain_text())
    }

    /// Get slide dimensions in inches.
    pub fn dimensions_inches(&self) -> (f64, f64) {
        (self.width as f64 / 914400.0, self.height as f64 / 914400.0)
    }

    /// Check if the slide has any animations.
    pub fn has_animations(&self) -> bool {
        !self.animations.is_empty()
    }

    /// Get shapes by type name (convenience method).
    pub fn shapes_with_text(&self) -> Vec<&Shape> {
        self.shapes.iter()
            .filter(|s| s.text_frame.as_ref().map(|tf| !tf.is_empty()).unwrap_or(false))
            .collect()
    }
}

/// Background of a slide.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SlideBackground {
    pub fill: BackgroundFill,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum BackgroundFill {
    None,
    Solid { color: crate::models::color::ColorSpec },
    Gradient {
        stops: Vec<(f64, crate::models::color::ColorSpec)>,
        angle: f64,
        path: Option<GradientPath>,
    },
    Pattern {
        fg: crate::models::color::ColorSpec,
        bg: crate::models::color::ColorSpec,
        preset: String,
    },
    Picture {
        image: ImageData,
        stretch: bool,
    },
    Theme,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum GradientPath { Circle, Rect, Shape }

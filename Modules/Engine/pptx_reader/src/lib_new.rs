//! PPTX Reader Engine - Complete PowerPoint/Google Slides Compatible Parser
//! 
//! This module provides full-featured PPTX file parsing and manipulation capabilities
//! matching Microsoft PowerPoint and Google Slides functionality.
//! 
//! # Features
//! - Complete PPTX import/export with all Office Open XML elements
//! - Slide master and layout support
//! - Animation timeline with all effect types
//! - Transition effects gallery
//! - Table editing with full formatting
//! - Chart parsing and rendering
//! - Multimedia (audio/video) support
//! - Theme and color scheme extraction
//! - Shape geometry and text formatting
//! - Hyperlink and action handling
//! - Speaker notes and comments
//! - Custom shows and sections
//! - Accessibility features (alt-text, reading order)

pub mod error;
pub mod models;
pub mod parsers;
pub mod extractors;
pub mod writers;
pub mod validators;

// Core types
pub use error::{PptxError, Result, PptxValidationError};
pub use models::presentation::Presentation;
pub use models::slide::Slide;
pub use models::slide_master::SlideMaster;
pub use models::slide_layout::SlideLayout;
pub use models::shape::{Shape, ShapeType, ShapeGeometry};
pub use models::text::{TextFrame, Paragraph, Run, TextProperties, FontScheme};
pub use models::image::ImageData;
pub use models::chart::{Chart, ChartType, ChartSeries, ChartData};
pub use models::table::{Table, TableRow, TableCell, TableStyle};
pub use models::animation::{Animation, AnimationEffect, AnimationTrigger, AnimationTimeline};
pub use models::transition::{SlideTransition, TransitionType, TransitionSpeed};
pub use models::metadata::PresentationMetadata;
pub use models::theme::{Theme, ColorScheme, FontScheme, FormatScheme};
pub use models::color::Color;
pub use models::geometry::{Geometry, PathCommand, Point2D};
pub use models::hyperlink::{Hyperlink, Action};
pub use models::media::{MediaFile, MediaType, AudioFile, VideoFile};
pub use models::comment::{Comment, CommentAuthor};
pub use models::notes::SpeakerNotes;

// Parser and extractor
pub use parsers::pptx_parser::PptxParser;
pub use extractors::pptx_extractor::PptxExtractor;
pub use writers::pptx_writer::PptxWriter;
pub use validators::pptx_validator::PptxValidator;

// Engine components
pub mod engine {
    pub use crate::animation_engine::*;
    pub use crate::render_engine::*;
    pub use crate::layout_engine::*;
}

pub mod animation_engine;
pub mod render_engine;
pub mod layout_engine;

// Session and operations
pub mod session;
pub mod ops;
pub mod history;
pub mod selection;
pub mod scene;
pub mod renderer;

// Re-export commonly used items
pub use session::PresentationSession;
pub use ops::{PresentationEdit, PresentationOperation, PresentationTransaction};
pub use renderer::{SlideRenderer, DrawCommand};
pub use scene::{SceneGraph, Transform, Rect, Size, Point};

/// Library version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Supported PPTX schema versions
pub const SUPPORTED_SCHEMA_VERSIONS: &[&str] = &[
    "http://schemas.openxmlformats.org/presentationml/2006/main",
    "http://schemas.microsoft.com/office/powerpoint/2010/main",
    "http://schemas.microsoft.com/office/powerpoint/2013/main",
];

/// Default slide dimensions (16:9 aspect ratio in EMU)
pub const DEFAULT_SLIDE_WIDTH_EMU: i64 = 9144000;  // 10 inches
pub const DEFAULT_SLIDE_HEIGHT_EMU: i64 = 5143500; // 5.625 inches

/// Maximum supported slide dimensions
pub const MAX_SLIDE_WIDTH_EMU: i64 = 51816000; // 57 inches
pub const MAX_SLIDE_HEIGHT_EMU: i64 = 51816000;

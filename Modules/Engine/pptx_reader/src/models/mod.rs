//! Data models for PPTX presentation elements

pub mod presentation;
pub mod slide;
pub mod slide_master;
pub mod slide_layout;
pub mod shape;
pub mod text;
pub mod image;
pub mod chart;
pub mod table;
pub mod animation;
pub mod transition;
pub mod theme;
pub mod color;
pub mod geometry;
pub mod hyperlink;
pub mod media;
pub mod comment;
pub mod notes;
pub mod metadata;

// Re-export commonly used types
pub use presentation::Presentation;
pub use slide::Slide;
pub use slide_master::SlideMaster;
pub use slide_layout::SlideLayout;
pub use shape::{Shape, ShapeType, ShapeGeometry};
pub use text::{TextFrame, Paragraph, Run};
pub use image::ImageData;
pub use chart::{Chart, ChartType};
pub use table::{Table, TableRow, TableCell};
pub use animation::{Animation, AnimationEffect};
pub use transition::SlideTransition;
pub use theme::Theme;
pub use color::Color;
pub use geometry::{Geometry, Point2D};
pub use hyperlink::Hyperlink;
pub use media::MediaFile;
pub use comment::Comment;
pub use notes::SpeakerNotes;
pub use metadata::PresentationMetadata;

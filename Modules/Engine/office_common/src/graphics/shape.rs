use serde::{Deserialize, Serialize};
use crate::models::{
    geometry::{Geometry, PresetGeometry, FillType, LineProperties},
    text::TextFrame,
    image::ImageData,
    chart::Chart,
    table::Table,
};

/// A shape on a slide — the central element of a presentation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Shape {
    /// Unique shape identifier within the slide.
    pub id: String,
    /// User-visible name (e.g., "Title 1", "Picture 3").
    pub name: String,
    /// Alt text for accessibility.
    pub alt_text: Option<String>,
    /// Position and size of the shape.
    pub geometry: Geometry,
    /// The type/content of the shape.
    pub shape_type: ShapeType,
    /// Text content (if this shape contains text).
    pub text_frame: Option<TextFrame>,
    /// Fill applied to the shape.
    pub fill: Option<FillType>,
    /// Border/outline of the shape.
    pub line: Option<LineProperties>,
    /// Preset geometry (if this is a standard shape like rect, ellipse, etc.).
    pub preset_geometry: Option<PresetGeometry>,
    /// Whether this shape is hidden on the slide.
    pub hidden: bool,
    /// Z-order (drawing order) — lower numbers are further back.
    pub z_order: u32,
    /// Whether this shape is a placeholder (title, content, etc.).
    pub placeholder: Option<Placeholder>,
    /// Group this shape belongs to (if nested).
    pub group_id: Option<String>,
    /// Hyperlink on the entire shape (not text-level).
    pub hyperlink: Option<crate::models::hyperlink::Hyperlink>,
    /// Lock properties.
    pub locks: ShapeLocks,
    /// 3D effect properties.
    pub effect_3d: Option<Shape3dEffect>,
    /// Shadow, glow, reflection, soft edge effects.
    pub effects: Vec<ShapeEffect>,
}

impl Shape {
    /// Get plain text from the text frame, if any.
    pub fn plain_text(&self) -> Option<String> {
        self.text_frame.as_ref().map(|tf| tf.plain_text())
    }

    /// Check if this shape is a title placeholder.
    pub fn is_title(&self) -> bool {
        self.placeholder.as_ref().map(|p| matches!(
            p.placeholder_type,
            PlaceholderType::Title | PlaceholderType::CenteredTitle
        )).unwrap_or(false)
    }

    /// Get the embedded image, if this is a picture shape.
    pub fn image(&self) -> Option<&ImageData> {
        match &self.shape_type {
            ShapeType::Picture { image, .. } => Some(image),
            _ => None,
        }
    }

    /// Get the chart data, if this is a chart shape.
    pub fn chart(&self) -> Option<&Chart> {
        match &self.shape_type {
            ShapeType::Chart(c) => Some(c),
            _ => None,
        }
    }

    /// Get the table data, if this is a table shape.
    pub fn table(&self) -> Option<&Table> {
        match &self.shape_type {
            ShapeType::Table(t) => Some(t),
            _ => None,
        }
    }
}

/// The type of content a shape represents.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ShapeType {
    /// A generic shape (rectangle, ellipse, arrow, etc.) — may contain text.
    AutoShape,

    /// A text box with a text frame.
    TextBox,

    /// An embedded or linked picture/image.
    Picture {
        image: ImageData,
        /// Whether this picture has a preset shape applied (picture frame).
        frame_shape: Option<PresetGeometry>,
    },

    /// A chart (bar, line, pie, scatter, etc.).
    Chart(Chart),

    /// A table.
    Table(Table),

    /// A connector/line between shapes.
    Connector {
        connector_type: ConnectorType,
        start_shape: Option<ConnectionPoint>,
        end_shape: Option<ConnectionPoint>,
    },

    /// A grouped collection of shapes.
    Group(Vec<Shape>),

    /// A SmartArt graphic (structure only; rendered as image).
    SmartArt {
        diagram_type: String,
        shapes: Vec<Shape>,
    },

    /// An OLE object (embedded external content).
    OleObject {
        program_id: String,
        relationship_id: String,
        cached_image: Option<ImageData>,
    },

    /// An audio or video media object.
    Media {
        media_type: MediaType,
        relationship_id: String,
        poster_image: Option<ImageData>,
        playback: MediaPlayback,
    },

    /// Ink annotations.
    Ink,

    /// Unknown/unrecognized shape type.
    Unknown,
}

/// Placeholder type (layout positions like Title, Content, etc.)
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Placeholder {
    pub placeholder_type: PlaceholderType,
    pub index: Option<u32>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum PlaceholderType {
    Title,
    CenteredTitle,
    Body,
    SubTitle,
    DateAndTime,
    SlideNumber,
    Footer,
    Header,
    Object,
    Chart,
    Table,
    ClipArt,
    OrgChart,
    Media,
    Picture,
    SlideImage,
    Custom(u32),
}

/// Connector (line between shapes) type.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum ConnectorType {
    Straight,
    Bent,
    Curved,
    Elbow,
}

/// Connection point on a shape (for connectors).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConnectionPoint {
    pub shape_id: String,
    pub connection_index: u32,
}

/// Media type for embedded media shapes.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum MediaType {
    Audio { mime_type: String },
    Video { mime_type: String },
    Unknown,
}

/// Playback settings for media shapes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaPlayback {
    pub auto_play: bool,
    pub loop_media: bool,
    pub muted: bool,
    pub hide_during_show: bool,
    pub rewind_after: bool,
    pub trim_start_ms: Option<u64>,
    pub trim_end_ms: Option<u64>,
    pub volume: f32,
}

impl Default for MediaPlayback {
    fn default() -> Self {
        MediaPlayback {
            auto_play: false,
            loop_media: false,
            muted: false,
            hide_during_show: false,
            rewind_after: false,
            trim_start_ms: None,
            trim_end_ms: None,
            volume: 1.0,
        }
    }
}

/// Lock properties that prevent certain modifications.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ShapeLocks {
    pub no_group: bool,
    pub no_select: bool,
    pub no_rotate: bool,
    pub no_resize: bool,
    pub no_move: bool,
    pub no_text_edit: bool,
    pub no_aspect_ratio_change: bool,
}

/// 3D effects applied to a shape.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Shape3dEffect {
    pub bevel_top: Option<Bevel>,
    pub bevel_bottom: Option<Bevel>,
    pub extrusion_height: Option<i64>,
    pub contour_width: Option<i64>,
    pub extrusion_color: Option<crate::models::color::ColorSpec>,
    pub contour_color: Option<crate::models::color::ColorSpec>,
    pub camera: Option<CameraProps>,
    pub light_rig: Option<LightRig>,
    pub z_offset: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bevel {
    pub bevel_type: String,
    pub width: i64,
    pub height: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CameraProps {
    pub preset: String,
    pub fov: Option<f64>,
    pub zoom: Option<f64>,
    pub rot: Option<(f64, f64, f64)>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LightRig {
    pub rig_type: String,
    pub direction: String,
    pub rot: Option<(f64, f64, f64)>,
}

/// Visual effects applied to a shape (shadow, glow, reflection, soft edge).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ShapeEffect {
    OuterShadow {
        blur: f64,
        distance: f64,
        direction: f64,
        color: crate::models::color::ColorSpec,
        alpha: f32,
        sx: Option<f64>,
        sy: Option<f64>,
        kx: Option<f64>,
        ky: Option<f64>,
        align: Option<String>,
        rotate_with_shape: bool,
    },
    InnerShadow {
        blur: f64,
        distance: f64,
        direction: f64,
        color: crate::models::color::ColorSpec,
        alpha: f32,
    },
    Glow {
        radius: f64,
        color: crate::models::color::ColorSpec,
        alpha: f32,
    },
    Reflection {
        blur: f64,
        alpha: f32,
        start_a: f32,
        end_a: f32,
        dist: f64,
        dir: f64,
        fade_dir: f64,
        sy: f64,
        ky: f64,
        align: String,
        rotate_with_shape: bool,
    },
    SoftEdge { radius: f64 },
}

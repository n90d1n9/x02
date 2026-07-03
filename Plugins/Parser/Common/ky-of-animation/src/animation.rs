use serde::{Deserialize, Serialize};

/// All animations on a slide, organized into sequences.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SlideAnimations {
    /// Main animation sequence (click-triggered animations).
    pub main_sequence: Vec<Animation>,
    /// Interactive sequences (triggered by clicking a specific shape).
    pub interactive_sequences: Vec<InteractiveSequence>,
}

impl SlideAnimations {
    pub fn is_empty(&self) -> bool {
        self.main_sequence.is_empty() && self.interactive_sequences.is_empty()
    }

    pub fn total_count(&self) -> usize {
        self.main_sequence.len()
            + self.interactive_sequences.iter().map(|s| s.animations.len()).sum::<usize>()
    }
}

/// An interactive animation sequence triggered by clicking a shape.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InteractiveSequence {
    /// The shape ID that triggers this sequence.
    pub trigger_shape_id: Option<String>,
    pub animations: Vec<Animation>,
}

/// A single animation effect on a shape.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Animation {
    /// The ID of the shape this animation is applied to.
    pub shape_id: Option<String>,
    /// The animation effect.
    pub effect: AnimationEffect,
    /// What triggers this animation.
    pub trigger: AnimationTrigger,
    /// Delay before the animation starts (in milliseconds).
    pub delay_ms: u64,
    /// Duration of the animation (in milliseconds).
    pub duration_ms: u64,
    /// Number of times to repeat (None = forever).
    pub repeat_count: Option<f32>,
    /// Whether to auto-reverse after playing.
    pub auto_reverse: bool,
    /// Speed of the animation.
    pub speed: AnimationSpeed,
    /// What to do after the animation ends.
    pub end_action: AnimationEndAction,
    /// Sub-shape or text unit target (e.g., by paragraph).
    pub target: AnimationTarget,
    /// Acceleration factor (0.0–1.0).
    pub accel: f32,
    /// Deceleration factor (0.0–1.0).
    pub decel: f32,
    /// Whether the shape is hidden before the animation plays.
    pub hide_after: bool,
    /// Additional properties specific to the effect type.
    pub extra: Option<AnimationExtras>,
}

/// The specific animation effect applied.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AnimationEffect {
    // --- Entrance effects ---
    Appear,
    Blinds { direction: Direction },
    Box { direction: BoxDirection },
    Checkerboard { direction: Direction },
    Circle { direction: EntranceExitDirection },
    CrawlIn { from: Direction },
    Diamond { direction: EntranceExitDirection },
    Dissolve,
    Fade,
    FadeZoom,
    Fly { from: Direction, smooth_start: bool, smooth_end: bool },
    Glide,
    GrowAndTurn,
    Peek { from: Direction },
    Plus { direction: EntranceExitDirection },
    RandomBars { direction: Direction },
    RandomEffects,
    Rise,
    Spinner { amount: SpinAmount },
    Split { orientation: Orientation, direction: SplitDirection },
    Stretch { direction: Direction },
    Strips { direction: CornerDirection },
    Swivel { axis: Axis },
    Wedge,
    Wheel { spokes: u32 },
    WhipIn { direction: Direction },
    Wipe { direction: Direction },
    Zoom { direction: ZoomDirection, origin: ZoomOrigin },

    // --- Emphasis effects ---
    Bold,
    BoldFlash,
    BoldReveal,
    Brush,
    ChangeFillColor { color: String },
    ChangeFont { font: String },
    ChangeFontColor { color: String },
    ChangeFontSize { size: f32 },
    ChangeFontStyle { bold: Option<bool>, italic: Option<bool> },
    ChangeLineColor { color: String },
    Complementary,
    Contrasting,
    Darken,
    Desaturate,
    FlashBulb,
    FlickerOn,
    Grow { size: f32 },
    GrowShrink { size: f32 },
    Lighten,
    OjectColorReveal,
    Pulse,
    Shimmer,
    Sling,
    Spin { amount: f32, direction: RotationDirection, auto_reverse: bool },
    Teeter,
    Transparent { amount: f32 },
    Underline,
    Wave,
    WheelOverFar,
    Blink,

    // --- Exit effects ---
    Collapse,
    ColorPattern,
    CrawlOut { to: Direction },
    Credits { direction: CreditsDirection },
    Disappear,
    EaseOut,
    FlyOut { to: Direction },
    Float,
    GrowTurn,
    Magnify,
    PeekOut { to: Direction },
    Pinwheel,
    Slingshot,
    Swish { direction: Direction },
    Swivel2 { axis: Axis },
    Thread,
    WhipOut { direction: Direction },
    ZoomOut { direction: ZoomDirection, origin: ZoomOrigin },

    // --- Motion paths ---
    MotionPath {
        path_type: MotionPathType,
        path_data: Option<String>, // SVG path data for custom paths
        origin: Option<(f64, f64)>,
        destination: Option<(f64, f64)>,
        smooth: bool,
        rotate_with_path: bool,
    },

    // --- OLE action verbs ---
    OleAction { verb: String },

    /// Any unrecognized effect (stores the raw preset name).
    Custom(String),
}

/// What triggers an animation to play.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AnimationTrigger {
    /// Plays on a mouse click.
    OnClick,
    /// Plays with the previous animation (simultaneously).
    WithPrevious,
    /// Plays after the previous animation ends.
    AfterPrevious,
    /// Plays on a click of a specific shape.
    OnClickOf { shape_id: String },
    /// Plays when the mouse enters a shape.
    OnMouseEnter { shape_id: String },
    /// Begins after a relative offset from another trigger.
    BeginAfter { offset_ms: i64 },
}

/// Which part of a shape is animated.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AnimationTarget {
    /// Animate the entire shape.
    WholeShape,
    /// Animate text by word.
    ByWord { delay_between: f32 },
    /// Animate text by letter.
    ByLetter { delay_between: f32 },
    /// Animate text by paragraph.
    ByParagraph { index: Option<u32> },
    /// Animate a specific child element.
    ByElement,
}

/// Preset animation speeds.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AnimationSpeed {
    VerySlow,  // 5000ms
    Slow,      // 3000ms
    Medium,    // 2000ms
    Fast,      // 1000ms
    VeryFast,  // 500ms
    Custom(u64),
}

impl AnimationSpeed {
    pub fn to_ms(&self) -> u64 {
        match self {
            AnimationSpeed::VerySlow => 5000,
            AnimationSpeed::Slow => 3000,
            AnimationSpeed::Medium => 2000,
            AnimationSpeed::Fast => 1000,
            AnimationSpeed::VeryFast => 500,
            AnimationSpeed::Custom(ms) => *ms,
        }
    }
}

/// What happens to the shape after the animation ends.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AnimationEndAction {
    /// Shape retains the animation's end state.
    Hold,
    /// Shape returns to its original state.
    Remove,
    /// Shape is hidden after the animation.
    Hide,
}

// --- Helper enums used by effects ---

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Direction { Left, Right, Up, Down }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum BoxDirection { In, Out }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum EntranceExitDirection { In, Out }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Orientation { Horizontal, Vertical }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum SplitDirection { In, Out }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum CornerDirection { LeftDown, LeftUp, RightDown, RightUp }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum Axis { Horizontal, Vertical }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum ZoomDirection { In, Out, SlightlyIn, SlightlyOut }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum ZoomOrigin { Center, SlideCenter }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum SpinAmount { Full, Half, Quarter }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum RotationDirection { Clockwise, CounterClockwise }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum CreditsDirection { Up, Down }

/// Motion path shape types.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum MotionPathType {
    Line,
    Arc,
    Circle,
    CurvedLine,
    Diamond,
    Figure8,
    FigureS,
    FunnelRight,
    Heart,
    Hexagon,
    HorizontalFigure8,
    Inverted,
    InvertedSquare,
    Loop,
    NeutronPath,
    Peanut,
    Pentagon,
    Plus,
    PTurnRight,
    PointyStar,
    RightTriangle,
    Sine,
    SpiralLeft,
    SpiralRight,
    Spring,
    Square,
    Star,
    Swoosh,
    Teardrop,
    Triangle,
    TurnDown,
    TurnRight,
    TurnUp,
    TurnUpRight,
    VerticalFigure8,
    Wave,
    Zigzag,
    Custom,
    User,
}

/// Extra animation properties depending on effect type.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnimationExtras {
    pub color: Option<String>,
    pub formula: Option<String>,
    pub by: Option<String>,
    pub from: Option<String>,
    pub to: Option<String>,
}

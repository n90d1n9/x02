use serde::{Deserialize, Serialize};

/// Slide transition effect.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SlideTransition {
    pub effect: TransitionEffect,
    /// Duration of the transition in milliseconds.
    pub duration_ms: Option<u64>,
    /// Whether the transition advances on click.
    pub advance_on_click: bool,
    /// Auto-advance after this many milliseconds (None = no auto-advance).
    pub advance_after_ms: Option<u64>,
    /// Transition sound.
    pub sound: Option<TransitionSound>,
}

/// The visual effect used for the transition.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Default)]
pub enum TransitionEffect {
    // Basic
    #[default]
    None,
    Cut,
    CutThroughBlack,
    Fade,
    FadeSmoothly,

    // Push / wipe family
    Blinds { direction: TransitionDirection },
    Box { direction: TransitionBoxDirection },
    Checker { direction: TransitionDirection },
    Comb { direction: TransitionDirection },
    Cover { direction: TransitionDirection8Way },
    Diamond,
    Dissolve,
    Flash,
    Flip { direction: TransitionDirection },
    Gallery { direction: TransitionDirection },
    Honeycomb,
    Newsflash,
    Pan { direction: TransitionDirection8Way },
    Plus,
    Pull { direction: TransitionDirection8Way },
    Push { direction: TransitionDirection4Way },
    Random,
    RandomBar { direction: TransitionDirection },
    Ripple { direction: TransitionDirection4Way },
    Rotate,
    Shred { direction: TransitionShredDirection },
    Split { orientation: TransitionOrientation, direction: TransitionInOutDirection },
    Strips { direction: TransitionCornerDirection },
    Switch { direction: TransitionDirection },
    Uncover { direction: TransitionDirection8Way },
    Vortex { direction: TransitionDirection4Way },
    Warp,
    Wedge,
    Wheel { spokes: u32 },
    Wind { direction: TransitionDirection },
    Wipe { direction: TransitionDirection4Way },
    Zoom { direction: TransitionInOutDirection },
    ZoomAndRotate,

    // Morph
    Morph { option: MorphOption },

    /// Unknown or custom transition.
    Other(String),
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionDirection { Horizontal, Vertical }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionOrientation { Horizontal, Vertical }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionInOutDirection { In, Out }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionBoxDirection { In, Out }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionShredDirection { Forward, Backward }

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionCornerDirection { LeftDown, LeftUp, RightDown, RightUp }

/// 4-way directional transition.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionDirection4Way { Left, Right, Up, Down }

/// 8-way directional transition.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum TransitionDirection8Way {
    Left, Right, Up, Down,
    LeftDown, LeftUp, RightDown, RightUp,
}

/// Morph transition option.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum MorphOption {
    ByObject,
    ByWord,
    ByChar,
}

/// Sound played during a transition.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransitionSound {
    pub relationship_id: Option<String>,
    pub preset: Option<String>,
    pub loop_sound: bool,
    pub stop_previous: bool,
    pub is_builtin: bool,
}

//! Transition model - slide transition effects

use serde::{Deserialize, Serialize};

/// Slide Transition - effect when moving between slides
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SlideTransition {
    /// Transition effect type
    pub effect_type: String,
    /// Duration in milliseconds
    pub duration_ms: u64,
    /// Speed preset (slow, medium, fast)
    pub speed: String,
    /// Sound effect (optional)
    pub sound: Option<String>,
    /// Auto-advance after time in milliseconds
    pub auto_advance_ms: Option<u64>,
    /// Random transition
    pub random: bool,
}

impl SlideTransition {
    pub fn new(effect_type: &str) -> Self {
        Self {
            effect_type: effect_type.to_string(),
            duration_ms: 500,
            speed: "medium".to_string(),
            sound: None,
            auto_advance_ms: None,
            random: false,
        }
    }
    
    pub fn with_duration(mut self, ms: u64) -> Self {
        self.duration_ms = ms;
        self
    }
    
    pub fn with_speed(mut self, speed: &str) -> Self {
        self.speed = speed.to_string();
        self
    }
    
    pub fn with_auto_advance(mut self, ms: u64) -> Self {
        self.auto_advance_ms = Some(ms);
        self
    }
}

impl Default for SlideTransition {
    fn default() -> Self {
        Self {
            effect_type: "none".to_string(),
            duration_ms: 500,
            speed: "medium".to_string(),
            sound: None,
            auto_advance_ms: None,
            random: false,
        }
    }
}

/// Common transition types
pub mod transitions {
    pub const NONE: &str = "none";
    pub const FADE: &str = "fade";
    pub const PUSH: &str = "push";
    pub const WIPE: &str = "wipe";
    pub const SPLIT: &str = "split";
    pub const CUT: &str = "cut";
    pub const RANDOM: &str = "random";
    pub const MORPH: &str = "morph";
    pub const TRANSFORM: &str = "transform";
    pub const FLIP: &str = "flip";
    pub const ROTATE: &str = "rotate";
    pub const ZOOM: &str = "zoom";
    pub const COVER: &str = "cover";
    pub const UNCOVER: &str = "uncover";
    pub const DISSOLVE: &str = "dissolve";
    pub const NEWSFLASH: &str = "newsflash";
    pub const COMB: &str = "comb";
    pub const AIRPLANE: &str = "airplane";
    pub const CIRCLE: &str = "circle";
    pub const CONTOUR: &str = "contour";
    pub const CURTAINS: &str = "curtains";
    pub const DOOR: &str = "door";
    pub const FLY: &str = "fly";
    pub const FRAGILE: &str = "fragile";
    pub const GLITTER: &str = "glitter";
    pub const HONEYCOMB: &str = "honeycomb";
    pub const ORBIT: &str = "orbit";
    pub const PAN: &str = "pan";
    pub const PEEK: &str = "peek";
    pub const Ripples: &str = "ripples";
    pub const SHADES: &str = "shades";
    pub const SLIDE: &str = "slide";
    pub const SWEEP: &str = "sweep";
    pub const SWITCH: &str = "switch";
    pub const WEDGE: &str = "wedge";
    pub const WINDOW: &str = "window";
    pub const WORMHOLE: &str = "wormhole";
}

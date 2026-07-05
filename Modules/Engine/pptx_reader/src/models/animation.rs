//! Animation models - effects, triggers, and timing

use serde::{Deserialize, Serialize};

/// Animation container for a slide
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Animation {
    /// Animation effects on this slide
    pub effects: Vec<AnimationEffect>,
}

impl Animation {
    pub fn new() -> Self {
        Self::default()
    }
    
    pub fn add_effect(&mut self, effect: AnimationEffect) {
        self.effects.push(effect);
    }
}

/// Animation Effect - a single animation on an element
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnimationEffect {
    /// Unique identifier
    pub id: String,
    /// Target element ID
    pub target_id: String,
    /// Effect type (entrance, emphasis, exit, motion)
    pub effect_type: AnimationType,
    /// Specific effect name (e.g., "Fade", "Fly In")
    pub effect_name: String,
    /// Trigger type
    pub trigger: AnimationTrigger,
    /// Duration in milliseconds
    pub duration_ms: u64,
    /// Delay before starting in milliseconds
    pub delay_ms: u64,
    /// Repeat count
    pub repeat_count: Option<f64>,
    /// Easing function
    pub easing: Option<EasingType>,
    /// Order in sequence
    pub sequence_order: u32,
}

impl AnimationEffect {
    pub fn new(id: &str, target_id: &str, effect_type: AnimationType, effect_name: &str) -> Self {
        Self {
            id: id.to_string(),
            target_id: target_id.to_string(),
            effect_type,
            effect_name: effect_name.to_string(),
            trigger: AnimationTrigger::OnClick,
            duration_ms: 500,
            delay_ms: 0,
            repeat_count: None,
            easing: None,
            sequence_order: 0,
        }
    }
}

/// Animation Type
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum AnimationType {
    /// Entrance animations
    Entrance,
    /// Emphasis animations
    Emphasis,
    /// Exit animations
    Exit,
    /// Motion path animations
    MotionPath,
}

/// Animation Trigger - what starts the animation
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum AnimationTrigger {
    /// On mouse click
    OnClick,
    /// With previous animation
    WithPrevious,
    /// After previous animation
    AfterPrevious,
    /// On specific time
    OnTime(u64),
}

impl Default for AnimationTrigger {
    fn default() -> Self {
        AnimationTrigger::OnClick
    }
}

/// Easing Function types
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum EasingType {
    Linear,
    EaseIn,
    EaseOut,
    EaseInOut,
    Bounce,
    Elastic,
    Back,
    Circ,
    Cubic,
    Expo,
    Quad,
    Quart,
    Quint,
    Sine,
}

impl Default for EasingType {
    fn default() -> Self {
        EasingType::Linear
    }
}

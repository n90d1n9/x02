pub use waraq_core::core;

pub mod animation;
pub mod history;
pub mod ops;
pub mod renderer;
pub mod scene;
pub mod selection;
pub mod session;
pub mod shape;
pub mod slide;

pub use animation::{
    AnimationEffect, AnimationTrigger, Easing, ElementAnimation, SlideAnimations, Transition,
    TransitionKind,
};
pub use ops::{
    apply_presentation_edit, apply_presentation_operation, presentation_operation,
    presentation_snapshot, PresentationEdit, PresentationEditError, PresentationEditOutcome,
    PresentationOperation, PresentationOperationLog, PresentationSnapshot, PresentationTransaction,
    SLIDE_ENGINE_ID,
};
pub use renderer::{DrawCommand, SlideRenderer, TextRunCmd};
pub use scene::{Point, Rect, SceneGraph, Size, Transform};
pub use selection::{
    PresentationObjectSelection, PresentationSelection, PresentationSlideSelection,
};
pub use session::{presentation_session, PresentationSession};
pub use shape::{
    Fill, Geometry, ImageFit, Shape, Stroke, StrokeDash, TextAlign, TextBox, TextRun, VerticalAlign,
};
pub use slide::{Presentation, Slide, Theme, DEFAULT_SLIDE_HEIGHT, DEFAULT_SLIDE_WIDTH};

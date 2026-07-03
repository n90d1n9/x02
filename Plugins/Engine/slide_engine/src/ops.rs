use crate::{Presentation, Shape, Slide};
use serde::{Deserialize, Serialize};
use waraq_core::{
    ActorId, DocumentId, OfficeSnapshot, OperationApplier, OperationEnvelope, OperationId,
    OperationLog, OperationTransaction,
};

pub const SLIDE_ENGINE_ID: &str = "slide";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PresentationEdit {
    AddSlide {
        slide: Slide,
    },
    InsertSlide {
        after_index: usize,
        slide: Slide,
    },
    RemoveSlide {
        index: usize,
    },
    MoveSlide {
        from: usize,
        to: usize,
    },
    AddShape {
        slide_index: usize,
        shape: Shape,
    },
    RemoveShape {
        slide_index: usize,
        shape_id: String,
    },
    MoveShape {
        slide_index: usize,
        shape_id: String,
        dx: f64,
        dy: f64,
    },
    BringShapeToFront {
        slide_index: usize,
        shape_id: String,
    },
    SendShapeToBack {
        slide_index: usize,
        shape_id: String,
    },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum PresentationEditError {
    SlideNotFound {
        index: usize,
    },
    ShapeNotFound {
        slide_index: usize,
        shape_id: String,
    },
    InvalidSlideMove {
        from: usize,
        to: usize,
    },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PresentationEditOutcome {
    pub changed_slides: Vec<usize>,
    pub shape_id: Option<String>,
}

pub type PresentationOperation = OperationEnvelope<PresentationEdit>;
pub type PresentationOperationLog = OperationLog<PresentationEdit>;
pub type PresentationTransaction = OperationTransaction<PresentationEdit>;
pub type PresentationSnapshot = OfficeSnapshot<Presentation, PresentationEdit>;

pub fn presentation_operation(
    operation_id: impl Into<OperationId>,
    document_id: impl Into<DocumentId>,
    actor_id: impl Into<ActorId>,
    sequence: u64,
    timestamp_ms: u64,
    edit: PresentationEdit,
) -> PresentationOperation {
    OperationEnvelope::new(
        SLIDE_ENGINE_ID,
        operation_id,
        document_id,
        actor_id,
        sequence,
        timestamp_ms,
        edit,
    )
}

pub fn presentation_snapshot(
    document_id: impl Into<DocumentId>,
    sequence: u64,
    timestamp_ms: u64,
    presentation: Presentation,
    operation_log: PresentationOperationLog,
) -> PresentationSnapshot {
    OfficeSnapshot::new(
        SLIDE_ENGINE_ID,
        document_id,
        sequence,
        timestamp_ms,
        presentation,
    )
    .with_operation_log(operation_log)
}

impl PresentationEditOutcome {
    fn slide(index: usize) -> Self {
        Self {
            changed_slides: vec![index],
            shape_id: None,
        }
    }

    fn shape(slide_index: usize, shape_id: String) -> Self {
        Self {
            changed_slides: vec![slide_index],
            shape_id: Some(shape_id),
        }
    }
}

pub fn apply_presentation_edit(
    presentation: &mut Presentation,
    edit: PresentationEdit,
) -> Result<PresentationEditOutcome, PresentationEditError> {
    match edit {
        PresentationEdit::AddSlide { slide } => {
            let index = presentation.slides.len();
            presentation.add_slide(slide);
            Ok(PresentationEditOutcome::slide(index))
        }
        PresentationEdit::InsertSlide { after_index, slide } => {
            let index = (after_index + 1).min(presentation.slides.len());
            presentation.insert_slide(after_index, slide);
            Ok(PresentationEditOutcome::slide(index))
        }
        PresentationEdit::RemoveSlide { index } => {
            if presentation.remove_slide(index).is_some() {
                Ok(PresentationEditOutcome::slide(index))
            } else {
                Err(PresentationEditError::SlideNotFound { index })
            }
        }
        PresentationEdit::MoveSlide { from, to } => {
            if from >= presentation.slides.len() || to >= presentation.slides.len() {
                return Err(PresentationEditError::InvalidSlideMove { from, to });
            }
            presentation.move_slide(from, to);
            Ok(PresentationEditOutcome {
                changed_slides: vec![from, to],
                shape_id: None,
            })
        }
        PresentationEdit::AddShape { slide_index, shape } => {
            let shape_id = shape.id.clone();
            let slide = slide_mut(presentation, slide_index)?;
            slide.add_shape(shape);
            Ok(PresentationEditOutcome::shape(slide_index, shape_id))
        }
        PresentationEdit::RemoveShape {
            slide_index,
            shape_id,
        } => {
            let slide = slide_mut(presentation, slide_index)?;
            if slide.remove_shape(&shape_id).is_some() {
                Ok(PresentationEditOutcome::shape(slide_index, shape_id))
            } else {
                Err(PresentationEditError::ShapeNotFound {
                    slide_index,
                    shape_id,
                })
            }
        }
        PresentationEdit::MoveShape {
            slide_index,
            shape_id,
            dx,
            dy,
        } => {
            let slide = slide_mut(presentation, slide_index)?;
            let shape = slide.shapes.get_mut(&shape_id).ok_or_else(|| {
                PresentationEditError::ShapeNotFound {
                    slide_index,
                    shape_id: shape_id.clone(),
                }
            })?;
            shape.transform.tx += dx;
            shape.transform.ty += dy;
            Ok(PresentationEditOutcome::shape(slide_index, shape_id))
        }
        PresentationEdit::BringShapeToFront {
            slide_index,
            shape_id,
        } => {
            let slide = slide_mut(presentation, slide_index)?;
            ensure_shape_exists(slide, slide_index, &shape_id)?;
            slide.bring_to_front(&shape_id);
            Ok(PresentationEditOutcome::shape(slide_index, shape_id))
        }
        PresentationEdit::SendShapeToBack {
            slide_index,
            shape_id,
        } => {
            let slide = slide_mut(presentation, slide_index)?;
            ensure_shape_exists(slide, slide_index, &shape_id)?;
            slide.send_to_back(&shape_id);
            Ok(PresentationEditOutcome::shape(slide_index, shape_id))
        }
    }
}

pub fn apply_presentation_operation(
    presentation: &mut Presentation,
    operation: PresentationOperation,
) -> Result<PresentationEditOutcome, PresentationEditError> {
    apply_presentation_edit(presentation, operation.edit)
}

impl OperationApplier<PresentationEdit> for Presentation {
    type Outcome = PresentationEditOutcome;
    type Error = PresentationEditError;

    fn apply_operation(
        &mut self,
        operation: PresentationOperation,
    ) -> Result<Self::Outcome, Self::Error> {
        apply_presentation_operation(self, operation)
    }
}

fn slide_mut(
    presentation: &mut Presentation,
    index: usize,
) -> Result<&mut Slide, PresentationEditError> {
    presentation
        .slides
        .get_mut(index)
        .ok_or(PresentationEditError::SlideNotFound { index })
}

fn ensure_shape_exists(
    slide: &Slide,
    slide_index: usize,
    shape_id: &str,
) -> Result<(), PresentationEditError> {
    if slide.shapes.contains_key(shape_id) {
        Ok(())
    } else {
        Err(PresentationEditError::ShapeNotFound {
            slide_index,
            shape_id: shape_id.to_owned(),
        })
    }
}

impl Presentation {
    pub fn apply_edit(
        &mut self,
        edit: PresentationEdit,
    ) -> Result<PresentationEditOutcome, PresentationEditError> {
        apply_presentation_edit(self, edit)
    }

    pub fn apply_operation(
        &mut self,
        operation: PresentationOperation,
    ) -> Result<PresentationEditOutcome, PresentationEditError> {
        apply_presentation_operation(self, operation)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::scene::Rect;
    use waraq_core::Validatable;

    fn rect(id: &str) -> Shape {
        Shape::rect(id, Rect::new(0.0, 0.0, 100.0, 50.0), "#ff0000")
    }

    #[test]
    fn apply_slide_edits() {
        let mut presentation = Presentation::new("Deck");
        let outcome = presentation
            .apply_edit(PresentationEdit::AddSlide {
                slide: Slide::new("slide-1"),
            })
            .unwrap();
        assert_eq!(outcome.changed_slides, vec![0]);

        presentation
            .apply_edit(PresentationEdit::InsertSlide {
                after_index: 0,
                slide: Slide::new("slide-2"),
            })
            .unwrap();
        assert_eq!(presentation.slides[1].id, "slide-2");

        presentation
            .apply_edit(PresentationEdit::MoveSlide { from: 1, to: 0 })
            .unwrap();
        assert_eq!(presentation.slides[0].id, "slide-2");
    }

    #[test]
    fn apply_shape_edits_and_z_order() {
        let mut presentation = Presentation::new("Deck");
        presentation.add_slide(Slide::new("slide-1"));

        presentation
            .apply_edit(PresentationEdit::AddShape {
                slide_index: 0,
                shape: rect("bottom"),
            })
            .unwrap();
        presentation
            .apply_edit(PresentationEdit::AddShape {
                slide_index: 0,
                shape: rect("top"),
            })
            .unwrap();

        presentation
            .apply_edit(PresentationEdit::SendShapeToBack {
                slide_index: 0,
                shape_id: "top".into(),
            })
            .unwrap();
        assert_eq!(
            presentation.slides[0].scene_graph.draw_order(),
            &["top".to_string(), "bottom".to_string()]
        );

        presentation
            .apply_edit(PresentationEdit::MoveShape {
                slide_index: 0,
                shape_id: "bottom".into(),
                dx: 10.0,
                dy: 20.0,
            })
            .unwrap();
        let shape = presentation.slides[0].shapes.get("bottom").unwrap();
        assert_eq!(shape.transform.tx, 10.0);
        assert_eq!(shape.transform.ty, 20.0);
    }

    #[test]
    fn apply_shape_edit_reports_missing_shape() {
        let mut presentation = Presentation::new("Deck");
        presentation.add_slide(Slide::new("slide-1"));

        let err = presentation
            .apply_edit(PresentationEdit::RemoveShape {
                slide_index: 0,
                shape_id: "missing".into(),
            })
            .unwrap_err();

        assert_eq!(
            err,
            PresentationEditError::ShapeNotFound {
                slide_index: 0,
                shape_id: "missing".into(),
            }
        );
    }

    #[test]
    fn presentation_edit_json_roundtrip() {
        let edit = PresentationEdit::MoveShape {
            slide_index: 1,
            shape_id: "shape-1".into(),
            dx: 10.0,
            dy: 20.0,
        };

        let json = serde_json::to_string(&edit).unwrap();
        let restored: PresentationEdit = serde_json::from_str(&json).unwrap();

        match restored {
            PresentationEdit::MoveShape {
                slide_index,
                shape_id,
                dx,
                dy,
            } => {
                assert_eq!(slide_index, 1);
                assert_eq!(shape_id, "shape-1");
                assert_eq!(dx, 10.0);
                assert_eq!(dy, 20.0);
            }
            _ => panic!("expected move shape edit"),
        }
    }

    #[test]
    fn presentation_operation_roundtrip_and_apply() {
        let operation = presentation_operation(
            "op-1",
            "deck-1",
            "actor-1",
            1,
            10_000,
            PresentationEdit::AddSlide {
                slide: Slide::new("slide-1"),
            },
        )
        .with_metadata_text("source", "test");

        assert_eq!(operation.engine, SLIDE_ENGINE_ID);

        let json = operation.to_json().unwrap();
        let restored = PresentationOperation::from_json(&json).unwrap();

        let mut presentation = Presentation::new("Deck");
        let outcome = presentation.apply_operation(restored).unwrap();

        assert_eq!(outcome.changed_slides, vec![0]);
        assert_eq!(presentation.slides[0].id, "slide-1");
    }

    #[test]
    fn presentation_transaction_applies_operations_in_order() {
        let transaction = PresentationTransaction::new("tx-1")
            .with_operation(presentation_operation(
                "op-1",
                "deck-1",
                "actor-1",
                1,
                10_000,
                PresentationEdit::AddSlide {
                    slide: Slide::new("slide-1"),
                },
            ))
            .with_operation(presentation_operation(
                "op-2",
                "deck-1",
                "actor-1",
                2,
                10_001,
                PresentationEdit::AddShape {
                    slide_index: 0,
                    shape: rect("shape-1"),
                },
            ));

        transaction.validate().unwrap();

        let mut presentation = Presentation::new("Deck");
        let outcomes = waraq_core::apply_transaction(&mut presentation, &transaction).unwrap();

        assert_eq!(outcomes.len(), 2);
        assert_eq!(presentation.slides[0].id, "slide-1");
        assert!(presentation.slides[0].shapes.contains_key("shape-1"));
        assert_eq!(transaction.operation_log().operations.len(), 2);
    }

    #[test]
    fn presentation_snapshot_roundtrips_deck_and_operation_log() {
        let mut presentation = Presentation::new("Deck");
        let mut slide = Slide::new("slide-1");
        slide.add_shape(rect("shape-1"));
        presentation.add_slide(slide);

        let mut operation_log = PresentationOperationLog::new();
        operation_log.push(presentation_operation(
            "op-1",
            "deck-1",
            "actor-1",
            1,
            10_000,
            PresentationEdit::AddSlide {
                slide: Slide::new("slide-1"),
            },
        ));

        let snapshot = presentation_snapshot("deck-1", 1, 10_001, presentation, operation_log)
            .with_metadata_text("checkpoint", "autosave");
        let json = snapshot.to_json().unwrap();
        let restored = PresentationSnapshot::from_json(&json).unwrap();

        assert_eq!(restored.engine, SLIDE_ENGINE_ID);
        assert_eq!(restored.document_id, "deck-1");
        assert_eq!(restored.state.title, "Deck");
        assert_eq!(restored.state.slides[0].id, "slide-1");
        assert!(restored.state.slides[0].shapes.contains_key("shape-1"));
        assert_eq!(restored.operation_log.len(), 1);
        assert!(restored.validate_report().is_valid());
    }
}

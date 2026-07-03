use crate::{Presentation, PresentationEdit, SLIDE_ENGINE_ID};
use waraq_core::{DocumentId, OfficeDocumentSession};

pub type PresentationSession = OfficeDocumentSession<Presentation, PresentationEdit>;

pub fn presentation_session(
    document_id: impl Into<DocumentId>,
    presentation: Presentation,
) -> PresentationSession {
    OfficeDocumentSession::new(SLIDE_ENGINE_ID, document_id, presentation)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{presentation_operation, Slide};
    use waraq_core::{OfficeSelection, PageSelection, Validatable};

    #[test]
    fn presentation_session_applies_operation_and_snapshots_deck() {
        let mut session = presentation_session("deck-1", Presentation::new("Deck"));
        session.set_selection(OfficeSelection::Pages(PageSelection::single(0)));

        session
            .apply_operation(presentation_operation(
                "op-1",
                "deck-1",
                "actor-1",
                1,
                10_000,
                PresentationEdit::AddSlide {
                    slide: Slide::new("slide-1"),
                },
            ))
            .unwrap();

        let snapshot = session.snapshot(10_001);

        assert_eq!(session.state().slides[0].id, "slide-1");
        assert_eq!(snapshot.state.slides[0].id, "slide-1");
        assert_eq!(
            snapshot.selection,
            OfficeSelection::Pages(PageSelection::single(0))
        );
        assert_eq!(snapshot.operation_log.len(), 1);
        assert!(snapshot.validate_report().is_valid());
    }
}

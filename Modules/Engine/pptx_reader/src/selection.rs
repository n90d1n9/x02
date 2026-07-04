pub type PresentationObjectSelection = waraq_core::ObjectSelection;
pub type PresentationSelection = waraq_core::OfficeSelection;
pub type PresentationSlideSelection = waraq_core::PageSelection;

#[cfg(test)]
mod tests {
    use super::*;
    use waraq_core::ObjectId;

    #[test]
    fn presentation_object_selection_uses_core_object_selection() {
        let mut selection = PresentationObjectSelection::single("shape-1");
        selection.add("shape-2");

        assert_eq!(selection.primary, Some(ObjectId::new("shape-1")));
        assert!(selection.contains(&ObjectId::new("shape-2")));
    }

    #[test]
    fn presentation_slide_selection_keeps_active_slide() {
        let selection = PresentationSlideSelection::new(2, vec![0, 2]);

        assert_eq!(selection.active, 2);
        assert!(selection.contains(0));
        assert!(matches!(
            PresentationSelection::Pages(selection),
            PresentationSelection::Pages(_)
        ));
    }
}

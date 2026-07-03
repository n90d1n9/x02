pub type DocumentSelection = waraq_core::OfficeSelection;
pub type DocumentTextSelection = waraq_core::TextSelection;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn document_text_selection_uses_core_text_selection() {
        let selection = DocumentTextSelection::new(12, 4);

        assert_eq!(selection.range().start, 4);
        assert_eq!(selection.range().end, 12);
        assert!(matches!(
            DocumentSelection::Text(selection),
            DocumentSelection::Text(_)
        ));
    }
}

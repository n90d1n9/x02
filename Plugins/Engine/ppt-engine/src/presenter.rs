#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PresenterSession {
    pub presentation_id: String,
    pub slide_index: usize,
}

impl PresenterSession {
    pub fn new(presentation_id: impl Into<String>) -> Self {
        Self {
            presentation_id: presentation_id.into(),
            slide_index: 0,
        }
    }

    pub fn jump_to_slide(&mut self, slide_index: usize) {
        self.slide_index = slide_index;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tracks_presenter_slide_index() {
        let mut session = PresenterSession::new("deck-1");

        session.jump_to_slide(3);

        assert_eq!(session.presentation_id, "deck-1");
        assert_eq!(session.slide_index, 3);
    }
}

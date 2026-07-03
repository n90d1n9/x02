use crate::{Document, DocumentEdit, DOCUMENT_ENGINE_ID};
use waraq_core::{DocumentId, OfficeDocumentSession};

pub type DocumentSession = OfficeDocumentSession<Document, DocumentEdit>;

pub fn document_session(document_id: impl Into<DocumentId>, document: Document) -> DocumentSession {
    OfficeDocumentSession::new(DOCUMENT_ENGINE_ID, document_id, document)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{document_operation, Block, BlockType, InlineStyle};
    use waraq_core::{OfficeSelection, TextSelection, Validatable};

    fn paragraph(id: &str, text: &str) -> Block {
        let mut block = Block::new(id, BlockType::Paragraph);
        block.add_span(text, InlineStyle::default());
        block
    }

    #[test]
    fn document_session_applies_operation_and_snapshots_state() {
        let mut session = document_session("doc-1", Document::new("Draft"));
        session.set_selection(OfficeSelection::Text(TextSelection::caret(5)));

        session
            .apply_operation(document_operation(
                "op-1",
                "doc-1",
                "actor-1",
                1,
                10_000,
                crate::DocumentEdit::AddBlock {
                    block: paragraph("p1", "hello"),
                },
            ))
            .unwrap();

        let snapshot = session.snapshot(10_001);

        assert_eq!(session.state().blocks[0].spans[0].text, "hello");
        assert_eq!(snapshot.state.blocks[0].spans[0].text, "hello");
        assert_eq!(
            snapshot.selection,
            OfficeSelection::Text(TextSelection::caret(5))
        );
        assert_eq!(snapshot.operation_log.len(), 1);
        assert!(snapshot.validate_report().is_valid());
    }
}

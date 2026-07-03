use crate::{Block, Document};
use serde::{Deserialize, Serialize};
use waraq_core::{
    ActorId, DocumentId, OfficeSnapshot, OperationApplier, OperationEnvelope, OperationId,
    OperationLog, OperationTransaction,
};

pub const DOCUMENT_ENGINE_ID: &str = "docs";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DocumentEdit {
    AddBlock {
        block: Block,
    },
    InsertText {
        block_index: usize,
        span_index: usize,
        char_offset: usize,
        text: String,
    },
    SplitBlock {
        block_index: usize,
        span_index: usize,
        char_offset: usize,
    },
    DeleteBlock {
        block_index: usize,
    },
    ReplaceBlock {
        block_index: usize,
        block: Block,
    },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DocumentEditOutcome {
    pub changed_blocks: Vec<usize>,
}

pub type DocumentOperation = OperationEnvelope<DocumentEdit>;
pub type DocumentOperationLog = OperationLog<DocumentEdit>;
pub type DocumentTransaction = OperationTransaction<DocumentEdit>;
pub type DocumentSnapshot = OfficeSnapshot<Document, DocumentEdit>;

pub fn document_operation(
    operation_id: impl Into<OperationId>,
    document_id: impl Into<DocumentId>,
    actor_id: impl Into<ActorId>,
    sequence: u64,
    timestamp_ms: u64,
    edit: DocumentEdit,
) -> DocumentOperation {
    OperationEnvelope::new(
        DOCUMENT_ENGINE_ID,
        operation_id,
        document_id,
        actor_id,
        sequence,
        timestamp_ms,
        edit,
    )
}

pub fn document_snapshot(
    document_id: impl Into<DocumentId>,
    sequence: u64,
    timestamp_ms: u64,
    document: Document,
    operation_log: DocumentOperationLog,
) -> DocumentSnapshot {
    OfficeSnapshot::new(
        DOCUMENT_ENGINE_ID,
        document_id,
        sequence,
        timestamp_ms,
        document,
    )
    .with_operation_log(operation_log)
}

impl DocumentEditOutcome {
    fn single(index: usize) -> Self {
        Self {
            changed_blocks: vec![index],
        }
    }
}

pub fn apply_document_edit(
    document: &mut Document,
    edit: DocumentEdit,
) -> Result<DocumentEditOutcome, String> {
    match edit {
        DocumentEdit::AddBlock { block } => {
            let index = document.blocks.len();
            document.add_block(block);
            Ok(DocumentEditOutcome::single(index))
        }
        DocumentEdit::InsertText {
            block_index,
            span_index,
            char_offset,
            text,
        } => {
            document.insert_text(block_index, span_index, char_offset, &text)?;
            Ok(DocumentEditOutcome::single(block_index))
        }
        DocumentEdit::SplitBlock {
            block_index,
            span_index,
            char_offset,
        } => {
            document.split_block(block_index, span_index, char_offset)?;
            Ok(DocumentEditOutcome {
                changed_blocks: vec![block_index, block_index + 1],
            })
        }
        DocumentEdit::DeleteBlock { block_index } => {
            if block_index >= document.blocks.len() {
                return Err("Block not found".into());
            }
            document.blocks.remove(block_index);
            Ok(DocumentEditOutcome::single(block_index))
        }
        DocumentEdit::ReplaceBlock { block_index, block } => {
            let target = document
                .blocks
                .get_mut(block_index)
                .ok_or("Block not found")?;
            *target = block;
            Ok(DocumentEditOutcome::single(block_index))
        }
    }
}

pub fn apply_document_operation(
    document: &mut Document,
    operation: DocumentOperation,
) -> Result<DocumentEditOutcome, String> {
    apply_document_edit(document, operation.edit)
}

impl OperationApplier<DocumentEdit> for Document {
    type Outcome = DocumentEditOutcome;
    type Error = String;

    fn apply_operation(
        &mut self,
        operation: DocumentOperation,
    ) -> Result<Self::Outcome, Self::Error> {
        apply_document_operation(self, operation)
    }
}

impl Document {
    pub fn apply_edit(&mut self, edit: DocumentEdit) -> Result<DocumentEditOutcome, String> {
        apply_document_edit(self, edit)
    }

    pub fn apply_operation(
        &mut self,
        operation: DocumentOperation,
    ) -> Result<DocumentEditOutcome, String> {
        apply_document_operation(self, operation)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{BlockType, InlineStyle};
    use waraq_core::Validatable;

    fn paragraph(id: &str, text: &str) -> Block {
        let mut block = Block::new(id, BlockType::Paragraph);
        block.add_span(text, InlineStyle::default());
        block
    }

    #[test]
    fn apply_insert_and_split_edits() {
        let mut document = Document::new("Draft");
        document
            .apply_edit(DocumentEdit::AddBlock {
                block: paragraph("p1", "hello world"),
            })
            .unwrap();

        let outcome = document
            .apply_edit(DocumentEdit::InsertText {
                block_index: 0,
                span_index: 0,
                char_offset: 5,
                text: ",".into(),
            })
            .unwrap();
        assert_eq!(outcome.changed_blocks, vec![0]);
        assert_eq!(document.blocks[0].spans[0].text, "hello, world");

        let outcome = document
            .apply_edit(DocumentEdit::SplitBlock {
                block_index: 0,
                span_index: 0,
                char_offset: 6,
            })
            .unwrap();
        assert_eq!(outcome.changed_blocks, vec![0, 1]);
        assert_eq!(document.blocks[0].spans[0].text, "hello,");
        assert_eq!(document.blocks[1].spans[0].text, " world");
    }

    #[test]
    fn apply_delete_and_replace_edits() {
        let mut document = Document::new("Draft");
        document.add_block(paragraph("p1", "first"));
        document.add_block(paragraph("p2", "second"));

        document
            .apply_edit(DocumentEdit::ReplaceBlock {
                block_index: 1,
                block: paragraph("p3", "replacement"),
            })
            .unwrap();
        assert_eq!(document.blocks[1].spans[0].text, "replacement");

        document
            .apply_edit(DocumentEdit::DeleteBlock { block_index: 0 })
            .unwrap();
        assert_eq!(document.blocks.len(), 1);
        assert_eq!(document.blocks[0].id, "p3");
    }

    #[test]
    fn document_edit_json_roundtrip() {
        let edit = DocumentEdit::InsertText {
            block_index: 0,
            span_index: 1,
            char_offset: 2,
            text: "hi".into(),
        };

        let json = serde_json::to_string(&edit).unwrap();
        let restored: DocumentEdit = serde_json::from_str(&json).unwrap();

        match restored {
            DocumentEdit::InsertText {
                block_index,
                span_index,
                char_offset,
                text,
            } => {
                assert_eq!(block_index, 0);
                assert_eq!(span_index, 1);
                assert_eq!(char_offset, 2);
                assert_eq!(text, "hi");
            }
            _ => panic!("expected insert edit"),
        }
    }

    #[test]
    fn document_operation_roundtrip_and_apply() {
        let operation = document_operation(
            "op-1",
            "doc-1",
            "actor-1",
            1,
            10_000,
            DocumentEdit::AddBlock {
                block: paragraph("p1", "hello"),
            },
        )
        .with_metadata_text("source", "test");

        assert_eq!(operation.engine, DOCUMENT_ENGINE_ID);

        let json = operation.to_json().unwrap();
        let restored = DocumentOperation::from_json(&json).unwrap();

        let mut document = Document::new("Draft");
        let outcome = document.apply_operation(restored).unwrap();

        assert_eq!(outcome.changed_blocks, vec![0]);
        assert_eq!(document.blocks[0].spans[0].text, "hello");
    }

    #[test]
    fn document_transaction_applies_operations_in_order() {
        let transaction = DocumentTransaction::new("tx-1")
            .with_operation(document_operation(
                "op-1",
                "doc-1",
                "actor-1",
                1,
                10_000,
                DocumentEdit::AddBlock {
                    block: paragraph("p1", "hello"),
                },
            ))
            .with_operation(document_operation(
                "op-2",
                "doc-1",
                "actor-1",
                2,
                10_001,
                DocumentEdit::InsertText {
                    block_index: 0,
                    span_index: 0,
                    char_offset: 5,
                    text: " team".into(),
                },
            ));

        transaction.validate().unwrap();

        let mut document = Document::new("Draft");
        let outcomes = waraq_core::apply_transaction(&mut document, &transaction).unwrap();

        assert_eq!(outcomes.len(), 2);
        assert_eq!(document.blocks[0].spans[0].text, "hello team");
        assert_eq!(transaction.operation_log().operations.len(), 2);
    }

    #[test]
    fn document_snapshot_roundtrips_state_and_operation_log() {
        let mut document = Document::new("Draft");
        document.add_block(paragraph("p1", "hello"));

        let mut operation_log = DocumentOperationLog::new();
        operation_log.push(document_operation(
            "op-1",
            "doc-1",
            "actor-1",
            1,
            10_000,
            DocumentEdit::AddBlock {
                block: paragraph("p1", "hello"),
            },
        ));

        let snapshot = document_snapshot("doc-1", 1, 10_001, document, operation_log)
            .with_metadata_text("checkpoint", "autosave");
        let json = snapshot.to_json().unwrap();
        let restored = DocumentSnapshot::from_json(&json).unwrap();

        assert_eq!(restored.engine, DOCUMENT_ENGINE_ID);
        assert_eq!(restored.document_id, "doc-1");
        assert_eq!(restored.state.title, "Draft");
        assert_eq!(restored.state.blocks[0].spans[0].text, "hello");
        assert_eq!(restored.operation_log.len(), 1);
        assert!(restored.validate_report().is_valid());
    }
}

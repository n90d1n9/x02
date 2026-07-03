pub use waraq_core::core;

pub mod block;
pub mod document;
pub mod ops;
pub mod selection;
pub mod session;

pub use block::{Block, BlockType, InlineStyle};
pub use document::Document;
pub use ops::{
    apply_document_edit, apply_document_operation, document_operation, document_snapshot,
    DocumentEdit, DocumentEditOutcome, DocumentOperation, DocumentOperationLog, DocumentSnapshot,
    DocumentTransaction, DOCUMENT_ENGINE_ID,
};
pub use selection::{DocumentSelection, DocumentTextSelection};
pub use session::{document_session, DocumentSession};

//! Content-model rules: *which children a block type is allowed to have*.
//!
//! This is deliberately separate from `schema.rs` (which defines what
//! node/mark *kinds exist*) and from `transaction.rs` (which defines
//! *how* the tree mutates). Keeping validation in its own module means
//! the rules can change — e.g. to make `TableCell` allow full block
//! content instead of just paragraphs — without touching either the
//! type definitions or the op-application logic.

use crate::schema::BlockType;
use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Clone, Copy)]
pub enum ChildRef<'a> {
    Text,
    Block(&'a BlockType),
}

impl<'a> std::fmt::Display for ChildRef<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ChildRef::Text => write!(f, "text"),
            ChildRef::Block(bt) => write!(f, "{bt:?}"),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Error)]
#[error("{parent:?} cannot contain {child}")]
pub struct SchemaViolation {
    pub parent: BlockType,
    pub child: String,
}

/// The single source of truth for "can `parent` contain `child`".
/// `Custom` block types are deliberately permissive — they're the
/// extension point for app-specific content and shouldn't require
/// editing this crate to add. If an app needs its custom blocks
/// strictly validated too, that's a natural place to grow this function
/// into a pluggable registry later without changing any call sites.
pub fn validate_child(parent: &BlockType, child: ChildRef) -> Result<(), SchemaViolation> {
    let ok = match parent {
        BlockType::Doc => matches!(
            child,
            ChildRef::Block(bt) if matches!(
                bt,
                BlockType::Paragraph
                    | BlockType::Heading
                    | BlockType::BulletList
                    | BlockType::OrderedList
                    | BlockType::CodeBlock
                    | BlockType::Blockquote
                    | BlockType::Image
                    | BlockType::HorizontalRule
                    | BlockType::Table
                    | BlockType::Custom(_)
            )
        ),
        BlockType::Paragraph | BlockType::Heading | BlockType::CodeBlock => matches!(child, ChildRef::Text),
        BlockType::BulletList | BlockType::OrderedList => {
            matches!(child, ChildRef::Block(BlockType::ListItem))
        }
        // List items may hold inline text directly, a wrapping
        // paragraph, or a nested list — this is what makes nested lists
        // possible without a special-cased "nested list" node type.
        BlockType::ListItem => matches!(
            child,
            ChildRef::Text
                | ChildRef::Block(BlockType::Paragraph)
                | ChildRef::Block(BlockType::BulletList)
                | ChildRef::Block(BlockType::OrderedList)
        ),
        BlockType::Blockquote => matches!(
            child,
            ChildRef::Block(bt) if matches!(
                bt,
                BlockType::Paragraph
                    | BlockType::Heading
                    | BlockType::BulletList
                    | BlockType::OrderedList
                    | BlockType::CodeBlock
            )
        ),
        BlockType::Table => matches!(child, ChildRef::Block(BlockType::TableRow)),
        BlockType::TableRow => matches!(child, ChildRef::Block(BlockType::TableCell)),
        BlockType::TableCell => matches!(child, ChildRef::Text | ChildRef::Block(BlockType::Paragraph)),
        BlockType::Image | BlockType::HorizontalRule => false, // leaves: never any children
        BlockType::Custom(_) => true,
    };
    if ok {
        Ok(())
    } else {
        Err(SchemaViolation { parent: parent.clone(), child: child.to_string() })
    }
}

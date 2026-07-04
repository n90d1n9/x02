//! The schema module defines *what a document is allowed to contain*.
//!
//! This is the piece Quill hides from you: block types, mark types, and
//! their attributes are all defined here as plain Rust data, so adding a
//! new block type is a one-line enum variant, not a package patch.

use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// A block-level node type. `Custom` exists so callers (including an
/// agent) can register application-specific block kinds without forking
/// this crate — the schema stays data-driven rather than closed.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum BlockType {
    Doc,
    Paragraph,
    Heading,
    BulletList,
    OrderedList,
    ListItem,
    CodeBlock,
    Blockquote,
    Image,
    HorizontalRule,
    Table,
    TableRow,
    TableCell,
    /// Escape hatch for app-specific blocks (e.g. "callout", "embed:tweet").
    Custom(String),
}

impl BlockType {
    /// Whether this block type is allowed to hold text-run children
    /// directly (as opposed to only other blocks).
    pub fn allows_inline_children(&self) -> bool {
        matches!(
            self,
            BlockType::Paragraph
                | BlockType::Heading
                | BlockType::ListItem
                | BlockType::CodeBlock
                | BlockType::TableCell
                | BlockType::Custom(_)
        )
    }

    /// Whether this block type is a leaf (no children at all).
    pub fn is_leaf(&self) -> bool {
        matches!(self, BlockType::Image | BlockType::HorizontalRule)
    }
}

/// Inline formatting applied to a run of text. `Custom` is again the
/// escape hatch for app-defined marks (e.g. "highlight:yellow").
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Mark {
    Bold,
    Italic,
    Underline,
    Strike,
    Code,
    Link { href: String },
    Custom { name: String, attrs: BTreeMap<String, AttrValue> },
}

impl Mark {
    /// A stable tag used for equality/lookup that ignores payload
    /// (e.g. two `Link`s with different hrefs are the "same mark type").
    pub fn tag(&self) -> MarkTag {
        match self {
            Mark::Bold => MarkTag::Bold,
            Mark::Italic => MarkTag::Italic,
            Mark::Underline => MarkTag::Underline,
            Mark::Strike => MarkTag::Strike,
            Mark::Code => MarkTag::Code,
            Mark::Link { .. } => MarkTag::Link,
            Mark::Custom { name, .. } => MarkTag::Custom(name.clone()),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum MarkTag {
    Bold,
    Italic,
    Underline,
    Strike,
    Code,
    Link,
    Custom(String),
}

/// A generic attribute value, used both for block attrs (e.g. heading
/// level, image src) and custom mark attrs.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(untagged)]
pub enum AttrValue {
    Text(String),
    Number(f64),
    Bool(bool),
    List(Vec<AttrValue>),
    Null,
}

impl From<&str> for AttrValue {
    fn from(s: &str) -> Self {
        AttrValue::Text(s.to_string())
    }
}
impl From<f64> for AttrValue {
    fn from(n: f64) -> Self {
        AttrValue::Number(n)
    }
}
impl From<bool> for AttrValue {
    fn from(b: bool) -> Self {
        AttrValue::Bool(b)
    }
}

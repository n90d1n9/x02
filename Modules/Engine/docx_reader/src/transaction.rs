//! Every mutation to a document happens through an `Op`. There is no
//! other way to change a `Tree` — this is what makes the engine safe to
//! drive from Dart across FFI *and* from an LLM agent: both sides send
//! the same small, typed vocabulary of operations, never raw tree
//! mutations.
//!
//! Applying an `Op` (or a `Transaction` = `Vec<Op>`) returns the inverse
//! ops needed to undo it, so undo/redo is "apply the inverse
//! transaction" rather than a separate code path.

use crate::schema::{AttrValue, BlockType, Mark, MarkTag};
use crate::tree::{DocError, DocResult, Node, NodeId, NodeKind, Tree};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

/// A serializable spec for a node (and its subtree) that hasn't been
/// allocated into a `Tree` yet. Used for `InsertNode` payloads and as
/// the inverse payload for `DeleteNode` (so undo can fully reconstruct
/// a deleted subtree).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "kind")]
pub enum NewNodeSpec {
    Block {
        node_type: BlockType,
        #[serde(default)]
        attrs: BTreeMap<String, AttrValue>,
        #[serde(default)]
        children: Vec<NewNodeSpec>,
    },
    Text {
        text: String,
        #[serde(default)]
        marks: Vec<Mark>,
    },
}

impl NewNodeSpec {
    pub fn paragraph(text: impl Into<String>) -> Self {
        NewNodeSpec::Block {
            node_type: BlockType::Paragraph,
            attrs: BTreeMap::new(),
            children: vec![NewNodeSpec::Text { text: text.into(), marks: vec![] }],
        }
    }
}

/// The full vocabulary of document edits. This enum *is* the API
/// surface an agentic tool-call would target: give an LLM this schema
/// (via `serde_json::to_value` on a described version, see `agent.rs`)
/// and it can emit valid edits directly.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "op", rename_all = "snake_case")]
pub enum Op {
    InsertText { node: NodeId, offset: usize, text: String },
    DeleteText { node: NodeId, start: usize, end: usize },
    /// Splits a text node into two text nodes (same marks) at `offset`.
    SplitText { node: NodeId, offset: usize },
    /// "Press Enter" at `offset` within text node `node`: splits the
    /// enclosing block into two sibling blocks.
    SplitBlock { node: NodeId, offset: usize },
    /// Merge `second` block's children onto the end of `first` block's
    /// children, then remove `second`. Blocks must be adjacent siblings.
    MergeBlocks { first: NodeId, second: NodeId },
    AddMark { node: NodeId, mark: Mark },
    RemoveMark { node: NodeId, mark: MarkTag },
    SetAttr { node: NodeId, key: String, value: AttrValue },
    InsertNode { parent: NodeId, index: usize, node: NewNodeSpec },
    DeleteNode { node: NodeId },

    // --- inverse-only ops: never emitted directly by callers, only
    // produced as the inverse of SplitText / MergeBlocks / SetAttr, but
    // are still ordinary Ops so `apply_transaction` can replay them
    // uniformly for undo/redo. ---
    /// Inverse of `SplitText`: merge `left` and `right` text nodes back
    /// into a single node re-using the id `original`.
    MergeTextPair { left: NodeId, right: NodeId, original: NodeId },
    /// Inverse of `MergeBlocks`: recreate `second_id` at `second_index`
    /// under `second_parent`, moving `first`'s children from
    /// `split_at_child_index` onward into it.
    UnmergeBlocks { first: NodeId, split_at_child_index: usize, second_id: NodeId, second_parent: NodeId, second_index: usize },
    /// Inverse of `SetAttr` when the key previously had no value.
    ClearAttr { node: NodeId, key: String },
}

/// Result of applying a single `Op`: the inverse op(s) needed to undo
/// it, plus any newly allocated node ids (so a caller — Dart or an
/// agent — can address freshly created nodes without a round trip).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct OpOutcome {
    pub inverse: Vec<Op>,
    pub created: Vec<NodeId>,
}

pub type Transaction = Vec<Op>;

/// Apply a whole transaction; on error, roll back everything already
/// applied in this call by re-applying the inverses collected so far.
pub fn apply_transaction(tree: &mut Tree, ops: &[Op]) -> DocResult<OpOutcome> {
    let mut inverses: Vec<Op> = Vec::new();
    let mut created: Vec<NodeId> = Vec::new();
    for op in ops {
        match apply_op(tree, op) {
            Ok(mut outcome) => {
                created.append(&mut outcome.created);
                // Undo of the whole transaction = inverses in reverse order.
                inverses.splice(0..0, outcome.inverse);
            }
            Err(e) => {
                // Roll back what succeeded so far.
                let _ = apply_transaction(tree, &inverses);
                return Err(e);
            }
        }
    }
    Ok(OpOutcome { inverse: inverses, created })
}

pub fn apply_op(tree: &mut Tree, op: &Op) -> DocResult<OpOutcome> {
    match op {
        Op::InsertText { node, offset, text } => insert_text(tree, *node, *offset, text),
        Op::DeleteText { node, start, end } => delete_text(tree, *node, *start, *end),
        Op::SplitText { node, offset } => split_text(tree, *node, *offset),
        Op::SplitBlock { node, offset } => split_block(tree, *node, *offset),
        Op::MergeBlocks { first, second } => merge_blocks(tree, *first, *second),
        Op::AddMark { node, mark } => add_mark(tree, *node, mark.clone()),
        Op::RemoveMark { node, mark } => remove_mark(tree, *node, mark.clone()),
        Op::SetAttr { node, key, value } => set_attr(tree, *node, key.clone(), value.clone()),
        Op::InsertNode { parent, index, node } => insert_node(tree, *parent, *index, node.clone()),
        Op::DeleteNode { node } => delete_node(tree, *node),
        Op::MergeTextPair { left, right, original } => merge_text_pair(tree, *left, *right, *original),
        Op::UnmergeBlocks { first, split_at_child_index, second_id, second_parent, second_index } => {
            unmerge_blocks(tree, *first, *split_at_child_index, *second_id, *second_parent, *second_index)
        }
        Op::ClearAttr { node, key } => clear_attr(tree, *node, key.clone()),
    }
}

// ---- primitive ops -------------------------------------------------

fn text_mut<'a>(tree: &'a mut Tree, id: NodeId) -> DocResult<(&'a mut String, &'a mut Vec<Mark>)> {
    match &mut tree.get_mut(id)?.kind {
        NodeKind::Text { text, marks } => Ok((text, marks)),
        NodeKind::Block { .. } => Err(DocError::NotText(id)),
    }
}

fn insert_text(tree: &mut Tree, node: NodeId, offset: usize, text: &str) -> DocResult<OpOutcome> {
    let (s, _) = text_mut(tree, node)?;
    if offset > s.chars().count() {
        return Err(DocError::OffsetOutOfBounds { node, offset, len: s.chars().count() });
    }
    let byte_off = char_to_byte(s, offset);
    s.insert_str(byte_off, text);
    let inverse = Op::DeleteText { node, start: offset, end: offset + text.chars().count() };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![] })
}

fn delete_text(tree: &mut Tree, node: NodeId, start: usize, end: usize) -> DocResult<OpOutcome> {
    let (s, _) = text_mut(tree, node)?;
    let len = s.chars().count();
    if start > len || end > len || start > end {
        return Err(DocError::OffsetOutOfBounds { node, offset: end, len });
    }
    let b_start = char_to_byte(s, start);
    let b_end = char_to_byte(s, end);
    let removed: String = s[b_start..b_end].to_string();
    s.replace_range(b_start..b_end, "");
    let inverse = Op::InsertText { node, offset: start, text: removed };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![] })
}

fn split_text(tree: &mut Tree, node: NodeId, offset: usize) -> DocResult<OpOutcome> {
    let parent = tree.get(node)?.parent.ok_or(DocError::NodeNotFound(node))?;
    let (left_text, right_text, marks) = {
        let (s, marks) = text_mut(tree, node)?;
        let len = s.chars().count();
        if offset > len {
            return Err(DocError::OffsetOutOfBounds { node, offset, len });
        }
        let b = char_to_byte(s, offset);
        let right = s[b..].to_string();
        let left = s[..b].to_string();
        (left, right, marks.clone())
    };

    // Find this node's position among its parent's children.
    let (_, idx_in_parent) = tree.detach_child(node)?;

    let left_id = tree.alloc_id();
    let right_id = tree.alloc_id();
    tree.insert_raw(Node { id: left_id, parent: Some(parent), kind: NodeKind::Text { text: left_text, marks: marks.clone() } });
    tree.insert_raw(Node { id: right_id, parent: Some(parent), kind: NodeKind::Text { text: right_text, marks } });
    tree.splice_child(parent, idx_in_parent, right_id)?;
    tree.splice_child(parent, idx_in_parent, left_id)?;
    tree.remove_raw(node);

    let inverse = Op::MergeTextPair { left: left_id, right: right_id, original: node };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![left_id, right_id] })
}

fn split_block(tree: &mut Tree, node: NodeId, offset: usize) -> DocResult<OpOutcome> {
    let block = tree.get(node)?.parent.ok_or(DocError::NodeNotFound(node))?;
    let (block_type, attrs, children) = match &tree.get(block)?.kind {
        NodeKind::Block { node_type, attrs, children } => (node_type.clone(), attrs.clone(), children.clone()),
        NodeKind::Text { .. } => return Err(DocError::NotBlock(block)),
    };
    let grandparent = tree.get(block)?.parent.ok_or(DocError::NodeNotFound(block))?;
    let (_, block_index) = tree.detach_child(block)?;
    // re-attach block where it was for now; we'll rebuild via two new blocks
    tree.splice_child(grandparent, block_index, block)?;

    let split_pos = children.iter().position(|c| *c == node).ok_or(DocError::NodeNotFound(node))?;

    // Split the text node itself first if offset is inside it (not at edges).
    let text_len = match &tree.get(node)?.kind {
        NodeKind::Text { text, .. } => text.chars().count(),
        NodeKind::Block { .. } => return Err(DocError::NotText(node)),
    };

    let mut created_ids = vec![];
    let right_children: Vec<NodeId>;
    if offset == 0 {
        right_children = children[split_pos..].to_vec();
    } else if offset == text_len {
        right_children = children[split_pos + 1..].to_vec();
    } else {
        let outcome = split_text(tree, node, offset)?;
        created_ids.extend(outcome.created.iter().copied());
        let left_id = outcome.created[0];
        let right_id = outcome.created[1];
        let mut new_children = children.clone();
        new_children.splice(split_pos..split_pos + 1, [left_id, right_id]);
        right_children = new_children[split_pos + 1..].to_vec();
        // left_children unused directly; block's own children vec is updated below via detach
        let _ = left_id;
    }

    // Detach right_children from the original block.
    for c in &right_children {
        tree.detach_child(*c).ok();
    }

    let new_block_id = tree.alloc_id();
    created_ids.push(new_block_id);
    tree.insert_raw(Node {
        id: new_block_id,
        parent: Some(grandparent),
        kind: NodeKind::Block { node_type: block_type, attrs, children: vec![] },
    });
    for (i, c) in right_children.iter().enumerate() {
        tree.splice_child(new_block_id, i, *c)?;
    }
    // Insert the new block right after the original.
    let (_, orig_index_now) = {
        let gp_children = tree.children_of(grandparent)?;
        let idx = gp_children.iter().position(|c| *c == block).unwrap();
        (block, idx)
    };
    tree.splice_child(grandparent, orig_index_now + 1, new_block_id)?;

    let inverse = Op::MergeBlocks { first: block, second: new_block_id };
    Ok(OpOutcome { inverse: vec![inverse], created: created_ids })
}

fn merge_blocks(tree: &mut Tree, first: NodeId, second: NodeId) -> DocResult<OpOutcome> {
    let second_children = match &tree.get(second)?.kind {
        NodeKind::Block { children, .. } => children.clone(),
        NodeKind::Text { .. } => return Err(DocError::NotBlock(second)),
    };
    let first_len = match &tree.get(first)?.kind {
        NodeKind::Block { children, .. } => children.len(),
        NodeKind::Text { .. } => return Err(DocError::NotBlock(first)),
    };
    for c in &second_children {
        tree.detach_child(*c).ok();
    }
    for (i, c) in second_children.iter().enumerate() {
        tree.splice_child(first, first_len + i, *c)?;
    }
    let (grandparent, second_index) = tree.detach_child(second)?;
    tree.remove_raw(second);

    let inverse = Op::UnmergeBlocks {
        first,
        split_at_child_index: first_len,
        second_id: second,
        second_parent: grandparent,
        second_index,
    };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![] })
}

fn add_mark(tree: &mut Tree, node: NodeId, mark: Mark) -> DocResult<OpOutcome> {
    let tag = mark.tag();
    let (_, marks) = text_mut(tree, node)?;
    let already = marks.iter().any(|m| m.tag() == tag);
    if !already {
        marks.push(mark.clone());
    }
    let inverse = Op::RemoveMark { node, mark: tag };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![] })
}

fn remove_mark(tree: &mut Tree, node: NodeId, tag: MarkTag) -> DocResult<OpOutcome> {
    let (_, marks) = text_mut(tree, node)?;
    let removed = marks.iter().find(|m| m.tag() == tag).cloned();
    marks.retain(|m| m.tag() != tag);
    let inverse = match removed {
        Some(m) => vec![Op::AddMark { node, mark: m }],
        None => vec![],
    };
    Ok(OpOutcome { inverse, created: vec![] })
}

fn set_attr(tree: &mut Tree, node: NodeId, key: String, value: AttrValue) -> DocResult<OpOutcome> {
    let old = match &mut tree.get_mut(node)?.kind {
        NodeKind::Block { attrs, .. } => attrs.insert(key.clone(), value),
        NodeKind::Text { .. } => return Err(DocError::NotBlock(node)),
    };
    let inverse = match old {
        Some(old_val) => Op::SetAttr { node, key, value: old_val },
        None => Op::ClearAttr { node, key },
    };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![] })
}

fn clear_attr(tree: &mut Tree, node: NodeId, key: String) -> DocResult<OpOutcome> {
    let old = match &mut tree.get_mut(node)?.kind {
        NodeKind::Block { attrs, .. } => attrs.remove(&key),
        NodeKind::Text { .. } => return Err(DocError::NotBlock(node)),
    };
    let inverse = match old {
        Some(old_val) => vec![Op::SetAttr { node, key, value: old_val }],
        None => vec![],
    };
    Ok(OpOutcome { inverse, created: vec![] })
}

fn insert_node(tree: &mut Tree, parent: NodeId, index: usize, spec: NewNodeSpec) -> DocResult<OpOutcome> {
    let parent_type = match &tree.get(parent)?.kind {
        NodeKind::Block { node_type, .. } => node_type.clone(),
        NodeKind::Text { .. } => return Err(DocError::NotBlock(parent)),
    };
    let child_ref = match &spec {
        NewNodeSpec::Text { .. } => crate::content_model::ChildRef::Text,
        NewNodeSpec::Block { node_type, .. } => crate::content_model::ChildRef::Block(node_type),
    };
    crate::content_model::validate_child(&parent_type, child_ref)?;
    validate_spec_recursive(&spec)?;

    let new_id = materialize(tree, parent, spec);
    tree.splice_child(parent, index, new_id)?;
    let inverse = Op::DeleteNode { node: new_id };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![new_id] })
}

/// Recursively check that every block's declared children are legal for
/// its type, *before* any of it is materialized into the tree. This
/// stops an agent (or a bug) from constructing a self-consistent-looking
/// but schema-invalid subtree in one shot.
fn validate_spec_recursive(spec: &NewNodeSpec) -> DocResult<()> {
    if let NewNodeSpec::Block { node_type, children, .. } = spec {
        for child in children {
            let child_ref = match child {
                NewNodeSpec::Text { .. } => crate::content_model::ChildRef::Text,
                NewNodeSpec::Block { node_type: ct, .. } => crate::content_model::ChildRef::Block(ct),
            };
            crate::content_model::validate_child(node_type, child_ref)?;
            validate_spec_recursive(child)?;
        }
    }
    Ok(())
}

fn delete_node(tree: &mut Tree, node: NodeId) -> DocResult<OpOutcome> {
    let spec = capture_subtree(tree, node)?;
    let (parent, index) = tree.detach_child(node)?;
    remove_subtree(tree, node);
    let inverse = Op::InsertNode { parent, index, node: spec };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![] })
}

fn merge_text_pair(tree: &mut Tree, left: NodeId, right: NodeId, original: NodeId) -> DocResult<OpOutcome> {
    let (left_text, marks) = match &tree.get(left)?.kind {
        NodeKind::Text { text, marks } => (text.clone(), marks.clone()),
        NodeKind::Block { .. } => return Err(DocError::NotText(left)),
    };
    let right_text = match &tree.get(right)?.kind {
        NodeKind::Text { text, .. } => text.clone(),
        NodeKind::Block { .. } => return Err(DocError::NotText(right)),
    };
    let split_offset = left_text.chars().count();
    let (parent, left_index) = tree.detach_child(left)?;
    tree.detach_child(right)?;
    tree.remove_raw(left);
    tree.remove_raw(right);

    let merged = format!("{left_text}{right_text}");
    tree.insert_raw(Node { id: original, parent: Some(parent), kind: NodeKind::Text { text: merged, marks } });
    tree.splice_child(parent, left_index, original)?;

    let inverse = Op::SplitText { node: original, offset: split_offset };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![original] })
}

fn unmerge_blocks(
    tree: &mut Tree,
    first: NodeId,
    split_at_child_index: usize,
    second_id: NodeId,
    second_parent: NodeId,
    second_index: usize,
) -> DocResult<OpOutcome> {
    let (block_type, attrs, moved_children) = match &tree.get(first)?.kind {
        NodeKind::Block { node_type, attrs, children } => {
            let moved = children[split_at_child_index..].to_vec();
            (node_type.clone(), attrs.clone(), moved)
        }
        NodeKind::Text { .. } => return Err(DocError::NotBlock(first)),
    };
    for c in &moved_children {
        tree.detach_child(*c).ok();
    }
    tree.insert_raw(Node {
        id: second_id,
        parent: Some(second_parent),
        kind: NodeKind::Block { node_type: block_type, attrs, children: vec![] },
    });
    for (i, c) in moved_children.iter().enumerate() {
        tree.splice_child(second_id, i, *c)?;
    }
    tree.splice_child(second_parent, second_index, second_id)?;

    let inverse = Op::MergeBlocks { first, second: second_id };
    Ok(OpOutcome { inverse: vec![inverse], created: vec![second_id] })
}

// ---- helpers ---------------------------------------------------------

fn char_to_byte(s: &str, char_idx: usize) -> usize {
    s.char_indices().nth(char_idx).map(|(b, _)| b).unwrap_or(s.len())
}

fn materialize(tree: &mut Tree, parent: NodeId, spec: NewNodeSpec) -> NodeId {
    let id = tree.alloc_id();
    match spec {
        NewNodeSpec::Text { text, marks } => {
            tree.insert_raw(Node { id, parent: Some(parent), kind: NodeKind::Text { text, marks } });
        }
        NewNodeSpec::Block { node_type, attrs, children } => {
            tree.insert_raw(Node { id, parent: Some(parent), kind: NodeKind::Block { node_type, attrs, children: vec![] } });
            for (i, child_spec) in children.into_iter().enumerate() {
                let child_id = materialize(tree, id, child_spec);
                tree.splice_child(id, i, child_id).ok();
            }
        }
    }
    id
}

fn capture_subtree(tree: &Tree, id: NodeId) -> DocResult<NewNodeSpec> {
    let node = tree.get(id)?;
    Ok(match &node.kind {
        NodeKind::Text { text, marks } => NewNodeSpec::Text { text: text.clone(), marks: marks.clone() },
        NodeKind::Block { node_type, attrs, children } => {
            let mut child_specs = Vec::with_capacity(children.len());
            for c in children {
                child_specs.push(capture_subtree(tree, *c)?);
            }
            NewNodeSpec::Block { node_type: node_type.clone(), attrs: attrs.clone(), children: child_specs }
        }
    })
}

fn remove_subtree(tree: &mut Tree, id: NodeId) {
    let children = match tree.get(id) {
        Ok(Node { kind: NodeKind::Block { children, .. }, .. }) => children.clone(),
        _ => vec![],
    };
    for c in children {
        remove_subtree(tree, c);
    }
    tree.remove_raw(id);
}

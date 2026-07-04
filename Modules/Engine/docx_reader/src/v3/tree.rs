//! Arena-based document tree.
//!
//! Nodes are stored flat in a `HashMap<NodeId, Node>` rather than as
//! nested owned structs. This makes node addressing stable (an agent or
//! the Flutter side can hold a `NodeId` across edits), avoids borrow-
//! checker pain from parent/child ownership, and mirrors how ProseMirror
//! / Lexical style engines represent state internally.

use crate::schema::{AttrValue, BlockType, Mark};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::collections::HashMap;
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
pub struct NodeId(pub u64);

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "kind")]
pub enum NodeKind {
    Block {
        node_type: BlockType,
        attrs: BTreeMap<String, AttrValue>,
        children: Vec<NodeId>,
    },
    Text {
        text: String,
        marks: Vec<Mark>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Node {
    pub id: NodeId,
    pub parent: Option<NodeId>,
    pub kind: NodeKind,
}

#[derive(Debug, Error)]
pub enum DocError {
    #[error("node {0:?} not found")]
    NodeNotFound(NodeId),
    #[error("node {0:?} is not a text node")]
    NotText(NodeId),
    #[error("node {0:?} is not a block node")]
    NotBlock(NodeId),
    #[error("offset {offset} out of bounds for node {node:?} (len {len})")]
    OffsetOutOfBounds { node: NodeId, offset: usize, len: usize },
    #[error("index {index} out of bounds for children of {node:?} (len {len})")]
    ChildIndexOutOfBounds { node: NodeId, index: usize, len: usize },
    #[error("block type {0:?} cannot hold inline (text) children")]
    BlockDisallowsInline(BlockType),
    #[error(transparent)]
    Schema(#[from] crate::content_model::SchemaViolation),
    #[error("cannot merge nodes of different kinds")]
    IncompatibleMerge,
    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),
}

pub type DocResult<T> = Result<T, DocError>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tree {
    nodes: HashMap<NodeId, Node>,
    pub root: NodeId,
    next_id: u64,
}

impl Tree {
    /// Create a new, empty document: a `Doc` root containing a single
    /// empty paragraph (so there's always somewhere to type).
    pub fn new_empty() -> Self {
        let mut tree = Tree {
            nodes: HashMap::new(),
            root: NodeId(0),
            next_id: 0,
        };
        let root_id = tree.alloc_id();
        let para_id = tree.alloc_id();
        let text_id = tree.alloc_id();

        tree.nodes.insert(
            text_id,
            Node { id: text_id, parent: Some(para_id), kind: NodeKind::Text { text: String::new(), marks: vec![] } },
        );
        tree.nodes.insert(
            para_id,
            Node {
                id: para_id,
                parent: Some(root_id),
                kind: NodeKind::Block {
                    node_type: BlockType::Paragraph,
                    attrs: BTreeMap::new(),
                    children: vec![text_id],
                },
            },
        );
        tree.nodes.insert(
            root_id,
            Node {
                id: root_id,
                parent: None,
                kind: NodeKind::Block {
                    node_type: BlockType::Doc,
                    attrs: BTreeMap::new(),
                    children: vec![para_id],
                },
            },
        );
        tree.root = root_id;
        tree
    }

    pub fn alloc_id(&mut self) -> NodeId {
        let id = NodeId(self.next_id);
        self.next_id += 1;
        id
    }

    pub fn get(&self, id: NodeId) -> DocResult<&Node> {
        self.nodes.get(&id).ok_or(DocError::NodeNotFound(id))
    }

    pub fn get_mut(&mut self, id: NodeId) -> DocResult<&mut Node> {
        self.nodes.get_mut(&id).ok_or(DocError::NodeNotFound(id))
    }

    pub fn insert_raw(&mut self, node: Node) {
        self.nodes.insert(node.id, node);
    }

    pub fn remove_raw(&mut self, id: NodeId) -> Option<Node> {
        self.nodes.remove(&id)
    }

    pub fn children_of(&self, id: NodeId) -> DocResult<&[NodeId]> {
        match &self.get(id)?.kind {
            NodeKind::Block { children, .. } => Ok(children),
            NodeKind::Text { .. } => Err(DocError::NotBlock(id)),
        }
    }

    /// Insert `child` as a child of `parent` at `index`, and set its
    /// parent pointer. Does not validate schema rules (callers, i.e.
    /// transaction ops, are expected to do that).
    pub fn splice_child(&mut self, parent: NodeId, index: usize, child: NodeId) -> DocResult<()> {
        {
            let parent_node = self.get_mut(parent)?;
            match &mut parent_node.kind {
                NodeKind::Block { children, .. } => {
                    if index > children.len() {
                        return Err(DocError::ChildIndexOutOfBounds { node: parent, index, len: children.len() });
                    }
                    children.insert(index, child);
                }
                NodeKind::Text { .. } => return Err(DocError::NotBlock(parent)),
            }
        }
        if let Some(child_node) = self.nodes.get_mut(&child) {
            child_node.parent = Some(parent);
        }
        Ok(())
    }

    /// Remove `child` from its parent's children list (parent found via
    /// the child's own `.parent` pointer). Does not delete the node
    /// itself or its subtree — caller decides whether to keep it (e.g.
    /// for undo) or drop it.
    pub fn detach_child(&mut self, child: NodeId) -> DocResult<(NodeId, usize)> {
        let parent = self.get(child)?.parent.ok_or(DocError::NodeNotFound(child))?;
        let index = {
            let parent_node = self.get_mut(parent)?;
            match &mut parent_node.kind {
                NodeKind::Block { children, .. } => {
                    let idx = children.iter().position(|c| *c == child).ok_or(DocError::NodeNotFound(child))?;
                    children.remove(idx);
                    idx
                }
                NodeKind::Text { .. } => return Err(DocError::NotBlock(parent)),
            }
        };
        Ok((parent, index))
    }
}

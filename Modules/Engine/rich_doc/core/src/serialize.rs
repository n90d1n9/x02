//! Wire format for talking to your own backend. Two forms:
//! - `to_json` / `from_json`: full fidelity, includes internal `NodeId`s,
//!   good for save/load and for round-tripping with the agent API.
//! - `to_portable_json`: a plain nested tree *without* internal ids,
//!   for handing to systems that just want content, not editor internals
//!   (e.g. exporting to a CMS, feeding a doc to an LLM as context).

use crate::tree::{DocResult, NodeKind, Tree};
use serde_json::{json, Value};

pub fn to_json(tree: &Tree) -> DocResult<String> {
    Ok(serde_json::to_string(tree)?)
}

pub fn from_json(s: &str) -> DocResult<Tree> {
    Ok(serde_json::from_str(s)?)
}

/// Render a node (recursively) as plain nested JSON with no internal
/// ids — the shape a backend or an LLM context window would want.
pub fn to_portable_json(tree: &Tree, node_id: crate::tree::NodeId) -> DocResult<Value> {
    let node = tree.get(node_id)?;
    Ok(match &node.kind {
        NodeKind::Text { text, marks } => {
            json!({ "text": text, "marks": marks })
        }
        NodeKind::Block { node_type, attrs, children } => {
            let mut child_vals = Vec::with_capacity(children.len());
            for c in children {
                child_vals.push(to_portable_json(tree, *c)?);
            }
            json!({ "type": node_type, "attrs": attrs, "children": child_vals })
        }
    })
}

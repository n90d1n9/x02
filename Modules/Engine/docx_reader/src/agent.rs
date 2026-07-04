//! Agentic AI support.
//!
//! The design goal: an LLM agent should be able to edit a document using
//! the *exact same* vocabulary Flutter uses across FFI — no separate "AI
//! editing API" to keep in sync. This module is a thin, JSON-native,
//! tool-call-friendly wrapper around `commands::Command` (which itself
//! wraps `transaction::Op`), plus a description of the schema you can
//! hand a model as a tool definition (e.g. the `input_schema` of an
//! Anthropic tool, or a function-calling schema for any other provider).

use crate::commands::{apply_commands, Command};
use crate::tree::{DocResult, Tree};
use crate::transaction::{apply_op, OpOutcome};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

/// One agent-issued edit request: a batch of commands applied
/// atomically. If any command in the batch fails, the whole batch is
/// rolled back — an agent never leaves a document half-edited.
#[derive(Debug, Deserialize)]
pub struct AgentCommand {
    pub ops: Vec<Command>,
    /// Optional free-text note from the agent about *why* it made this
    /// edit — not applied to the document, just useful for audit logs /
    /// debugging agent behavior.
    #[serde(default)]
    pub reason: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AgentResult {
    pub ok: bool,
    pub outcome: Option<OpOutcome>,
    pub error: Option<String>,
}

/// Parse and apply a JSON-encoded `AgentCommand` against `tree`.
/// This is the single entry point an agent's "edit_document" tool
/// should call.
pub fn execute_command_json(tree: &mut Tree, command_json: &str) -> AgentResult {
    let command: AgentCommand = match serde_json::from_str(command_json) {
        Ok(c) => c,
        Err(e) => return AgentResult { ok: false, outcome: None, error: Some(format!("invalid command json: {e}")) },
    };
    match apply_commands(tree, &command.ops) {
        Ok(outcome) => AgentResult { ok: true, outcome: Some(outcome), error: None },
        Err(e) => AgentResult { ok: false, outcome: None, error: Some(e.to_string()) },
    }
}

/// A single raw primitive op, applied and returning its own outcome
/// directly (convenience for callers, e.g. the Flutter FFI boundary,
/// that don't need the batch/rollback wrapper and want minimal overhead
/// per keystroke).
pub fn execute_op_json(tree: &mut Tree, op_json: &str) -> DocResult<OpOutcome> {
    let op = serde_json::from_str(op_json)?;
    apply_op(tree, &op)
}

/// Machine-readable description of the editing schema: block types,
/// mark types, and the full `Command` vocabulary (primitives +
/// composites), suitable for use as — or to generate — a tool/function-
/// calling schema for an LLM. Hand this to the agent once at the start
/// of a session instead of hand-writing a duplicate description of what
/// edits are possible.
pub fn describe_schema() -> Value {
    json!({
        "block_types": [
            "doc", "paragraph", "heading", "bullet_list", "ordered_list",
            "list_item", "code_block", "blockquote", "image",
            "horizontal_rule", "table", "table_row", "table_cell",
            "custom (any other string)"
        ],
        "mark_types": ["bold", "italic", "underline", "strike", "code", "link (has href)", "custom (name + attrs)"],
        "content_model_notes": [
            "doc holds top-level blocks only (not list_item/table_row/table_cell).",
            "paragraph/heading/code_block hold inline text only.",
            "bullet_list/ordered_list hold list_item only; list_item may hold text, a paragraph, or a nested list.",
            "table > table_row > table_cell; table_cell holds text or a paragraph.",
            "image/horizontal_rule are leaves and can never have children.",
            "custom block types are unrestricted (extension point for app-specific content)."
        ],
        "primitive_ops": {
            "insert_text": { "node": "NodeId", "offset": "usize", "text": "string" },
            "delete_text": { "node": "NodeId", "start": "usize", "end": "usize" },
            "split_text": { "node": "NodeId", "offset": "usize" },
            "split_block": { "node": "NodeId (a text node)", "offset": "usize — 'press enter' at this point" },
            "merge_blocks": { "first": "NodeId", "second": "NodeId (adjacent sibling)" },
            "add_mark": { "node": "NodeId", "mark": "Mark (applies to the WHOLE node)" },
            "remove_mark": { "node": "NodeId", "mark": "MarkTag" },
            "set_attr": { "node": "NodeId", "key": "string", "value": "AttrValue" },
            "insert_node": { "parent": "NodeId", "index": "usize", "node": "NewNodeSpec — validated against the content model" },
            "delete_node": { "node": "NodeId" }
        },
        "composite_commands": {
            "add_mark_range": { "node": "NodeId", "start": "usize", "end": "usize", "mark": "Mark — handles the split for you" },
            "remove_mark_range": { "node": "NodeId", "start": "usize", "end": "usize", "mark": "MarkTag" }
        },
        "notes": [
            "Send a batch as { \"ops\": [ {\"command\": \"op\", \"payload\": {...primitive Op...}}, {\"command\": \"add_mark_range\", ...} ], \"reason\": \"optional\" } to execute_command_json.",
            "The whole batch is atomic: any failing command rolls the batch back.",
            "Every successful call returns inverse ops in the outcome — store them if you want the agent's edits to be undoable by the user.",
            "insert_node is schema-validated: inserting an invalid child (e.g. a table_row directly under doc) is rejected before the tree is touched."
        ]
    })
}

pub fn portable_snapshot(tree: &Tree) -> DocResult<Value> {
    crate::serialize::to_portable_json(tree, tree.root)
}

//! Composite commands.
//!
//! `transaction::Op` is deliberately a small, stable, orthogonal set of
//! primitives — that's what makes it safe to treat as a long-term wire
//! format. But some everyday editing actions ("bold this selection")
//! naturally expand to *several* primitives whose exact node ids aren't
//! known until the first ones are applied (splitting text creates new
//! nodes).
//!
//! `Command` is where those conveniences live. Each variant expands to
//! a sequence of `Op`s at apply-time and is executed through the exact
//! same `apply_op` path as everything else, so it inherits undo/redo,
//! rollback-on-failure, and JSON transport for free. Adding a new
//! composite command never requires touching `transaction.rs` or
//! breaking compatibility with anything that only speaks raw `Op`s.

use crate::schema::{Mark, MarkTag};
use crate::transaction::{apply_op, Op, OpOutcome};
use crate::tree::{DocError, DocResult, NodeId, NodeKind, Tree};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "command", rename_all = "snake_case")]
pub enum Command {
    /// Escape hatch: run a single primitive `Op` through the command
    /// API, so callers can mix raw ops and composites in one batch.
    Op { payload: Op },
    /// Apply `mark` to the character range `[start, end)` within a text
    /// node, splitting the run as needed. This is the one thing the
    /// primitive `Op` set can't do in a single step (marks are
    /// whole-node in the primitive model — see `transaction::Op::AddMark`).
    AddMarkRange { node: NodeId, start: usize, end: usize, mark: Mark },
    RemoveMarkRange { node: NodeId, start: usize, end: usize, mark: MarkTag },
}

pub fn apply_command(tree: &mut Tree, cmd: &Command) -> DocResult<OpOutcome> {
    match cmd {
        Command::Op { payload } => apply_op(tree, payload),
        Command::AddMarkRange { node, start, end, mark } => mark_range(tree, *node, *start, *end, MarkOp::Add(mark.clone())),
        Command::RemoveMarkRange { node, start, end, mark } => mark_range(tree, *node, *start, *end, MarkOp::Remove(mark.clone())),
    }
}

/// Apply a batch of commands atomically: on the first failure, every
/// command applied so far in this call is rolled back via its inverse.
pub fn apply_commands(tree: &mut Tree, cmds: &[Command]) -> DocResult<OpOutcome> {
    let mut inverses: Vec<Op> = Vec::new();
    let mut created: Vec<NodeId> = Vec::new();
    for cmd in cmds {
        match apply_command(tree, cmd) {
            Ok(mut outcome) => {
                created.append(&mut outcome.created);
                inverses.splice(0..0, outcome.inverse);
            }
            Err(e) => {
                let _ = crate::transaction::apply_transaction(tree, &inverses);
                return Err(e);
            }
        }
    }
    Ok(OpOutcome { inverse: inverses, created })
}

enum MarkOp {
    Add(Mark),
    Remove(MarkTag),
}

fn text_len(tree: &Tree, node: NodeId) -> DocResult<usize> {
    match &tree.get(node)?.kind {
        NodeKind::Text { text, .. } => Ok(text.chars().count()),
        NodeKind::Block { .. } => Err(DocError::NotText(node)),
    }
}

/// Shared implementation for `AddMarkRange` / `RemoveMarkRange`: split
/// the text node so `[start, end)` is its own node, then apply the mark
/// op to just that node. Splitting from the end first keeps `start`
/// stable for the second split.
fn mark_range(tree: &mut Tree, node: NodeId, start: usize, end: usize, op: MarkOp) -> DocResult<OpOutcome> {
    let len = text_len(tree, node)?;
    if start > end || end > len {
        return Err(DocError::OffsetOutOfBounds { node, offset: end, len });
    }
    if start == end {
        return Ok(OpOutcome::default());
    }

    let mut inverse: Vec<Op> = Vec::new();
    let mut created: Vec<NodeId> = Vec::new();
    let mut target = node;

    if end < len {
        let outcome = apply_op(tree, &Op::SplitText { node: target, offset: end })?;
        inverse.splice(0..0, outcome.inverse);
        created.extend(&outcome.created);
        target = outcome.created[0]; // left part: [0, end)
    }
    if start > 0 {
        let outcome = apply_op(tree, &Op::SplitText { node: target, offset: start })?;
        inverse.splice(0..0, outcome.inverse);
        created.extend(&outcome.created);
        target = outcome.created[1]; // right part of that split: [start, end)
    }

    let mark_outcome = match op {
        MarkOp::Add(mark) => apply_op(tree, &Op::AddMark { node: target, mark })?,
        MarkOp::Remove(tag) => apply_op(tree, &Op::RemoveMark { node: target, mark: tag })?,
    };
    inverse.splice(0..0, mark_outcome.inverse);
    if !created.contains(&target) {
        created.push(target);
    }

    Ok(OpOutcome { inverse, created })
}

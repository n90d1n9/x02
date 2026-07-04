// src/core/undo_redo.rs
// Ported from Waraq core undo implementation.

use super::buffer::TextChange;
use super::edit::EditOp;
use super::types::Range;

/// One undoable unit: the original op + its inverse.
#[derive(Debug, Clone)]
pub struct UndoRecord {
    pub op: EditOp,
    pub inverse: EditOp,
    pub group_id: usize,
}

/// Group counter used to batch related edits (e.g. multi-cursor inserts).
#[derive(Debug, Default)]
pub struct UndoGroup {
    next_id: usize,
    open: bool,
}

impl UndoGroup {
    pub fn begin(&mut self) -> usize {
        self.open = true;
        self.next_id
    }
    pub fn end(&mut self) {
        if self.open {
            self.next_id += 1;
            self.open = false;
        }
    }
    pub fn current(&self) -> usize {
        self.next_id
    }
}

/// The full undo/redo stack.
pub struct UndoStack {
    history: Vec<UndoRecord>,
    /// Index past the last applied record (0 = nothing to undo).
    cursor: usize,
    save_point: usize,
    group: UndoGroup,
    max_depth: usize,
}

impl UndoStack {
    pub fn new() -> Self {
        Self {
            history: Vec::new(),
            cursor: 0,
            save_point: 0,
            group: UndoGroup::default(),
            max_depth: 0,
        }
    }

    pub fn with_max_depth(max_depth: usize) -> Self {
        Self {
            max_depth,
            ..Self::new()
        }
    }

    // ── Recording ─────────────────────────────────────────────────────────────

    pub fn begin_group(&mut self) {
        self.group.begin();
    }
    pub fn end_group(&mut self) {
        self.group.end();
    }

    pub fn push(&mut self, op: EditOp, change: TextChange) {
        // Truncate redo branch
        self.history.truncate(self.cursor);

        let inverse = invert_op(&op, &change);
        let group_id = self.group.current();
        self.history.push(UndoRecord {
            op,
            inverse,
            group_id,
        });
        self.cursor = self.history.len();

        if !self.group.open {
            self.group.next_id += 1;
        }

        // Enforce depth limit
        if self.max_depth > 0 && self.history.len() > self.max_depth {
            let drop = self.history.len() - self.max_depth;
            self.history.drain(0..drop);
            self.cursor = self.cursor.saturating_sub(drop);
        }
    }

    // ── Playback ──────────────────────────────────────────────────────────────

    /// Undo the last group. Returns all inverse ops (largest-offset-first for
    /// safe sequential application without re-indexing).
    pub fn undo(&mut self) -> Vec<EditOp> {
        if self.cursor == 0 {
            return vec![];
        }
        self.cursor -= 1;
        let group_id = self.history[self.cursor].group_id;

        let mut ops = vec![self.history[self.cursor].inverse.clone()];
        while self.cursor > 0 && self.history[self.cursor - 1].group_id == group_id {
            self.cursor -= 1;
            ops.push(self.history[self.cursor].inverse.clone());
        }
        ops
    }

    /// Redo the last undone group. Returns all forward ops (oldest→newest).
    pub fn redo(&mut self) -> Vec<EditOp> {
        if self.cursor >= self.history.len() {
            return vec![];
        }
        let group_id = self.history[self.cursor].group_id;

        let mut ops = vec![self.history[self.cursor].op.clone()];
        self.cursor += 1;
        while self.cursor < self.history.len() && self.history[self.cursor].group_id == group_id {
            ops.push(self.history[self.cursor].op.clone());
            self.cursor += 1;
        }
        ops
    }

    // ── Predicates ────────────────────────────────────────────────────────────

    pub fn can_undo(&self) -> bool {
        self.cursor > 0
    }
    pub fn can_redo(&self) -> bool {
        self.cursor < self.history.len()
    }
    pub fn depth(&self) -> usize {
        self.cursor
    }

    /// Mark the current position as the save point (file was just saved).
    pub fn mark_save_point(&mut self) {
        self.save_point = self.cursor;
    }

    /// Returns true if the current position differs from the save point.
    pub fn is_at_saved_point(&self) -> bool {
        self.cursor == self.save_point
    }

    pub fn group_count(&self) -> usize {
        if self.history.is_empty() {
            return 0;
        }
        let mut last = self.history[0].group_id;
        let mut count = 1;
        for r in &self.history[1..] {
            if r.group_id != last {
                count += 1;
                last = r.group_id;
            }
        }
        count
    }
}

impl Default for UndoStack {
    fn default() -> Self {
        Self::new()
    }
}

// ── Inversion ─────────────────────────────────────────────────────────────────

/// Compute the inverse of an applied edit, using `TextChange.deleted` for
/// the original text.
fn invert_op(op: &EditOp, change: &TextChange) -> EditOp {
    match op {
        EditOp::Insert { at, text } => {
            // Inverse of insert(at, text) is delete(at, at + len)
            EditOp::Delete {
                range: Range::new(*at, *at + text.len()),
            }
        }
        EditOp::Delete { range } => {
            // Inverse of delete is re-insert the deleted bytes
            EditOp::Insert {
                at: range.start,
                text: change.deleted.clone(),
            }
        }
        EditOp::Replace { range, text } => {
            // After the replace, the new text occupies [range.start, range.start + text.len()).
            // To undo: replace that span with the original deleted text.
            EditOp::Replace {
                range: Range::new(range.start, range.start + text.len()),
                text: change.deleted.clone(),
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::buffer::TextBuffer;

    fn mk_change(text: &str) -> TextChange {
        TextChange {
            replaced: crate::types::Range::new(0, 0),
            inserted: text.to_owned(),
            deleted: String::new(),
            byte_delta: text.len() as i64,
            first_line: 0,
            last_line: 0,
        }
    }

    fn mk_delete_change(deleted: &str) -> TextChange {
        TextChange {
            replaced: crate::types::Range::new(0, deleted.len()),
            inserted: String::new(),
            deleted: deleted.to_owned(),
            byte_delta: -(deleted.len() as i64),
            first_line: 0,
            last_line: 0,
        }
    }

    #[test]
    fn test_undo_single_edit() {
        let mut stack = UndoStack::new();
        stack.push(EditOp::insert(0, "hello"), mk_change("hello"));
        assert!(stack.can_undo());
        assert!(!stack.can_redo());
        let ops = stack.undo();
        assert_eq!(ops.len(), 1);
        assert!(!stack.can_undo());
        assert!(stack.can_redo());
    }

    #[test]
    fn test_redo_single_edit() {
        let mut stack = UndoStack::new();
        stack.push(EditOp::insert(0, "hello"), mk_change("hello"));
        stack.undo();
        let ops = stack.redo();
        assert_eq!(ops.len(), 1);
        assert!(stack.can_undo());
        assert!(!stack.can_redo());
    }

    #[test]
    fn test_undo_group_returns_all_ops() {
        let mut stack = UndoStack::new();
        stack.begin_group();
        stack.push(EditOp::insert(0, "a"), mk_change("a"));
        stack.push(EditOp::insert(1, "b"), mk_change("b"));
        stack.push(EditOp::insert(2, "c"), mk_change("c"));
        stack.end_group();
        assert_eq!(stack.depth(), 3);
        let ops = stack.undo();
        assert_eq!(
            ops.len(),
            3,
            "group undo must return all {} ops, got {}",
            3,
            ops.len()
        );
        assert_eq!(stack.depth(), 0);
    }

    #[test]
    fn test_redo_group_returns_all_ops() {
        let mut stack = UndoStack::new();
        stack.begin_group();
        stack.push(EditOp::insert(0, "x"), mk_change("x"));
        stack.push(EditOp::insert(1, "y"), mk_change("y"));
        stack.end_group();
        stack.undo();
        let ops = stack.redo();
        assert_eq!(ops.len(), 2, "group redo must return all ops");
    }

    #[test]
    fn test_undo_group_ops_are_inverses() {
        let mut stack = UndoStack::new();
        stack.push(EditOp::insert(0, "hello"), mk_change("hello"));
        let ops = stack.undo();
        match &ops[0] {
            EditOp::Delete { range } => {
                assert_eq!(range.start, 0);
                assert_eq!(range.end, 5);
            }
            _ => panic!("Expected Delete"),
        }
    }

    #[test]
    fn test_undo_delete_is_insert() {
        let mut stack = UndoStack::new();
        stack.push(EditOp::delete(0, 5), mk_delete_change("hello"));
        let ops = stack.undo();
        match &ops[0] {
            EditOp::Insert { at, text } => {
                assert_eq!(*at, 0);
                assert_eq!(text, "hello");
            }
            _ => panic!("Expected Insert"),
        }
    }

    #[test]
    fn test_redo_cleared_after_new_push() {
        let mut stack = UndoStack::new();
        stack.push(EditOp::insert(0, "a"), mk_change("a"));
        stack.push(EditOp::insert(1, "b"), mk_change("b"));
        stack.undo();
        assert!(stack.can_redo());
        // New edit clears redo branch
        stack.push(EditOp::insert(1, "c"), mk_change("c"));
        assert!(!stack.can_redo());
    }

    #[test]
    fn test_standalone_pushes_are_separate_groups() {
        let mut stack = UndoStack::new();
        stack.push(EditOp::insert(0, "a"), mk_change("a"));
        stack.push(EditOp::insert(1, "b"), mk_change("b"));
        let ops1 = stack.undo();
        assert_eq!(ops1.len(), 1);
        assert!(stack.can_undo());
        let ops2 = stack.undo();
        assert_eq!(ops2.len(), 1);
        assert!(!stack.can_undo());
    }

    #[test]
    fn test_two_separate_groups_undo_independently() {
        let mut stack = UndoStack::new();
        stack.begin_group();
        stack.push(EditOp::insert(0, "a"), mk_change("a"));
        stack.push(EditOp::insert(1, "b"), mk_change("b"));
        stack.end_group();
        stack.begin_group();
        stack.push(EditOp::insert(2, "c"), mk_change("c"));
        stack.end_group();
        // Undo second group (just "c")
        let ops1 = stack.undo();
        assert_eq!(ops1.len(), 1);
        // Undo first group ("a" and "b")
        let ops2 = stack.undo();
        assert_eq!(ops2.len(), 2);
        assert!(!stack.can_undo());
    }

    #[test]
    fn test_max_depth_drops_oldest() {
        let mut stack = UndoStack::with_max_depth(3);
        for i in 0..5 {
            stack.push(EditOp::insert(i, "x"), mk_change("x"));
        }
        assert!(stack.depth() <= 3);
    }

    #[test]
    fn test_empty_undo_returns_empty_vec() {
        let mut stack = UndoStack::new();
        let ops = stack.undo();
        assert!(ops.is_empty());
    }

    #[test]
    fn test_group_count() {
        let mut stack = UndoStack::new();
        stack.begin_group();
        stack.push(EditOp::insert(0, "a"), mk_change("a"));
        stack.push(EditOp::insert(1, "b"), mk_change("b"));
        stack.end_group();
        stack.push(EditOp::insert(2, "c"), mk_change("c"));
        assert_eq!(stack.group_count(), 2);
    }

    #[test]
    fn test_undo_redo_round_trip_with_text_buffer() {
        let mut buffer = TextBuffer::from_text("hello");
        let mut stack = UndoStack::new();
        let op = EditOp::insert(5, " office");
        let change = buffer.apply(op.clone()).unwrap();
        stack.push(op, change);

        assert_eq!(buffer.as_str(), "hello office");

        for undo_op in stack.undo() {
            buffer.apply(undo_op).unwrap();
        }
        assert_eq!(buffer.as_str(), "hello");

        for redo_op in stack.redo() {
            buffer.apply(redo_op).unwrap();
        }
        assert_eq!(buffer.as_str(), "hello office");
    }
}

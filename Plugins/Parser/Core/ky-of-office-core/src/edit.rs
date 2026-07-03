// src/edit.rs
// Minimal EditOp definition for core crate
use crate::types::Range;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum EditOp {
    Insert { at: usize, text: String },
    Delete { range: Range },
    Replace { range: Range, text: String },
}

impl EditOp {
    pub fn insert(at: usize, text: &str) -> Self {
        EditOp::Insert {
            at,
            text: text.to_string(),
        }
    }
    pub fn delete(start: usize, end: usize) -> Self {
        EditOp::Delete {
            range: Range::new(start, end),
        }
    }
    pub fn replace(start: usize, end: usize, text: &str) -> Self {
        EditOp::Replace {
            range: Range::new(start, end),
            text: text.to_string(),
        }
    }
}

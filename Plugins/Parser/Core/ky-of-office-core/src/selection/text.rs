use crate::Range;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SelectionDirection {
    Forward,
    Backward,
    Collapsed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct TextSelection {
    pub anchor: usize,
    pub focus: usize,
}

impl TextSelection {
    pub fn new(anchor: usize, focus: usize) -> Self {
        Self { anchor, focus }
    }

    pub fn caret(offset: usize) -> Self {
        Self::new(offset, offset)
    }

    pub fn range(self) -> Range {
        Range::new(self.anchor, self.focus).normalized()
    }

    pub fn is_collapsed(self) -> bool {
        self.anchor == self.focus
    }

    pub fn direction(self) -> SelectionDirection {
        match self.anchor.cmp(&self.focus) {
            std::cmp::Ordering::Less => SelectionDirection::Forward,
            std::cmp::Ordering::Greater => SelectionDirection::Backward,
            std::cmp::Ordering::Equal => SelectionDirection::Collapsed,
        }
    }

    pub fn len(self) -> usize {
        self.range().len()
    }
}

use crate::Presentation;
use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct UndoRedoManager {
    undo_stack: Vec<Presentation>,
    redo_stack: Vec<Presentation>,
}

impl UndoRedoManager {
    pub fn new() -> Self {
        Self::default()
    }

    /// Save a snapshot before making a change
    pub fn push_snapshot(&mut self, presentation: &Presentation) {
        self.undo_stack.push(presentation.clone());
        self.redo_stack.clear(); // Clear redo stack on new action
    }

    /// Undo the last action, restoring the previous snapshot
    /// Returns the restored presentation state if undo was successful
    pub fn undo(&mut self, current: &Presentation) -> Option<Presentation> {
        if let Some(previous) = self.undo_stack.pop() {
            self.redo_stack.push(current.clone());
            Some(previous)
        } else {
            None
        }
    }

    /// Redo the last undone action
    pub fn redo(&mut self, current: &Presentation) -> Option<Presentation> {
        if let Some(next) = self.redo_stack.pop() {
            self.undo_stack.push(current.clone());
            Some(next)
        } else {
            None
        }
    }
}

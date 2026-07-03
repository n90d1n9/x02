//! Selection accessors and selection-change event handling.

use super::super::OfficeSessionEventKind;
use super::OfficeDocumentSession;
use crate::OfficeSelection;

impl<State, Edit> OfficeDocumentSession<State, Edit> {
    pub fn selection(&self) -> &OfficeSelection {
        &self.selection
    }

    pub fn set_selection(&mut self, selection: OfficeSelection) {
        self.set_selection_at(selection, self.last_timestamp_ms);
    }

    pub fn set_selection_at(&mut self, selection: OfficeSelection, timestamp_ms: u64) {
        if self.selection == selection {
            return;
        }

        self.selection = selection;
        self.record_event(OfficeSessionEventKind::SelectionChanged, timestamp_ms);
    }

    pub fn with_selection(mut self, selection: OfficeSelection) -> Self {
        self.selection = selection;
        self
    }

    pub fn clear_selection(&mut self) {
        self.set_selection(OfficeSelection::None);
    }
}

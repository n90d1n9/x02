use super::{GridSelection, ObjectSelection, PageSelection, TextSelection};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum OfficeSelection {
    None,
    Text(TextSelection),
    Grid(GridSelection),
    Objects(ObjectSelection),
    Pages(PageSelection),
}

impl OfficeSelection {
    pub fn is_none(&self) -> bool {
        matches!(self, OfficeSelection::None)
    }

    pub fn is_empty(&self) -> bool {
        match self {
            OfficeSelection::None => true,
            OfficeSelection::Text(selection) => selection.is_collapsed(),
            OfficeSelection::Grid(selection) => selection.ranges.is_empty(),
            OfficeSelection::Objects(selection) => selection.is_empty(),
            OfficeSelection::Pages(selection) => selection.is_empty(),
        }
    }
}

impl Default for OfficeSelection {
    fn default() -> Self {
        Self::None
    }
}

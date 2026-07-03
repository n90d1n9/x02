use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PageSelection {
    pub active: usize,
    pub page_indices: Vec<usize>,
}

impl PageSelection {
    pub fn single(active: usize) -> Self {
        Self {
            active,
            page_indices: vec![active],
        }
    }

    pub fn new(active: usize, page_indices: Vec<usize>) -> Self {
        let mut selection = Self {
            active,
            page_indices: Vec::new(),
        };

        if page_indices.is_empty() {
            selection.page_indices.push(active);
            return selection;
        }

        for page_index in page_indices {
            selection.add(page_index);
        }
        selection
    }

    pub fn add(&mut self, page_index: usize) {
        if !self.page_indices.contains(&page_index) {
            self.page_indices.push(page_index);
            self.page_indices.sort_unstable();
        }
        self.active = page_index;
    }

    pub fn contains(&self, page_index: usize) -> bool {
        self.page_indices.contains(&page_index)
    }

    pub fn len(&self) -> usize {
        self.page_indices.len()
    }

    pub fn is_empty(&self) -> bool {
        self.page_indices.is_empty()
    }
}

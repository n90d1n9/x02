use crate::ObjectId;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ObjectSelection {
    pub primary: Option<ObjectId>,
    pub object_ids: Vec<ObjectId>,
}

impl ObjectSelection {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn single(object_id: impl Into<ObjectId>) -> Self {
        let object_id = object_id.into();
        Self {
            primary: Some(object_id.clone()),
            object_ids: vec![object_id],
        }
    }

    pub fn from_ids(primary: Option<ObjectId>, object_ids: Vec<ObjectId>) -> Self {
        let mut selection = Self::new();
        for object_id in object_ids {
            selection.add(object_id);
        }
        selection.primary = primary.or_else(|| selection.object_ids.first().cloned());
        selection
    }

    pub fn add(&mut self, object_id: impl Into<ObjectId>) {
        let object_id = object_id.into();
        if self.object_ids.contains(&object_id) {
            return;
        }

        if self.primary.is_none() {
            self.primary = Some(object_id.clone());
        }
        self.object_ids.push(object_id);
    }

    pub fn remove(&mut self, object_id: &ObjectId) -> bool {
        let original_len = self.object_ids.len();
        self.object_ids
            .retain(|selected_id| selected_id != object_id);
        let removed = self.object_ids.len() != original_len;

        if self.primary.as_ref() == Some(object_id) {
            self.primary = self.object_ids.first().cloned();
        }

        removed
    }

    pub fn contains(&self, object_id: &ObjectId) -> bool {
        self.object_ids.contains(object_id)
    }

    pub fn len(&self) -> usize {
        self.object_ids.len()
    }

    pub fn is_empty(&self) -> bool {
        self.object_ids.is_empty()
    }
}

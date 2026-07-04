use super::{OfficeSessionEvent, OfficeSessionEventKind};
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// Groups session events into product-facing channels for observers and UI surfaces.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeSessionEventCategory {
    Edit,
    History,
    Collaboration,
    Persistence,
    Recovery,
    Maintenance,
    Selection,
}

impl OfficeSessionEventKind {
    pub fn category(&self) -> OfficeSessionEventCategory {
        match self {
            OfficeSessionEventKind::OperationApplied { .. } => OfficeSessionEventCategory::Edit,
            OfficeSessionEventKind::TransactionCommitted { .. }
            | OfficeSessionEventKind::UndoApplied { .. }
            | OfficeSessionEventKind::RedoApplied { .. } => OfficeSessionEventCategory::History,
            OfficeSessionEventKind::RemoteBatchApplied { .. } => {
                OfficeSessionEventCategory::Collaboration
            }
            OfficeSessionEventKind::CheckpointSaved { .. }
            | OfficeSessionEventKind::DocumentSaved { .. }
            | OfficeSessionEventKind::SaveSkipped { .. } => OfficeSessionEventCategory::Persistence,
            OfficeSessionEventKind::RecoveryCompleted { .. } => {
                OfficeSessionEventCategory::Recovery
            }
            OfficeSessionEventKind::CompactionCompleted { .. }
            | OfficeSessionEventKind::OperationLogPruned { .. } => {
                OfficeSessionEventCategory::Maintenance
            }
            OfficeSessionEventKind::SelectionChanged => OfficeSessionEventCategory::Selection,
        }
    }
}

impl OfficeSessionEvent {
    pub fn category(&self) -> OfficeSessionEventCategory {
        self.kind.category()
    }
}

/// Describes which queued session events should be read or drained by a consumer.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionEventFilter {
    #[serde(default, skip_serializing_if = "BTreeSet::is_empty")]
    categories: BTreeSet<OfficeSessionEventCategory>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    min_event_index: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    min_sequence: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    min_timestamp_ms: Option<u64>,
}

impl Default for OfficeSessionEventFilter {
    fn default() -> Self {
        Self::all()
    }
}

impl OfficeSessionEventFilter {
    pub fn all() -> Self {
        Self {
            categories: BTreeSet::new(),
            min_event_index: None,
            min_sequence: None,
            min_timestamp_ms: None,
        }
    }

    pub fn category(category: OfficeSessionEventCategory) -> Self {
        Self::all().with_category(category)
    }

    pub fn categories(categories: impl IntoIterator<Item = OfficeSessionEventCategory>) -> Self {
        Self::all().with_categories(categories)
    }

    pub fn with_category(mut self, category: OfficeSessionEventCategory) -> Self {
        self.categories.insert(category);
        self
    }

    pub fn with_categories(
        mut self,
        categories: impl IntoIterator<Item = OfficeSessionEventCategory>,
    ) -> Self {
        self.categories.extend(categories);
        self
    }

    pub fn with_min_sequence(mut self, min_sequence: u64) -> Self {
        self.min_sequence = Some(min_sequence);
        self
    }

    pub fn with_min_event_index(mut self, min_event_index: u64) -> Self {
        self.min_event_index = Some(min_event_index);
        self
    }

    pub fn with_min_timestamp_ms(mut self, min_timestamp_ms: u64) -> Self {
        self.min_timestamp_ms = Some(min_timestamp_ms);
        self
    }

    pub fn categories_set(&self) -> &BTreeSet<OfficeSessionEventCategory> {
        &self.categories
    }

    pub fn min_sequence(&self) -> Option<u64> {
        self.min_sequence
    }

    pub fn min_event_index(&self) -> Option<u64> {
        self.min_event_index
    }

    pub fn min_timestamp_ms(&self) -> Option<u64> {
        self.min_timestamp_ms
    }

    pub fn matches(&self, event: &OfficeSessionEvent) -> bool {
        if !self.categories.is_empty() && !self.categories.contains(&event.category()) {
            return false;
        }

        if let Some(min_event_index) = self.min_event_index {
            if event.event_index < min_event_index {
                return false;
            }
        }

        if let Some(min_sequence) = self.min_sequence {
            if event.sequence < min_sequence {
                return false;
            }
        }

        if let Some(min_timestamp_ms) = self.min_timestamp_ms {
            if event.timestamp_ms < min_timestamp_ms {
                return false;
            }
        }

        true
    }
}

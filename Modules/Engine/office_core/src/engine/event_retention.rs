use crate::DocumentId;
use serde::{Deserialize, Serialize};

/// Configures how many queued session events should remain available to observers.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionEventRetentionPolicy {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    max_retained_events: Option<usize>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    prune_through_event_index: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    prune_before_timestamp_ms: Option<u64>,
}

impl OfficeSessionEventRetentionPolicy {
    pub fn unbounded() -> Self {
        Self::default()
    }

    pub fn max_events(max_retained_events: usize) -> Self {
        Self::unbounded().with_max_retained_events(max_retained_events)
    }

    pub fn with_max_retained_events(mut self, max_retained_events: usize) -> Self {
        self.max_retained_events = Some(max_retained_events);
        self
    }

    pub fn with_prune_through_event_index(mut self, event_index: u64) -> Self {
        self.prune_through_event_index = Some(event_index);
        self
    }

    pub fn with_prune_before_timestamp_ms(mut self, timestamp_ms: u64) -> Self {
        self.prune_before_timestamp_ms = Some(timestamp_ms);
        self
    }

    pub fn max_retained_events(&self) -> Option<usize> {
        self.max_retained_events
    }

    pub fn prune_through_event_index(&self) -> Option<u64> {
        self.prune_through_event_index
    }

    pub fn prune_before_timestamp_ms(&self) -> Option<u64> {
        self.prune_before_timestamp_ms
    }
}

/// Summarizes the effect of applying an event retention policy to a session queue.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionEventPruneReport {
    pub document_id: DocumentId,
    pub requested_policy: OfficeSessionEventRetentionPolicy,
    pub pruned_through_event_index: u64,
    pub last_event_index: u64,
    pub original_event_count: usize,
    pub retained_event_count: usize,
    pub pruned_event_count: usize,
    pub retained_event_range: Option<(u64, u64)>,
}

impl OfficeSessionEventPruneReport {
    pub fn pruned_events(&self) -> bool {
        self.pruned_event_count > 0
    }
}

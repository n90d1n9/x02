//! Event queue access, filtering, pruning, and recording for document sessions.

use super::super::{
    OfficeSessionEvent, OfficeSessionEventBatch, OfficeSessionEventCursor, OfficeSessionEventError,
    OfficeSessionEventFilter, OfficeSessionEventKind, OfficeSessionEventPruneReport,
    OfficeSessionEventRetentionPolicy,
};
use super::OfficeDocumentSession;

impl<State, Edit> OfficeDocumentSession<State, Edit> {
    pub fn events(&self) -> &[OfficeSessionEvent] {
        &self.events
    }

    pub fn event_cursor(&self) -> OfficeSessionEventCursor {
        OfficeSessionEventCursor::new(self.last_event_index)
    }

    pub fn event_pruned_through_index(&self) -> u64 {
        self.event_pruned_through_index
    }

    pub fn events_matching(&self, filter: &OfficeSessionEventFilter) -> Vec<&OfficeSessionEvent> {
        self.events
            .iter()
            .filter(|event| filter.matches(event))
            .collect()
    }

    pub fn events_after(
        &self,
        cursor: OfficeSessionEventCursor,
        filter: &OfficeSessionEventFilter,
    ) -> Vec<&OfficeSessionEvent> {
        self.events
            .iter()
            .filter(|event| event.event_index > cursor.event_index && filter.matches(event))
            .collect()
    }

    pub fn try_events_after(
        &self,
        cursor: OfficeSessionEventCursor,
        filter: &OfficeSessionEventFilter,
    ) -> Result<Vec<&OfficeSessionEvent>, OfficeSessionEventError> {
        self.validate_event_cursor(cursor)?;
        Ok(self.events_after(cursor, filter))
    }

    pub fn event_batch_after(
        &self,
        cursor: OfficeSessionEventCursor,
        filter: &OfficeSessionEventFilter,
    ) -> OfficeSessionEventBatch {
        let next_cursor = cursor.max(self.event_cursor());
        let events = self
            .events_after(cursor, filter)
            .into_iter()
            .cloned()
            .collect();

        OfficeSessionEventBatch::new(cursor, next_cursor, events)
    }

    pub fn try_event_batch_after(
        &self,
        cursor: OfficeSessionEventCursor,
        filter: &OfficeSessionEventFilter,
    ) -> Result<OfficeSessionEventBatch, OfficeSessionEventError> {
        self.validate_event_cursor(cursor)?;
        Ok(self.event_batch_after(cursor, filter))
    }

    pub fn prune_events(
        &mut self,
        policy: &OfficeSessionEventRetentionPolicy,
    ) -> OfficeSessionEventPruneReport {
        let original_event_count = self.events.len();
        let prune_through_event_index = self.requested_event_prune_through_index(policy);

        self.events
            .retain(|event| event.event_index > prune_through_event_index);
        self.event_pruned_through_index = self
            .event_pruned_through_index
            .max(prune_through_event_index);

        let retained_event_count = self.events.len();
        let retained_event_range = self
            .events
            .first()
            .zip(self.events.last())
            .map(|(first, last)| (first.event_index, last.event_index));

        OfficeSessionEventPruneReport {
            document_id: self.document_id.clone(),
            requested_policy: policy.clone(),
            pruned_through_event_index: self.event_pruned_through_index,
            last_event_index: self.last_event_index,
            original_event_count,
            retained_event_count,
            pruned_event_count: original_event_count.saturating_sub(retained_event_count),
            retained_event_range,
        }
    }

    pub fn drain_events(&mut self) -> Vec<OfficeSessionEvent> {
        let events = std::mem::take(&mut self.events);
        if let Some(last_event) = events.last() {
            self.event_pruned_through_index =
                self.event_pruned_through_index.max(last_event.event_index);
        }
        events
    }

    pub fn drain_events_matching(
        &mut self,
        filter: &OfficeSessionEventFilter,
    ) -> Vec<OfficeSessionEvent> {
        let mut drained_events = Vec::new();
        let mut retained_events = Vec::new();

        for event in std::mem::take(&mut self.events) {
            if filter.matches(&event) {
                drained_events.push(event);
            } else {
                retained_events.push(event);
            }
        }

        self.events = retained_events;
        drained_events
    }

    pub fn clear_events(&mut self) {
        if let Some(last_event) = self.events.last() {
            self.event_pruned_through_index =
                self.event_pruned_through_index.max(last_event.event_index);
        }
        self.events.clear();
    }

    pub(crate) fn record_event(&mut self, kind: OfficeSessionEventKind, timestamp_ms: u64) {
        self.last_event_index = self.last_event_index.saturating_add(1);
        self.events.push(
            OfficeSessionEvent::new(
                self.engine.clone(),
                self.document_id.clone(),
                self.sequence,
                timestamp_ms,
                kind,
            )
            .with_event_index(self.last_event_index),
        );
    }

    fn requested_event_prune_through_index(
        &self,
        policy: &OfficeSessionEventRetentionPolicy,
    ) -> u64 {
        let mut prune_through_event_index = self.event_pruned_through_index;

        if let Some(event_index) = policy.prune_through_event_index() {
            prune_through_event_index = prune_through_event_index.max(event_index);
        }

        if let Some(timestamp_ms) = policy.prune_before_timestamp_ms() {
            if let Some(event_index) = self
                .events
                .iter()
                .take_while(|event| event.timestamp_ms < timestamp_ms)
                .map(|event| event.event_index)
                .last()
            {
                prune_through_event_index = prune_through_event_index.max(event_index);
            }
        }

        if let Some(max_retained_events) = policy.max_retained_events() {
            if max_retained_events == 0 {
                if let Some(event) = self.events.last() {
                    prune_through_event_index = prune_through_event_index.max(event.event_index);
                }
            } else if self.events.len() > max_retained_events {
                let prune_count = self.events.len() - max_retained_events;
                prune_through_event_index =
                    prune_through_event_index.max(self.events[prune_count - 1].event_index);
            }
        }

        prune_through_event_index.min(self.last_event_index)
    }

    fn validate_event_cursor(
        &self,
        cursor: OfficeSessionEventCursor,
    ) -> Result<(), OfficeSessionEventError> {
        if cursor.event_index < self.event_pruned_through_index {
            return Err(OfficeSessionEventError::CursorCompacted {
                requested_event_index: cursor.event_index,
                available_after_event_index: self.event_pruned_through_index,
            });
        }

        Ok(())
    }
}

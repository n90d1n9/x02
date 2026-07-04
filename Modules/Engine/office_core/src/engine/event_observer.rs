use super::session::OfficeDocumentSession;
use super::{
    OfficeSessionEventBatch, OfficeSessionEventCategory, OfficeSessionEventCursor,
    OfficeSessionEventError, OfficeSessionEventFilter,
};
use serde::{Deserialize, Serialize};

/// Stores reusable observer state for a product surface that polls session events.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionEventObserver {
    cursor: OfficeSessionEventCursor,
    filter: OfficeSessionEventFilter,
}

impl Default for OfficeSessionEventObserver {
    fn default() -> Self {
        Self::all()
    }
}

impl OfficeSessionEventObserver {
    pub fn all() -> Self {
        Self::new(OfficeSessionEventFilter::all())
    }

    pub fn category(category: OfficeSessionEventCategory) -> Self {
        Self::new(OfficeSessionEventFilter::category(category))
    }

    pub fn categories(categories: impl IntoIterator<Item = OfficeSessionEventCategory>) -> Self {
        Self::new(OfficeSessionEventFilter::categories(categories))
    }

    pub fn new(filter: OfficeSessionEventFilter) -> Self {
        Self {
            cursor: OfficeSessionEventCursor::start(),
            filter,
        }
    }

    pub fn with_cursor(mut self, cursor: OfficeSessionEventCursor) -> Self {
        self.cursor = cursor;
        self
    }

    pub fn cursor(&self) -> OfficeSessionEventCursor {
        self.cursor
    }

    pub fn filter(&self) -> &OfficeSessionEventFilter {
        &self.filter
    }

    pub fn reset_cursor(&mut self, cursor: OfficeSessionEventCursor) {
        self.cursor = cursor;
    }

    pub fn poll<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
    ) -> Result<OfficeSessionEventBatch, OfficeSessionEventError> {
        let batch = session.try_event_batch_after(self.cursor, &self.filter)?;
        self.cursor = batch.next_cursor;
        Ok(batch)
    }

    pub fn poll_resyncing<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
    ) -> Result<OfficeSessionEventObserverUpdate, OfficeSessionEventError> {
        match self.poll(session) {
            Ok(batch) => Ok(OfficeSessionEventObserverUpdate::new(batch, None)),
            Err(OfficeSessionEventError::CursorCompacted {
                available_after_event_index,
                ..
            }) => {
                let reset_cursor = OfficeSessionEventCursor::new(available_after_event_index);
                self.cursor = reset_cursor;
                let batch = self.poll(session)?;

                Ok(OfficeSessionEventObserverUpdate::new(
                    batch,
                    Some(reset_cursor),
                ))
            }
        }
    }
}

/// Describes the result of polling an event observer, including automatic cursor recovery.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSessionEventObserverUpdate {
    pub batch: OfficeSessionEventBatch,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reset_cursor: Option<OfficeSessionEventCursor>,
}

impl OfficeSessionEventObserverUpdate {
    pub fn new(
        batch: OfficeSessionEventBatch,
        reset_cursor: Option<OfficeSessionEventCursor>,
    ) -> Self {
        Self {
            batch,
            reset_cursor,
        }
    }

    pub fn cursor_was_reset(&self) -> bool {
        self.reset_cursor.is_some()
    }
}

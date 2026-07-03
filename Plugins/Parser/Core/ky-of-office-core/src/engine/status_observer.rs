use super::session::OfficeDocumentSession;
use super::{
    OfficeSessionCommand, OfficeSessionCommandState, OfficeSessionDiagnostics,
    OfficeSessionDiagnosticsPolicy, OfficeSessionDiagnosticsSignal, OfficeSessionEventCategory,
    OfficeSessionEventCursor, OfficeSessionEventError, OfficeSessionEventFilter,
    OfficeSessionEventObserver, OfficeSessionEventObserverUpdate,
};
use serde::{Deserialize, Serialize};

/// Captures session diagnostics, health, and command readiness for product status surfaces.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionStatusSnapshot {
    pub diagnostics: OfficeSessionDiagnostics,
    pub signal: OfficeSessionDiagnosticsSignal,
    pub commands: OfficeSessionCommandState,
}

impl OfficeSessionStatusSnapshot {
    pub fn new(
        diagnostics: OfficeSessionDiagnostics,
        signal: OfficeSessionDiagnosticsSignal,
    ) -> Self {
        let commands = OfficeSessionCommandState::from_diagnostics(&diagnostics);

        Self {
            diagnostics,
            signal,
            commands,
        }
    }

    pub fn is_healthy(&self) -> bool {
        self.signal.is_healthy()
    }

    /// Returns whether a core session command is currently available.
    pub fn can(&self, command: OfficeSessionCommand) -> bool {
        self.commands.can(command)
    }
}

/// Stores reusable status observer state for product shells and sidebar surfaces.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionStatusObserver {
    diagnostics_policy: OfficeSessionDiagnosticsPolicy,
    event_observer: OfficeSessionEventObserver,
}

impl Default for OfficeSessionStatusObserver {
    fn default() -> Self {
        Self::all_events()
    }
}

impl OfficeSessionStatusObserver {
    /// Builds a status observer that watches every session event with the default diagnostics policy.
    pub fn all_events() -> Self {
        Self::new(
            OfficeSessionDiagnosticsPolicy::default(),
            OfficeSessionEventObserver::all(),
        )
    }

    /// Builds a status observer scoped to one event category with the default diagnostics policy.
    pub fn category(category: OfficeSessionEventCategory) -> Self {
        Self::new(
            OfficeSessionDiagnosticsPolicy::default(),
            OfficeSessionEventObserver::category(category),
        )
    }

    /// Builds a status observer scoped to multiple event categories with the default diagnostics policy.
    pub fn categories(categories: impl IntoIterator<Item = OfficeSessionEventCategory>) -> Self {
        Self::new(
            OfficeSessionDiagnosticsPolicy::default(),
            OfficeSessionEventObserver::categories(categories),
        )
    }

    /// Builds a status observer from explicit diagnostics and event observer settings.
    pub fn new(
        diagnostics_policy: OfficeSessionDiagnosticsPolicy,
        event_observer: OfficeSessionEventObserver,
    ) -> Self {
        Self {
            diagnostics_policy,
            event_observer,
        }
    }

    /// Builds a status observer from an explicit diagnostics policy and event filter.
    pub fn with_event_filter(
        diagnostics_policy: OfficeSessionDiagnosticsPolicy,
        event_filter: OfficeSessionEventFilter,
    ) -> Self {
        Self::new(
            diagnostics_policy,
            OfficeSessionEventObserver::new(event_filter),
        )
    }

    /// Replaces the diagnostics policy while preserving event observer cursor state.
    pub fn with_diagnostics_policy(
        mut self,
        diagnostics_policy: OfficeSessionDiagnosticsPolicy,
    ) -> Self {
        self.diagnostics_policy = diagnostics_policy;
        self
    }

    /// Returns the diagnostics policy used to evaluate product-facing status signals.
    pub fn diagnostics_policy(&self) -> &OfficeSessionDiagnosticsPolicy {
        &self.diagnostics_policy
    }

    /// Returns the event observer used to poll incremental session events.
    pub fn event_observer(&self) -> &OfficeSessionEventObserver {
        &self.event_observer
    }

    /// Returns the next event cursor that will be used by this observer.
    pub fn event_cursor(&self) -> OfficeSessionEventCursor {
        self.event_observer.cursor()
    }

    /// Resets the observer event cursor for product surfaces that manually resync.
    pub fn reset_event_cursor(&mut self, cursor: OfficeSessionEventCursor) {
        self.event_observer.reset_cursor(cursor);
    }

    /// Captures diagnostics and evaluates them without polling the event queue.
    pub fn snapshot<State, Edit>(
        &self,
        session: &OfficeDocumentSession<State, Edit>,
    ) -> OfficeSessionStatusSnapshot {
        let diagnostics = session.diagnostics();
        let signal = diagnostics.evaluate(&self.diagnostics_policy);

        OfficeSessionStatusSnapshot::new(diagnostics, signal)
    }

    /// Polls diagnostics and events as one reusable status update for product surfaces.
    pub fn poll<State, Edit>(
        &mut self,
        session: &OfficeDocumentSession<State, Edit>,
    ) -> Result<OfficeSessionStatusUpdate, OfficeSessionEventError> {
        let events = self.event_observer.poll_resyncing(session)?;
        let snapshot = self.snapshot(session);

        Ok(OfficeSessionStatusUpdate::new(snapshot, events))
    }
}

/// Describes one product-facing status poll result with diagnostics and event updates.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct OfficeSessionStatusUpdate {
    pub snapshot: OfficeSessionStatusSnapshot,
    pub events: OfficeSessionEventObserverUpdate,
}

impl OfficeSessionStatusUpdate {
    pub fn new(
        snapshot: OfficeSessionStatusSnapshot,
        events: OfficeSessionEventObserverUpdate,
    ) -> Self {
        Self { snapshot, events }
    }

    /// Returns whether polling had to recover from an event cursor compacted by retention.
    pub fn event_cursor_was_reset(&self) -> bool {
        self.events.cursor_was_reset()
    }

    /// Returns whether polling had to recover from an event cursor compacted by retention.
    pub fn cursor_was_reset(&self) -> bool {
        self.event_cursor_was_reset()
    }
}

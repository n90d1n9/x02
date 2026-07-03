use super::session::OfficeDocumentSession;
use super::{
    OfficeSessionCommand, OfficeSessionCommandDelta, OfficeSessionCommandState, OfficeSessionError,
    OfficeSessionEventCursor,
};
use crate::{OfficeSelection, OperationApplier};
use serde::{Deserialize, Serialize};

/// Describes a product request to execute a core session command.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct OfficeSessionCommandRequest {
    pub command: OfficeSessionCommand,
    pub timestamp_ms: u64,
}

impl OfficeSessionCommandRequest {
    /// Builds a command request with the timestamp that should be used for generated events.
    pub fn new(command: OfficeSessionCommand, timestamp_ms: u64) -> Self {
        Self {
            command,
            timestamp_ms,
        }
    }

    /// Builds an undo command request.
    pub fn undo(timestamp_ms: u64) -> Self {
        Self::new(OfficeSessionCommand::Undo, timestamp_ms)
    }

    /// Builds a redo command request.
    pub fn redo(timestamp_ms: u64) -> Self {
        Self::new(OfficeSessionCommand::Redo, timestamp_ms)
    }

    /// Builds a clear-selection command request.
    pub fn clear_selection(timestamp_ms: u64) -> Self {
        Self::new(OfficeSessionCommand::ClearSelection, timestamp_ms)
    }

    /// Builds a save command request for product shells that route persistence externally.
    pub fn save(timestamp_ms: u64) -> Self {
        Self::new(OfficeSessionCommand::Save, timestamp_ms)
    }

    /// Builds a sync command request for product shells that route collaboration externally.
    pub fn sync_pending_changes(timestamp_ms: u64) -> Self {
        Self::new(OfficeSessionCommand::SyncPendingChanges, timestamp_ms)
    }
}

/// Reports the result of executing a core session command.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(bound(
    serialize = "Outcome: Serialize",
    deserialize = "Outcome: Deserialize<'de>"
))]
pub struct OfficeSessionCommandResult<Outcome> {
    pub command: OfficeSessionCommand,
    pub timestamp_ms: u64,
    pub sequence_before: u64,
    pub sequence_after: u64,
    pub event_cursor_before: OfficeSessionEventCursor,
    pub event_cursor_after: OfficeSessionEventCursor,
    pub command_state_before: OfficeSessionCommandState,
    pub command_state_after: OfficeSessionCommandState,
    #[serde(default)]
    pub operation_outcomes: Vec<Outcome>,
}

impl<Outcome> OfficeSessionCommandResult<Outcome> {
    /// Builds a command execution result from before/after session state.
    pub fn new(
        request: OfficeSessionCommandRequest,
        sequence_before: u64,
        sequence_after: u64,
        event_cursor_before: OfficeSessionEventCursor,
        event_cursor_after: OfficeSessionEventCursor,
        command_state_before: OfficeSessionCommandState,
        command_state_after: OfficeSessionCommandState,
        operation_outcomes: Vec<Outcome>,
    ) -> Self {
        Self {
            command: request.command,
            timestamp_ms: request.timestamp_ms,
            sequence_before,
            sequence_after,
            event_cursor_before,
            event_cursor_after,
            command_state_before,
            command_state_after,
            operation_outcomes,
        }
    }

    /// Returns whether the command changed the operation sequence.
    pub fn sequence_changed(&self) -> bool {
        self.sequence_before != self.sequence_after
    }

    /// Returns whether the command emitted session events.
    pub fn emitted_events(&self) -> bool {
        self.event_cursor_before != self.event_cursor_after
    }

    /// Returns the command availability delta caused by this command.
    pub fn command_delta(&self) -> OfficeSessionCommandDelta {
        self.command_state_after
            .diff_from(&self.command_state_before)
    }
}

/// Describes why a core session command could not be executed.
#[derive(Debug, Clone, PartialEq)]
pub enum OfficeSessionCommandExecutionError<Error> {
    Disabled { command: OfficeSessionCommand },
    RequiresExternalHandler { command: OfficeSessionCommand },
    Session(OfficeSessionError<Error>),
}

impl<Error> OfficeSessionCommandExecutionError<Error> {
    /// Builds an error for a command that is currently unavailable.
    pub fn disabled(command: OfficeSessionCommand) -> Self {
        Self::Disabled { command }
    }

    /// Builds an error for a command that must be handled by a product service.
    pub fn requires_external_handler(command: OfficeSessionCommand) -> Self {
        Self::RequiresExternalHandler { command }
    }

    /// Builds an error from a lower-level session failure.
    pub fn session(error: OfficeSessionError<Error>) -> Self {
        Self::Session(error)
    }
}

impl<State, Edit> OfficeDocumentSession<State, Edit>
where
    State: OperationApplier<Edit>,
    Edit: Clone,
{
    /// Executes a core command that can be completed entirely inside the session.
    pub fn execute_command(
        &mut self,
        request: OfficeSessionCommandRequest,
    ) -> Result<
        OfficeSessionCommandResult<State::Outcome>,
        OfficeSessionCommandExecutionError<State::Error>,
    > {
        let command_state_before = OfficeSessionCommandState::from_diagnostics(&self.diagnostics());
        if !command_state_before.can(request.command) {
            return Err(OfficeSessionCommandExecutionError::disabled(
                request.command,
            ));
        }

        let sequence_before = self.sequence();
        let event_cursor_before = self.event_cursor();
        let operation_outcomes = match request.command {
            OfficeSessionCommand::Undo => self
                .undo(request.timestamp_ms)
                .map_err(OfficeSessionCommandExecutionError::session)?,
            OfficeSessionCommand::Redo => self
                .redo(request.timestamp_ms)
                .map_err(OfficeSessionCommandExecutionError::session)?,
            OfficeSessionCommand::ClearSelection => {
                self.set_selection_at(OfficeSelection::None, request.timestamp_ms);
                Vec::new()
            }
            OfficeSessionCommand::Save | OfficeSessionCommand::SyncPendingChanges => {
                return Err(
                    OfficeSessionCommandExecutionError::requires_external_handler(request.command),
                );
            }
        };

        let command_state_after = OfficeSessionCommandState::from_diagnostics(&self.diagnostics());

        Ok(OfficeSessionCommandResult::new(
            request,
            sequence_before,
            self.sequence(),
            event_cursor_before,
            self.event_cursor(),
            command_state_before,
            command_state_after,
            operation_outcomes,
        ))
    }
}

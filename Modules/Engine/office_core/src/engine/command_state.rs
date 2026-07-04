use super::OfficeSessionDiagnostics;
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// Identifies a core session command that product shells can expose in toolbars or menus.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OfficeSessionCommand {
    Save,
    SyncPendingChanges,
    Undo,
    Redo,
    ClearSelection,
}

impl OfficeSessionCommand {
    /// Returns whether this command can be executed directly by an Office session.
    pub fn is_session_executable(self) -> bool {
        matches!(self, Self::Undo | Self::Redo | Self::ClearSelection)
    }

    /// Returns whether this command needs a product service such as persistence or sync.
    pub fn requires_external_handler(self) -> bool {
        matches!(self, Self::Save | Self::SyncPendingChanges)
    }
}

/// Captures which core session commands are currently available for a document.
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct OfficeSessionCommandState {
    #[serde(default)]
    pub enabled: BTreeSet<OfficeSessionCommand>,
}

impl OfficeSessionCommandState {
    /// Derives command availability from a diagnostics snapshot.
    pub fn from_diagnostics(diagnostics: &OfficeSessionDiagnostics) -> Self {
        let mut state = Self::default();

        if diagnostics.is_dirty {
            state.enable(OfficeSessionCommand::Save);
        }

        if diagnostics.pending_operation_count > 0 {
            state.enable(OfficeSessionCommand::SyncPendingChanges);
        }

        if diagnostics.can_undo {
            state.enable(OfficeSessionCommand::Undo);
        }

        if diagnostics.can_redo {
            state.enable(OfficeSessionCommand::Redo);
        }

        if !diagnostics.selection_is_empty {
            state.enable(OfficeSessionCommand::ClearSelection);
        }

        state
    }

    /// Returns the enabled command set in a stable order for serialization and UI adapters.
    pub fn enabled_commands(&self) -> &BTreeSet<OfficeSessionCommand> {
        &self.enabled
    }

    /// Compares this command state against an earlier state.
    pub fn diff_from(&self, previous: &Self) -> OfficeSessionCommandDelta {
        OfficeSessionCommandDelta::between(previous, self)
    }

    /// Returns whether a command can currently run.
    pub fn can(&self, command: OfficeSessionCommand) -> bool {
        self.enabled.contains(&command)
    }

    /// Returns whether a command can currently run.
    pub fn is_enabled(&self, command: OfficeSessionCommand) -> bool {
        self.can(command)
    }

    /// Returns whether no core session commands are currently available.
    pub fn is_empty(&self) -> bool {
        self.enabled.is_empty()
    }

    /// Returns whether the document has unsaved changes.
    pub fn can_save(&self) -> bool {
        self.can(OfficeSessionCommand::Save)
    }

    /// Returns whether the document has pending local changes for synchronization.
    pub fn can_sync_pending_changes(&self) -> bool {
        self.can(OfficeSessionCommand::SyncPendingChanges)
    }

    /// Returns whether undo can currently run.
    pub fn can_undo(&self) -> bool {
        self.can(OfficeSessionCommand::Undo)
    }

    /// Returns whether redo can currently run.
    pub fn can_redo(&self) -> bool {
        self.can(OfficeSessionCommand::Redo)
    }

    /// Returns whether an active selection can be cleared.
    pub fn can_clear_selection(&self) -> bool {
        self.can(OfficeSessionCommand::ClearSelection)
    }

    fn enable(&mut self, command: OfficeSessionCommand) {
        self.enabled.insert(command);
    }
}

/// Describes command availability changes between two status snapshots.
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct OfficeSessionCommandDelta {
    #[serde(default, skip_serializing_if = "BTreeSet::is_empty")]
    pub enabled: BTreeSet<OfficeSessionCommand>,
    #[serde(default, skip_serializing_if = "BTreeSet::is_empty")]
    pub disabled: BTreeSet<OfficeSessionCommand>,
}

impl OfficeSessionCommandDelta {
    /// Compares two command states and reports newly enabled and disabled commands.
    pub fn between(
        previous: &OfficeSessionCommandState,
        current: &OfficeSessionCommandState,
    ) -> Self {
        let enabled = current
            .enabled
            .difference(&previous.enabled)
            .copied()
            .collect();
        let disabled = previous
            .enabled
            .difference(&current.enabled)
            .copied()
            .collect();

        Self { enabled, disabled }
    }

    /// Returns whether no command availability changed.
    pub fn is_empty(&self) -> bool {
        self.enabled.is_empty() && self.disabled.is_empty()
    }

    /// Returns commands that became available.
    pub fn enabled_commands(&self) -> &BTreeSet<OfficeSessionCommand> {
        &self.enabled
    }

    /// Returns commands that became unavailable.
    pub fn disabled_commands(&self) -> &BTreeSet<OfficeSessionCommand> {
        &self.disabled
    }

    /// Returns whether a command became available.
    pub fn was_enabled(&self, command: OfficeSessionCommand) -> bool {
        self.enabled.contains(&command)
    }

    /// Returns whether a command became unavailable.
    pub fn was_disabled(&self, command: OfficeSessionCommand) -> bool {
        self.disabled.contains(&command)
    }
}

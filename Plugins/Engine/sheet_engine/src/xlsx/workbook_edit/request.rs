//! Direct sheet edit request contract.

use serde::{Deserialize, Serialize};
use waraq_core::{ActorId, OperationId};

use crate::SheetEdit;

/// Request for applying a sheet edit through an XLSX workbook session.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XlsxSheetEditRequest {
    sheet_name: Option<String>,
    operation_id: OperationId,
    actor_id: ActorId,
    timestamp_ms: u64,
    edit: SheetEdit,
}

impl XlsxSheetEditRequest {
    /// Create a request targeting the active sheet.
    pub fn new(
        operation_id: impl Into<OperationId>,
        actor_id: impl Into<ActorId>,
        timestamp_ms: u64,
        edit: SheetEdit,
    ) -> Self {
        Self {
            sheet_name: None,
            operation_id: operation_id.into(),
            actor_id: actor_id.into(),
            timestamp_ms,
            edit,
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet edit.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the core operation id to use for this edit.
    pub fn operation_id(&self) -> &OperationId {
        &self.operation_id
    }

    /// Return the actor id to use for this edit.
    pub fn actor_id(&self) -> &ActorId {
        &self.actor_id
    }

    /// Return the edit timestamp.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    /// Return the sheet edit payload.
    pub fn edit(&self) -> &SheetEdit {
        &self.edit
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }
}

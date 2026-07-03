//! Sheet snapshot entry stored inside an XLSX workbook snapshot.

use crate::SheetSnapshot;
use serde::{Deserialize, Serialize};
use waraq_core::DocumentId;

/// Snapshot of a sheet session inside an XLSX workbook runtime.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct XlsxWorkbookSheetSnapshot {
    sheet_name: String,
    snapshot: SheetSnapshot,
}

impl XlsxWorkbookSheetSnapshot {
    /// Create a sheet snapshot entry with the workbook sheet name as source of truth.
    pub fn new(sheet_name: impl Into<String>, snapshot: SheetSnapshot) -> Self {
        let sheet_name = sheet_name.into().trim().to_owned();
        let mut snapshot = snapshot;
        snapshot.state.name = sheet_name.clone();
        Self {
            sheet_name,
            snapshot,
        }
    }

    /// Return the sheet name in workbook order.
    pub fn sheet_name(&self) -> &str {
        &self.sheet_name
    }

    /// Return the core document id stored by the sheet snapshot.
    pub fn document_id(&self) -> &DocumentId {
        &self.snapshot.document_id
    }

    /// Return the embedded core sheet snapshot.
    pub fn snapshot(&self) -> &SheetSnapshot {
        &self.snapshot
    }

    /// Consume the entry and return the embedded core sheet snapshot.
    pub fn into_snapshot(self) -> SheetSnapshot {
        self.snapshot
    }

    pub(super) fn state_sheet_name(&self) -> &str {
        &self.snapshot.state.name
    }
}

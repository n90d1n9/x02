//! Workbook-level status aggregation and query helpers.

use serde::{Deserialize, Serialize};

use crate::XlsxWorkbookSession;

use super::XlsxSheetSessionStatus;

/// Read-only status summary for an XLSX workbook editing session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxWorkbookSessionStatus {
    pub workbook_id: String,
    pub active_sheet_name: String,
    pub sheet_count: usize,
    pub total_cell_count: usize,
    pub dirty_sheet_count: usize,
    pub pending_operation_count: usize,
    pub operation_log_count: usize,
    pub can_undo: bool,
    pub can_redo: bool,
    pub sheets: Vec<XlsxSheetSessionStatus>,
}

impl XlsxWorkbookSessionStatus {
    /// Build a status summary from the current workbook runtime state.
    pub fn from_session(session: &XlsxWorkbookSession) -> Self {
        let active_sheet_name = session.active_sheet_name().to_owned();
        let sheets = session
            .sheet_entries()
            .iter()
            .map(|entry| {
                let diagnostics = entry.session().diagnostics();
                let state = entry.session().state();

                XlsxSheetSessionStatus {
                    sheet_name: entry.sheet_name().to_owned(),
                    document_id: entry.document_id().clone(),
                    is_active: entry.sheet_name() == active_sheet_name,
                    cell_count: state.cell_count(),
                    max_col: state.max_col,
                    max_row: state.max_row,
                    sequence: diagnostics.sequence,
                    is_dirty: diagnostics.is_dirty,
                    dirty_sequence_range: diagnostics.dirty_sequence_range,
                    pending_operation_count: diagnostics.pending_operation_count,
                    operation_log_count: diagnostics.operation_log_count,
                    selection_kind: diagnostics.selection_kind,
                    selection_is_empty: diagnostics.selection_is_empty,
                    can_undo: diagnostics.can_undo,
                    can_redo: diagnostics.can_redo,
                }
            })
            .collect::<Vec<_>>();

        Self {
            workbook_id: session.workbook_id().to_owned(),
            active_sheet_name,
            sheet_count: sheets.len(),
            total_cell_count: sheets.iter().map(|sheet| sheet.cell_count).sum(),
            dirty_sheet_count: sheets.iter().filter(|sheet| sheet.is_dirty).count(),
            pending_operation_count: sheets
                .iter()
                .map(|sheet| sheet.pending_operation_count)
                .sum(),
            operation_log_count: sheets.iter().map(|sheet| sheet.operation_log_count).sum(),
            can_undo: sheets.iter().any(|sheet| sheet.can_undo),
            can_redo: sheets.iter().any(|sheet| sheet.can_redo),
            sheets,
        }
    }

    /// Return true when at least one sheet has unsaved operations.
    pub fn is_dirty(&self) -> bool {
        self.dirty_sheet_count > 0
    }

    /// Return true when at least one sheet has pending operations.
    pub fn has_pending_operations(&self) -> bool {
        self.pending_operation_count > 0
    }

    /// Return the active sheet status, if it is present.
    pub fn active_sheet(&self) -> Option<&XlsxSheetSessionStatus> {
        self.sheet_by_name(&self.active_sheet_name)
    }

    /// Find a sheet status by trimmed sheet name.
    pub fn sheet_by_name(&self, sheet_name: &str) -> Option<&XlsxSheetSessionStatus> {
        let requested = sheet_name.trim();
        self.sheets
            .iter()
            .find(|sheet| sheet.sheet_name == requested)
    }

    /// Return dirty sheet names in workbook order.
    pub fn dirty_sheet_names(&self) -> Vec<&str> {
        self.sheets
            .iter()
            .filter(|sheet| sheet.is_dirty)
            .map(|sheet| sheet.sheet_name.as_str())
            .collect()
    }
}

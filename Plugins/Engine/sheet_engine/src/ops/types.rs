//! Shared sheet operation contracts used by sessions, history, and workbook facades.

use crate::{CellFormat, CellPosition, SheetCellSnapshot, SheetGrid, SheetStructureEdit};
use serde::{Deserialize, Serialize};
use waraq_core::{OfficeSnapshot, OperationEnvelope, OperationLog, OperationTransaction};

/// Stable engine identifier used by sheet operation envelopes and snapshots.
pub const SHEET_ENGINE_ID: &str = "sheet";

/// User-facing mutation that can be applied to a sheet grid.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SheetEdit {
    /// Replace a cell's raw content and recalculate dependent formulas.
    SetCell {
        position: CellPosition,
        raw_content: String,
    },
    /// Replace a cell's raw content and format in one recalculated edit.
    SetCellWithFormat {
        position: CellPosition,
        raw_content: String,
        format: CellFormat,
    },
    /// Remove a cell and recalculate dependent formulas.
    ClearCell { position: CellPosition },
    /// Apply a visual format without recalculating formulas.
    SetCellFormat {
        position: CellPosition,
        format: CellFormat,
    },
    /// Restore exact cell snapshots, typically as an undo inverse.
    RestoreCells { cells: Vec<SheetCellSnapshot> },
    /// Apply a row or column structure mutation.
    ApplyStructure { edit: SheetStructureEdit },
    /// Re-evaluate formulas without changing raw cell content.
    Recalculate,
}

/// Result metadata returned after a sheet edit is applied.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SheetEditOutcome {
    /// Cell coordinates that were directly changed or recalculated by the edit.
    pub changed_cells: Vec<CellPosition>,
    /// Whether formula evaluation was run as part of the edit.
    pub recalculated: bool,
}

/// Persistable operation envelope carrying one sheet edit.
pub type SheetOperation = OperationEnvelope<SheetEdit>;

/// Ordered operation log for a sheet document.
pub type SheetOperationLog = OperationLog<SheetEdit>;

/// Undoable group of sheet operations and inverse operations.
pub type SheetTransaction = OperationTransaction<SheetEdit>;

/// Persistable sheet snapshot including grid state and optional operation history.
pub type SheetSnapshot = OfficeSnapshot<SheetGrid, SheetEdit>;

impl SheetEditOutcome {
    pub(crate) fn changed(position: CellPosition, recalculated: bool) -> Self {
        Self {
            changed_cells: vec![position],
            recalculated,
        }
    }
}

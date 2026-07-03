//! Public spreadsheet engine facade for sheet grids, formula evaluation, workbook sessions,
//! and XLSX-compatible import/export flows.
//!
//! # Overview
//!
//! This crate provides a high-performance spreadsheet engine with:
//!
//! - **Sparse Grid Storage**: Efficient memory usage for large spreadsheets with few populated cells
//! - **Formula Evaluation**: DAG-based evaluation with circular reference detection
//! - **Structure Edits**: Row/column insertion and deletion with automatic formula reference updates
//! - **Session Management**: Undo/redo support through operation logs and transactions
//! - **XLSX Compatibility**: Import/export with Excel-compatible file formats
//!
//! # Architecture
//!
//! The engine is organized into several key modules:
//!
//! - [`grid`]: Sparse matrix storage for cell data
//! - [`eval`]: Formula evaluation engine with dependency tracking
//! - [`ast`]: Formula parsing and AST representation
//! - [`ops`]: Edit operations and transaction management
//! - [`structure`]: Row/column structure modifications
//! - [`xlsx`]: XLSX file format handling
//!
//! # Example Usage
//!
//! ```rust,no_run
//! use sheet_engine::{SheetGrid, CellPosition, SheetEdit};
//!
//! // Create a new grid
//! let mut grid = SheetGrid::new("Sheet 1");
//!
//! // Set cell values
//! grid.apply_edit(SheetEdit::SetCell {
//!     position: CellPosition::new(0, 0),
//!     raw_content: "10".into(),
//! }).unwrap();
//!
//! grid.apply_edit(SheetEdit::SetCell {
//!     position: CellPosition::new(1, 0),
//!     raw_content: "=A1*2".into(),
//! }).unwrap();
//!
//! // Cell B1 now contains 20
//! ```
//!
//! Product layers should depend on this crate for sheet behavior. The lower-level `ky-of-xlsx`
//! crate remains an internal parser/writer dependency behind the `xlsx` facade.

pub use waraq_core::core;

pub mod ast;
pub mod cell;
pub mod eval;
pub mod formula;
pub mod formatting;
pub mod grid;
pub mod ops;
pub mod selection;
pub mod session;
pub mod structure;
pub mod validation;
pub mod xlsx;

/// Convenient imports for product integrations that need the stable sheet facade.
pub mod prelude {
    pub use crate::{
        apply_sheet_edit, apply_sheet_operation, apply_sheet_structure_edit, cell_position,
        grid_position, import_grid_workbook_bytes, import_grids_from_workbook_bytes,
        import_sheet_sessions_from_workbook_bytes, import_workbook_session_from_bytes,
        sheet_operation, sheet_session, sheet_snapshot, shift_formula_references_for_structure,
        summarize_workbook_bytes, translate_formula_references, write_empty_workbook,
        write_grid_workbook, write_grids_to_workbook, write_workbook_session, Cell, CellFormat,
        CellPosition, CellValue, ConditionalFormatManager, ConditionalFormatRule, CellRange,
        FormatCondition, ComparisonOperator as FormatComparisonOperator, DateCondition, ColorScaleStop, IconSetType,
        DataValidationManager, DataValidationRule, ValidationType, ComparisonOperator as ValidationComparisonOperator,
        ErrorStyle, InputMessage, InputMessagePosition, ValidationResult,
        EvalError, FormulaEvaluator, FormulaReferenceOffset,
        FormulaReferenceStructureEdit, SheetCellSelection, SheetCellSnapshot, SheetEdit,
        SheetEditOutcome, SheetGrid, SheetGridSnapshot, SheetOperation, SheetOperationLog,
        SheetRangeSelection, SheetSelection, SheetSession, SheetSnapshot, SheetStructureEdit,
        SheetTransaction, XlsxAddSheetRequest, XlsxCellFormatPatch, XlsxClearRangeRequest,
        XlsxClipboardLineEnding, XlsxClipboardTextCodec, XlsxClipboardTextOptions,
        XlsxClipboardTextResult, XlsxCopyRangeRequest, XlsxCopyRangeTextRequest,
        XlsxFormatRangeRequest, XlsxGridWorkbook, XlsxImportOptions, XlsxMoveSheetRequest,
        XlsxOptionalStringFormatPatch, XlsxPasteClipboardRequest, XlsxPasteClipboardTextRequest,
        XlsxRangeCellUpdate, XlsxRemoveSheetRequest, XlsxRenameSheetRequest,
        XlsxSheetClipboardPayload, XlsxSheetEditRequest, XlsxSheetEditResult,
        XlsxSheetHistoryAction, XlsxSheetHistoryRequest, XlsxSheetHistoryResult, XlsxSheetRange,
        XlsxSheetRangeEditRequest, XlsxSheetRangeEditResult, XlsxSheetSessionBundle,
        XlsxSheetSessionEntry, XlsxSheetSessionStatus, XlsxSheetStructureEditRequest,
        XlsxSheetStructureEditResult, XlsxSheetSummary, XlsxUndoableSheetEditRequest,
        XlsxUndoableSheetEditResult, XlsxUndoableSheetStructureEditRequest,
        XlsxUndoableSheetStructureEditResult, XlsxWorkbookCommand, XlsxWorkbookCommandAvailability,
        XlsxWorkbookCommandDelta, XlsxWorkbookCommandDisabledReason, XlsxWorkbookCommandResult,
        XlsxWorkbookCommandState, XlsxWorkbookError, XlsxWorkbookRequest, XlsxWorkbookSession,
        XlsxWorkbookSessionStatus, XlsxWorkbookSheetSnapshot, XlsxWorkbookSnapshot,
        XlsxWorkbookSummary, SHEET_ENGINE_ID,
    };
}

// Re-export core types.
pub use cell::{Cell, CellFormat, CellValue};
pub use eval::{EvalError, FormulaEvaluator};
pub use formatting::{
    ConditionalFormatManager, ConditionalFormatRule, CellRange, FormatCondition,
    ComparisonOperator as FormatComparisonOperator, DateCondition, ColorScaleStop, IconSetType,
};
pub use formula::{
    shift_formula_references_for_structure, translate_formula_references, FormulaReferenceOffset,
    FormulaReferenceStructureEdit,
};
pub use validation::{
    DataValidationManager, DataValidationRule, ValidationType,
    ComparisonOperator as ValidationComparisonOperator, ErrorStyle, InputMessage,
    InputMessagePosition, ValidationResult,
};
pub use grid::{CellPosition, SheetCellSnapshot, SheetGrid, SheetGridSnapshot};
pub use ops::{
    apply_sheet_edit, apply_sheet_operation, sheet_operation, sheet_snapshot, SheetEdit,
    SheetEditOutcome, SheetOperation, SheetOperationLog, SheetSnapshot, SheetTransaction,
    SHEET_ENGINE_ID,
};
pub use selection::{
    cell_position, grid_position, SheetCellSelection, SheetRangeSelection, SheetSelection,
};
pub use session::{sheet_session, SheetSession};
pub use structure::{apply_sheet_structure_edit, SheetStructureEdit};
pub use xlsx::*;

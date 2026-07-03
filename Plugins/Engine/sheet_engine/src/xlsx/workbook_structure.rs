//! Structure edit contracts for XLSX workbook sessions.

mod request;
mod result;
mod undo;
mod undoable;

pub use request::XlsxSheetStructureEditRequest;
pub use result::XlsxSheetStructureEditResult;
pub(crate) use undo::inverse_edits_for_structure_undo;
pub use undoable::{XlsxUndoableSheetStructureEditRequest, XlsxUndoableSheetStructureEditResult};

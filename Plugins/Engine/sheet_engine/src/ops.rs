//! Spreadsheet operation facade for edit contracts, builders, and application logic.

mod apply;
mod snapshot;
mod types;

pub use apply::{apply_sheet_edit, apply_sheet_operation};
pub use snapshot::{sheet_operation, sheet_snapshot};
pub use types::{
    SheetEdit, SheetEditOutcome, SheetOperation, SheetOperationLog, SheetSnapshot,
    SheetTransaction, SHEET_ENGINE_ID,
};

#[cfg(test)]
mod tests;

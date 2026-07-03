//! Product-facing workbook command facade for XLSX-backed sheet sessions.

mod command;
mod result;
mod sheet_requests;

pub use command::XlsxWorkbookCommand;
pub use result::XlsxWorkbookCommandResult;
pub use sheet_requests::{
    XlsxAddSheetRequest, XlsxMoveSheetRequest, XlsxRemoveSheetRequest, XlsxRenameSheetRequest,
};

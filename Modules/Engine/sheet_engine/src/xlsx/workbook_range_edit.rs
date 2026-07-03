//! Range edit contract facade for XLSX workbook sessions.

mod cell_update;
mod range;
mod request;
mod result;

pub use cell_update::XlsxRangeCellUpdate;
pub use range::XlsxSheetRange;
pub use request::XlsxSheetRangeEditRequest;
pub use result::XlsxSheetRangeEditResult;

//! Workbook request and summary contracts for the XLSX facade.

mod request;
mod summary;

pub use request::XlsxWorkbookRequest;
pub use summary::{XlsxSheetSummary, XlsxWorkbookSummary};

#[cfg(test)]
mod tests;

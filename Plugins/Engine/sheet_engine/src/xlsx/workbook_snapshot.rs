//! Workbook snapshot facade for XLSX runtime persistence and recovery.

mod sheet_snapshot;
mod validation;
mod workbook_snapshot;

pub use sheet_snapshot::XlsxWorkbookSheetSnapshot;
pub use workbook_snapshot::XlsxWorkbookSnapshot;

#[cfg(test)]
mod tests;

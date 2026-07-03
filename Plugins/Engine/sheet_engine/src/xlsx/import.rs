//! Workbook import and summary helpers for the XLSX facade.

mod options;
mod summary;

pub use options::XlsxImportOptions;
pub use summary::{summarize_workbook, summarize_workbook_bytes};

#[cfg(test)]
mod tests;

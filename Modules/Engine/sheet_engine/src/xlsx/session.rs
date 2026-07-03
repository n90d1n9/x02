//! Sheet-session facade for importing XLSX workbook sheets into editable state.

mod bundle;
mod entry;
mod import;

pub use bundle::XlsxSheetSessionBundle;
pub use entry::XlsxSheetSessionEntry;
pub use import::import_sheet_sessions_from_workbook_bytes;

#[cfg(test)]
mod tests;

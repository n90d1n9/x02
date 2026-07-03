use crate::XlsxSheetSessionBundle;

mod commands;
mod edits;
mod history;
mod lifecycle;
mod lookup;
mod persistence;
mod ranges;
mod status;

pub use persistence::{import_workbook_session_from_bytes, write_workbook_session};

/// Workbook-level runtime model that coordinates ordered sheet editing sessions.
#[derive(Debug)]
pub struct XlsxWorkbookSession {
    active_sheet_name: String,
    sheets: XlsxSheetSessionBundle,
}

#[cfg(test)]
mod tests;

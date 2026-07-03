//! Ordered workbook-sheet session collection.

mod construction;
mod lookup;
mod mutation;
mod validation;

use super::XlsxSheetSessionEntry;

/// Ordered collection of core sheet sessions imported from one XLSX workbook.
#[derive(Debug)]
pub struct XlsxSheetSessionBundle {
    workbook_id: String,
    entries: Vec<XlsxSheetSessionEntry>,
}

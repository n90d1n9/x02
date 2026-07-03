//! Clipboard text parsing helpers for spreadsheet-compatible TSV payloads.

mod encoding;
mod field;
mod range;
mod tsv;

pub(super) use encoding::push_encoded_field;
pub(super) use range::checked_range;
pub(super) use tsv::parse_tsv;

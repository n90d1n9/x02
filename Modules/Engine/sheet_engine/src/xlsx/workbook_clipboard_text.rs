//! Spreadsheet-compatible text clipboard facade for workbook range copy/paste APIs.

mod codec;
mod options;
mod parser;
mod requests;
mod result;

pub use codec::XlsxClipboardTextCodec;
pub use options::{XlsxClipboardLineEnding, XlsxClipboardTextOptions};
pub use requests::{XlsxCopyRangeTextRequest, XlsxPasteClipboardTextRequest};
pub use result::XlsxClipboardTextResult;

#[cfg(test)]
mod tests;

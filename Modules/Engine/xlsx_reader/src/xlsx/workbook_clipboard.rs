//! Clipboard request and payload facade for XLSX workbook sessions.

mod copy_request;
mod paste_request;
mod payload;

pub use copy_request::XlsxCopyRangeRequest;
pub use paste_request::XlsxPasteClipboardRequest;
pub use payload::XlsxSheetClipboardPayload;

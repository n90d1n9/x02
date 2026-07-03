//! Error types for ky-of-xlsx.

use std::path::PathBuf;
use thiserror::Error;

/// Crate-level `Result` alias.
pub type Result<T, E = Error> = std::result::Result<T, E>;

/// All errors that can arise while opening or reading a workbook.
#[derive(Debug, Error)]
#[non_exhaustive]
pub enum Error {
    /// The file could not be found or opened.
    #[error("I/O error reading `{path}`: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    /// Generic I/O error without a specific path (e.g. from a reader).
    #[error("I/O error: {0}")]
    IoRaw(#[from] std::io::Error),

    /// The ZIP container of an XLSX/XLSB file is malformed.
    #[error("ZIP error: {0}")]
    Zip(#[from] zip::result::ZipError),

    /// An XML fragment inside the XLSX is not well-formed.
    #[error("XML parse error: {0}")]
    Xml(#[from] quick_xml::Error),

    /// Calamine backend error (XLS, XLSB, ODS).
    #[error("Spreadsheet parse error: {0}")]
    Calamine(#[from] calamine::Error),

    /// The requested sheet name or index does not exist.
    #[error("Sheet not found: `{0}`")]
    SheetNotFound(String),

    /// A cell address string is syntactically invalid (e.g. "ZZZ").
    #[error("Invalid cell address `{0}`")]
    InvalidAddress(String),

    /// A cell reference is out of range for the sheet.
    #[error("Cell ({row}, {col}) out of range for sheet `{sheet}`")]
    OutOfRange { row: u32, col: u16, sheet: String },

    /// The workbook does not contain a `xl/workbook.xml` part.
    #[error("Workbook part missing from archive")]
    MissingWorkbookPart,

    /// A shared-string index in a cell is beyond the SST table.
    #[error("Shared string index {0} is out of bounds")]
    SharedStringOutOfBounds(usize),

    /// Password-protected workbooks are not supported.
    #[error("Password-protected workbooks are not supported")]
    PasswordProtected,

    /// An unsupported file format was supplied.
    #[error("Unsupported file format: `{0}`")]
    UnsupportedFormat(String),

    /// A date serial number could not be converted.
    #[error("Cannot convert serial {0} to a date/time")]
    InvalidDateSerial(f64),

    /// Wraps arbitrary string errors from calamine deserialization.
    #[error("{0}")]
    Custom(String),
}

impl Error {
    /// Construct a custom error from any `Display`-able value.
    pub fn custom(msg: impl std::fmt::Display) -> Self {
        Error::Custom(msg.to_string())
    }
}

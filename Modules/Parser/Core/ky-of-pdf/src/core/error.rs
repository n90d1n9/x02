use thiserror::Error;

/// All errors that rustpdf can produce.
#[derive(Debug, Error)]
pub enum Error {
    /// The file could not be read from the filesystem.
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// The PDF could not be parsed (corrupt, truncated, unsupported feature).
    #[error("PDF parse error: {0}")]
    Parse(String),

    /// A password is required to open this PDF.
    #[error("PDF is password protected")]
    PasswordRequired,

    /// The supplied password was incorrect.
    #[error("Incorrect password")]
    WrongPassword,

    /// A requested page index is out of range.
    #[error("Page {0} is out of range (document has {1} pages)")]
    PageOutOfRange(usize, usize),

    /// The requested object was not found inside the PDF.
    #[error("Object not found: {0}")]
    ObjectNotFound(String),

    /// JSON serialization/deserialization failure.
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),

    /// An unsupported encoding was encountered during text extraction.
    #[error("Encoding error: {0}")]
    Encoding(String),

    /// Generic catch-all for unexpected conditions.
    #[error("Internal error: {0}")]
    Internal(String),
}

impl From<lopdf::Error> for Error {
    fn from(e: lopdf::Error) -> Self {
        match e {
            lopdf::Error::IO(io) => Error::Io(io),
            other => Error::Parse(other.to_string()),
        }
    }
}

/// Convenience `Result` alias.
pub type Result<T> = std::result::Result<T, Error>;

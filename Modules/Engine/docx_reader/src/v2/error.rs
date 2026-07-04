use thiserror::Error;

/// All errors that can be produced by this crate.
#[derive(Debug, Error)]
pub enum DocxError {
    /// The supplied file is not a valid ZIP/DOCX archive.
    #[error("Invalid DOCX archive: {0}")]
    InvalidArchive(String),

    /// A required XML part could not be found inside the archive.
    #[error("Missing XML part: {0}")]
    MissingPart(String),

    /// XML parsing failed.
    #[error("XML parse error in '{part}': {source}")]
    XmlParse {
        part: String,
        #[source]
        source: quick_xml::Error,
    },

    /// I/O error (file not found, permission denied, etc.).
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    /// ZIP decompression error.
    #[error("ZIP error: {0}")]
    Zip(#[from] zip::result::ZipError),

    /// UTF-8 decoding error.
    #[error("UTF-8 decode error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),

    /// Base64 decode error (for embedded images).
    #[error("Base64 error: {0}")]
    Base64(#[from] base64::DecodeError),

    /// An image with the given relationship ID was not found.
    #[error("Image relationship not found: {0}")]
    ImageNotFound(String),

    /// Attempted to access a part that is not present in this document.
    #[error("Optional part not present: {0}")]
    PartNotPresent(String),

    /// Generic parsing logic error with a description.
    #[error("Parse logic error: {0}")]
    Logic(String),
}

/// Convenience alias used throughout the crate.
pub type Result<T> = std::result::Result<T, DocxError>;

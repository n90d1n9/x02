use thiserror::Error;

/// Result type alias for pptx_reader operations.
pub type Result<T> = std::result::Result<T, PptxError>;

/// Errors that can occur when reading a PPTX file.
#[derive(Debug, Error)]
pub enum PptxError {
    /// IO error accessing the file.
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// The file is not a valid ZIP archive (PPTX files are ZIP archives).
    #[error("Invalid ZIP archive: {0}")]
    InvalidZip(#[from] zip::result::ZipError),

    /// XML parsing error within the PPTX content.
    #[error("XML parse error: {0}")]
    XmlParse(String),

    /// A required part/file is missing from the PPTX archive.
    #[error("Missing required part: {0}")]
    MissingPart(String),

    /// Invalid or malformed data encountered during extraction.
    #[error("Invalid data: {0}")]
    InvalidData(String),

    /// Image extraction failed.
    #[error("Image extraction error: {0}")]
    ImageExtraction(String),

    /// Chart parsing failed.
    #[error("Chart parse error: {0}")]
    ChartParse(String),

    /// Relationship file parsing failed.
    #[error("Relationship parse error: {0}")]
    RelationshipParse(String),

    /// UTF-8 decoding error.
    #[error("UTF-8 decode error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),

    /// Base64 decode error for image data.
    #[error("Base64 decode error: {0}")]
    Base64(#[from] base64::DecodeError),

    /// Integer parsing error.
    #[error("Integer parse error: {0}")]
    ParseInt(#[from] std::num::ParseIntError),



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

impl From<roxmltree::Error> for PptxError {
    fn from(e: roxmltree::Error) -> Self {
        PptxError::XmlParse(e.to_string())
    }
}

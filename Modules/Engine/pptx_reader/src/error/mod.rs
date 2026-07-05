//! Error types for PPTX parsing and manipulation

use std::fmt;
use thiserror::Error;

/// Main error type for PPTX operations
#[derive(Error, Debug)]
pub enum PptxError {
    #[error("ZIP error: {0}")]
    Zip(#[from] zip::result::ZipError),
    
    #[error("XML parsing error: {0}")]
    Xml(#[from] quick_xml::Error),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("JSON serialization error: {0}")]
    Json(#[from] serde_json::Error),
    
    #[error("Invalid PPTX structure: {0}")]
    InvalidStructure(String),
    
    #[error("Missing required part: {0}")]
    MissingPart(String),
    
    #[error("Unsupported feature: {0}")]
    UnsupportedFeature(String),
    
    #[error("Validation error: {0}")]
    Validation(#[from] PptxValidationError),
    
    #[error("Image decoding error: {0}")]
    ImageDecode(String),
    
    #[error("Chart parsing error: {0}")]
    ChartParse(String),
    
    #[error("Animation parsing error: {0}")]
    AnimationParse(String),
    
    #[error("Transition parsing error: {0}")]
    TransitionParse(String),
    
    #[error("Theme parsing error: {0}")]
    ThemeParse(String),
    
    #[error("Relationship error: {0}")]
    Relationship(String),
    
    #[error("Content type error: {0}")]
    ContentType(String),
    
    #[error("Unknown error: {0}")]
    Unknown(String),
}

/// Validation errors for PPTX documents
#[derive(Error, Debug, Clone, PartialEq)]
pub enum PptxValidationError {
    #[error("Slide {0} has invalid dimensions")]
    InvalidSlideDimensions(usize),
    
    #[error("Shape {0} on slide {1} has invalid geometry")]
    InvalidShapeGeometry(String, usize),
    
    #[error("Animation effect {0} has invalid timing")]
    InvalidAnimationTiming(String),
    
    #[error("Transition {0} has unsupported parameters")]
    UnsupportedTransitionParams(String),
    
    #[error("Table on slide {0} has inconsistent cell structure")]
    InconsistentTableStructure(usize),
    
    #[error("Chart on slide {0} has missing data series")]
    MissingChartData(usize),
    
    #[error("Hyperlink target {0} is invalid")]
    InvalidHyperlinkTarget(String),
    
    #[error("Media file {0} has unsupported format")]
    UnsupportedMediaFormat(String),
    
    #[error("Theme color scheme is incomplete")]
    IncompleteColorScheme,
    
    #[error("Master slide reference {0} not found")]
    MasterSlideNotFound(String),
    
    #[error("Layout reference {0} not found in master {1}")]
    LayoutNotFound(String, String),
    
    #[error("Duplicate shape ID {0} on slide {1}")]
    DuplicateShapeId(String, usize),
    
    #[error("Circular animation dependency detected")]
    CircularAnimationDependency,
    
    #[error("Reading order is inconsistent with z-order")]
    InconsistentReadingOrder,
    
    #[error("Accessibility check failed: {0}")]
    AccessibilityFailure(String),
}

/// Result type alias for PPTX operations
pub type Result<T> = std::result::Result<T, PptxError>;

impl PptxError {
    /// Create a validation error
    pub fn validation(error: PptxValidationError) -> Self {
        PptxError::Validation(error)
    }
    
    /// Create an invalid structure error
    pub fn invalid_structure(msg: impl Into<String>) -> Self {
        PptxError::InvalidStructure(msg.into())
    }
    
    /// Create a missing part error
    pub fn missing_part(part: impl Into<String>) -> Self {
        PptxError::MissingPart(part.into())
    }
    
    /// Create an unsupported feature error
    pub fn unsupported_feature(feature: impl Into<String>) -> Self {
        PptxError::UnsupportedFeature(feature.into())
    }
}

impl From<&str> for PptxError {
    fn from(s: &str) -> Self {
        PptxError::Unknown(s.to_string())
    }
}

impl From<String> for PptxError {
    fn from(s: String) -> Self {
        PptxError::Unknown(s)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_error_display() {
        let err = PptxError::invalid_structure("Missing presentation.xml");
        assert!(err.to_string().contains("Invalid PPTX structure"));
        
        let validation_err = PptxValidationError::InvalidSlideDimensions(0);
        let err = PptxError::validation(validation_err);
        assert!(err.to_string().contains("Slide 0 has invalid dimensions"));
    }
    
    #[test]
    fn test_result_alias() {
        let result: Result<()> = Ok(());
        assert!(result.is_ok());
        
        let result: Result<()> = Err(PptxError::unknown("test"));
        assert!(result.is_err());
    }
}

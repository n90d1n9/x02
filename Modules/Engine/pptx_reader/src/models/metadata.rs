//! Metadata model - presentation properties

use serde::{Deserialize, Serialize};

/// Presentation Metadata - core document properties
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PresentationMetadata {
    /// Title
    pub title: Option<String>,
    /// Author/Creator
    pub author: Option<String>,
    /// Company/Organization
    pub company: Option<String>,
    /// Manager
    pub manager: Option<String>,
    /// Subject
    pub subject: Option<String>,
    /// Description/Comments
    pub description: Option<String>,
    /// Presentation format
    pub format: Option<String>,
    /// Creation date (ISO 8601)
    pub created: Option<String>,
    /// Last modified date (ISO 8601)
    pub modified: Option<String>,
    /// Total editing time in seconds
    pub total_time_seconds: Option<u64>,
    /// Number of slides
    pub slide_count: Option<usize>,
    /// Number of hidden slides
    pub hidden_slide_count: Option<usize>,
    /// Keywords/tags
    pub keywords: Option<String>,
    /// Category
    pub category: Option<String>,
    /// Application that created the file
    pub application: Option<String>,
    /// Application version
    pub app_version: Option<String>,
}

impl PresentationMetadata {
    pub fn new() -> Self {
        Self::default()
    }
}

impl Default for PresentationMetadata {
    fn default() -> Self {
        Self {
            title: None,
            author: None,
            company: None,
            manager: None,
            subject: None,
            description: None,
            format: None,
            created: None,
            modified: None,
            total_time_seconds: None,
            slide_count: None,
            hidden_slide_count: None,
            keywords: None,
            category: None,
            application: None,
            app_version: None,
        }
    }
}

use serde::{Deserialize, Serialize};

/// Presentation-level metadata (document properties).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PresentationMetadata {
    pub title: Option<String>,
    pub subject: Option<String>,
    pub author: Option<String>,
    pub keywords: Option<String>,
    pub description: Option<String>,
    pub last_modified_by: Option<String>,
    pub revision: Option<String>,
    pub created: Option<String>,
    pub modified: Option<String>,
    pub category: Option<String>,
    pub content_status: Option<String>,
    pub language: Option<String>,
    /// Application that created the file (e.g., "Microsoft Office PowerPoint").
    pub application: Option<String>,
    pub app_version: Option<String>,
    pub company: Option<String>,
    pub presentation_format: Option<String>,
    pub notes_words: Option<u32>,
    pub slides_count: Option<u32>,
    pub hidden_slides_count: Option<u32>,
    pub mm_clips_count: Option<u32>,
    pub scale_crop: Option<bool>,
    pub links_up_to_date: Option<bool>,
    pub shared_doc: Option<bool>,
    pub hyperlinks_changed: Option<bool>,
}

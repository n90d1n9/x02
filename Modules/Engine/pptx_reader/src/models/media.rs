//! Media file model - embedded images, audio, and video

use serde::{Deserialize, Serialize};

/// Media File - embedded image, audio, or video
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaFile {
    /// Path within the PPTX package
    pub path: String,
    /// Raw binary data
    #[serde(skip_serializing, skip_deserializing)]
    pub data: Vec<u8>,
    /// MIME content type
    pub content_type: String,
}

impl MediaFile {
    pub fn new(path: &str, data: Vec<u8>, content_type: &str) -> Self {
        Self {
            path: path.to_string(),
            data,
            content_type: content_type.to_string(),
        }
    }
    
    pub fn is_image(&self) -> bool {
        self.content_type.starts_with("image/")
    }
    
    pub fn is_audio(&self) -> bool {
        self.content_type.starts_with("audio/")
    }
    
    pub fn is_video(&self) -> bool {
        self.content_type.starts_with("video/")
    }
    
    pub fn extension(&self) -> Option<&str> {
        self.path.split('.').last()
    }
}

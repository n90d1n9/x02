//! Image data model

use serde::{Deserialize, Serialize};

/// Image Data - embedded image in a presentation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImageData {
    /// Raw binary data
    #[serde(skip_serializing, skip_deserializing)]
    pub data: Vec<u8>,
    /// MIME content type
    pub content_type: String,
    /// Width in pixels (if known)
    pub width: u32,
    /// Height in pixels (if known)
    pub height: u32,
}

impl ImageData {
    pub fn new(data: Vec<u8>, content_type: &str) -> Self {
        Self {
            data,
            content_type: content_type.to_string(),
            width: 0,
            height: 0,
        }
    }
    
    pub fn is_png(&self) -> bool {
        self.content_type == "image/png"
    }
    
    pub fn is_jpeg(&self) -> bool {
        self.content_type == "image/jpeg"
    }
    
    pub fn is_gif(&self) -> bool {
        self.content_type == "image/gif"
    }
    
    pub fn is_emf(&self) -> bool {
        self.content_type == "image/emf"
    }
    
    pub fn is_wmf(&self) -> bool {
        self.content_type == "image/wmf"
    }
}

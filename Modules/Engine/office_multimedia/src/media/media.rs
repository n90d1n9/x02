use serde::{Deserialize, Serialize};

/// Embedded media file (audio or video) in the presentation package.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MediaFile {
    pub relationship_id: String,
    pub filename: String,
    pub mime_type: String,
    pub extension: String,
    pub data: Vec<u8>,
    pub media_kind: MediaKind,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum MediaKind {
    Audio,
    Video,
    Unknown,
}

impl MediaFile {
    pub fn file_size(&self) -> usize { self.data.len() }

    pub fn as_base64(&self) -> String {
        use base64::{Engine, engine::general_purpose::STANDARD};
        STANDARD.encode(&self.data)
    }
}

//! Module for handling embedded objects (e.g., OLE objects) in a .docx archive.

use serde::{Deserialize, Serialize};

/// Representation of an embedded OLE object.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddedObject {
    /// Relationship ID linking to the binary data.
    pub rel_id: String,
    /// Target path inside the archive (e.g., "word/embeddings/oleObject1.bin").
    pub target: String,
    /// Optional description from the XML.
    pub description: Option<String>,
}


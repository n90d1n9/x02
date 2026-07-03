use serde::{Deserialize, Serialize};

// ═══════════════════════════════════════════════
// Metadata
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Metadata {
    pub title: Option<String>,
    pub author: Option<String>,
    pub subject: Option<String>,
    pub keywords: Option<String>,
    pub creator: Option<String>,
    pub producer: Option<String>,
    pub creation_date: Option<String>,
    pub modification_date: Option<String>,
    pub pdf_version: String,
    pub page_count: usize,
    pub is_encrypted: bool,
    pub page_layout: Option<String>,
    /// Page media box dimensions [width, height] for page 0 in PDF user units.
    pub page_size: Option<[f64; 2]>,
    /// Custom keys found in the Info dictionary beyond the standard ones.
    pub custom_properties: Vec<(String, String)>,
}

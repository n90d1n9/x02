//! Module for handling embedded objects (e.g., OLE objects) in a .docx archive.



/// Parse `word/embeddings/*.xml` entries and return a list of `EmbeddedObject`.
pub fn parse_embeddings(xml: &str) -> Vec<EmbeddedObject> {
    // Placeholder implementation – real parsing logic would inspect <embed> elements.
    // For now we just return an empty vector, keeping the API stable.
    let _ = xml;
    Vec::new()
}

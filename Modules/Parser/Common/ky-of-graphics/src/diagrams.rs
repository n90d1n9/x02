//! Module for handling diagram parts (e.g., SmartArt) in a .docx archive.

use quick_xml::events::Event;
use quick_xml::Reader;
use serde::{Deserialize, Serialize};
use std::io::BufRead;

/// Representation of a diagram (SmartArt) embedded in a Word document.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Diagram {
    /// Relationship ID from `_rels` referencing the diagram part.
    pub rel_id: String,
    /// Target path inside the zip, e.g. `word/diagrams/diagram1.xml`.
    pub target: String,
    /// Optional title or name of the diagram.
    pub title: Option<String>,
    /// Raw XML content of the diagram.
    pub xml: String,
}

/// Parse a diagram XML document into a `Diagram` struct.
/// This stub reads the whole XML and extracts a simple title if present.
pub fn parse_diagram<R: BufRead>(
    rel_id: &str,
    target: &str,
    reader: &mut Reader<R>,
) -> Result<Diagram, Box<dyn std::error::Error>> {
    let mut scratch = Vec::new();
    let mut xml = String::new();
    while let Ok(event) = reader.read_event_into(&mut scratch) {
        match event {
            Event::Eof => break,
            Event::Text(e) => xml.push_str(&e.unescape()?.into_owned()),
            _ => {}
        }
        scratch.clear();
    }
    let title = xml
        .split("<c:title>")
        .nth(1)
        .and_then(|s| s.split("</c:title>").next())
        .map(|s| s.trim().to_string());
    Ok(Diagram {
        rel_id: rel_id.to_string(),
        target: target.to_string(),
        title,
        xml,
    })
}

pub mod prelude {
    pub use super::{parse_diagram, Diagram};
}

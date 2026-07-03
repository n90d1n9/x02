use std::collections::HashMap;
use crate::error::{PptxError, Result};

/// A single relationship entry from a .rels file.
#[derive(Debug, Clone)]
pub struct Relationship {
    pub id: String,
    pub rel_type: String,
    pub target: String,
    pub target_mode: TargetMode,
}

#[derive(Debug, Clone, PartialEq)]
pub enum TargetMode {
    Internal,
    External,
}

/// A map of relationship ID -> Relationship.
pub type RelationshipMap = HashMap<String, Relationship>;

/// Parse a .rels XML file into a RelationshipMap.
pub fn parse_relationships(xml: &str) -> Result<RelationshipMap> {
    let doc = roxmltree::Document::parse(xml)
        .map_err(|e| PptxError::RelationshipParse(e.to_string()))?;

    let mut map = HashMap::new();
    for node in doc.descendants() {
        if node.tag_name().name() == "Relationship" {
            let id = node.attribute("Id").unwrap_or("").to_string();
            let rel_type = node.attribute("Type").unwrap_or("").to_string();
            let target = node.attribute("Target").unwrap_or("").to_string();
            let target_mode = match node.attribute("TargetMode") {
                Some("External") => TargetMode::External,
                _ => TargetMode::Internal,
            };

            if !id.is_empty() {
                map.insert(id.clone(), Relationship { id, rel_type, target, target_mode });
            }
        }
    }
    Ok(map)
}

/// Resolve a relative path inside the ZIP archive.
/// Given a part path like "ppt/slides/slide1.xml" and a relative path "../media/image1.png",
/// returns "ppt/media/image1.png".
pub fn resolve_path(base_part: &str, relative: &str) -> String {
    if relative.starts_with('/') {
        return relative.trim_start_matches('/').to_string();
    }

    // Get directory of base part
    let base_dir = base_part.rfind('/').map(|i| &base_part[..i]).unwrap_or("");

    let mut parts: Vec<&str> = if base_dir.is_empty() {
        vec![]
    } else {
        base_dir.split('/').collect()
    };

    for segment in relative.split('/') {
        match segment {
            ".." => { parts.pop(); }
            "." | "" => {}
            s => parts.push(s),
        }
    }
    parts.join("/")
}

/// Get the .rels path for a given part path.
/// e.g., "ppt/slides/slide1.xml" → "ppt/slides/_rels/slide1.xml.rels"
pub fn rels_path_for(part_path: &str) -> String {
    if let Some(slash) = part_path.rfind('/') {
        let dir = &part_path[..slash];
        let file = &part_path[slash + 1..];
        format!("{}/_rels/{}.rels", dir, file)
    } else {
        format!("_rels/{}.rels", part_path)
    }
}

/// Well-known relationship type suffixes (the last segment of the full URI).
pub mod rel_types {
    pub const SLIDE: &str = "slide";
    pub const SLIDE_LAYOUT: &str = "slideLayout";
    pub const SLIDE_MASTER: &str = "slideMaster";
    pub const NOTES_SLIDE: &str = "notesSlide";
    pub const NOTES_MASTER: &str = "notesMaster";
    pub const HANDOUT_MASTER: &str = "handoutMaster";
    pub const THEME: &str = "theme";
    pub const IMAGE: &str = "image";
    pub const CHART: &str = "chart";
    pub const DIAGRAM: &str = "diagramLayout";
    pub const AUDIO: &str = "audio";
    pub const VIDEO: &str = "video";
    pub const OLE_OBJECT: &str = "oleObject";
    pub const HYPERLINK: &str = "hyperlink";
    pub const CUSTOM_XML: &str = "customXml";
    pub const TABLE_STYLES: &str = "tableStyles";
    pub const PRESENTATION: &str = "officeDocument";
    pub const CORE_PROPS: &str = "core-properties";
    pub const APP_PROPS: &str = "extended-properties";
    pub const CUSTOM_PROPS: &str = "custom-properties";

    pub fn is_type(full_uri: &str, suffix: &str) -> bool {
        full_uri.ends_with(suffix)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resolve_path() {
        assert_eq!(
            resolve_path("ppt/slides/slide1.xml", "../media/image1.png"),
            "ppt/media/image1.png"
        );
        assert_eq!(
            resolve_path("ppt/slides/slide1.xml", "../charts/chart1.xml"),
            "ppt/charts/chart1.xml"
        );
        assert_eq!(
            resolve_path("ppt/presentation.xml", "slides/slide1.xml"),
            "ppt/slides/slide1.xml"
        );
    }

    #[test]
    fn test_rels_path_for() {
        assert_eq!(
            rels_path_for("ppt/slides/slide1.xml"),
            "ppt/slides/_rels/slide1.xml.rels"
        );
        assert_eq!(
            rels_path_for("ppt/presentation.xml"),
            "ppt/_rels/presentation.xml.rels"
        );
    }
}

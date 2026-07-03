use std::collections::HashMap;
use std::io::Read as _;
use quick_xml::events::Event;
use quick_xml::Reader;

use crate::error::{DocxError, Result};
use crate::models::*;

// ---------------------------------------------------------------------------
// Relationship map
// ---------------------------------------------------------------------------

/// Parse a `_rels/*.rels` file and return `{ rId -> (type, target) }`.
pub fn parse_relationships(xml: &str) -> HashMap<String, (String, String)> {
    let mut map = HashMap::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);

    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) => {
                if e.local_name().as_ref() == b"Relationship" {
                    let mut id = String::new();
                    let mut typ = String::new();
                    let mut target = String::new();
                    for attr in e.attributes().flatten() {
                        match attr.key.as_ref() {
                            b"Id" => id = String::from_utf8_lossy(&attr.value).to_string(),
                            b"Type" => typ = String::from_utf8_lossy(&attr.value).to_string(),
                            b"Target" => target = String::from_utf8_lossy(&attr.value).to_string(),
                            _ => {}
                        }
                    }
                    if !id.is_empty() {
                        map.insert(id, (typ, target));
                    }
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    map
}

// ---------------------------------------------------------------------------
// Content-type map
// ---------------------------------------------------------------------------

/// Parse `[Content_Types].xml` and return `{ part_path -> content_type }`.
pub fn parse_content_types(xml: &str) -> HashMap<String, String> {
    let mut map = HashMap::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) => {
                let name = e.local_name();
                if name.as_ref() == b"Override" {
                    let mut part = String::new();
                    let mut ct = String::new();
                    for attr in e.attributes().flatten() {
                        match attr.key.as_ref() {
                            b"PartName" => part = String::from_utf8_lossy(&attr.value).to_string(),
                            b"ContentType" => ct = String::from_utf8_lossy(&attr.value).to_string(),
                            _ => {}
                        }
                    }
                    if !part.is_empty() {
                        map.insert(part.trim_start_matches('/').to_string(), ct);
                    }
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    map
}


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

pub fn parse_alignment(val: &str) -> Option<Alignment> {
    Some(match val {
        "left" | "start" => Alignment::Left,
        "center" => Alignment::Center,
        "right" | "end" => Alignment::Right,
        "both" | "distribute" => Alignment::Justify,
        _ => return None,
    })
}

use quick_xml::events::Event;
use quick_xml::Reader;
use std::collections::HashMap;

// ---------------------------------------------------------------------------
// Numbering

/// Ordered vs unordered list formatting.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ListType {
    Ordered,
    Unordered,
}
// ---------------------------------------------------------------------------

/// Parse `word/numbering.xml` and return `{ numId -> ListType }`.
pub fn parse_numbering(xml: &str) -> HashMap<String, ListType> {
    // First pass: abstractNumId -> format
    let mut abstract_formats: HashMap<String, ListType> = HashMap::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut current_abstract_id = String::new();
    let mut in_abstract = false;
    let mut in_level = false;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "abstractNum" => {
                        in_abstract = true;
                        current_abstract_id = e.attributes().flatten()
                            .find(|a| a.key.as_ref() == b"w:abstractNumId")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string())
                            .unwrap_or_default();
                    }
                    "lvl" if in_abstract => in_level = true,
                    "numFmt" if in_level => {
                        if let Some(val) = e.attributes().flatten()
                            .find(|a| a.key.as_ref() == b"w:val")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string()) {
                            let lt = if val == "bullet" || val == "none" {
                                ListType::Unordered
                            } else {
                                ListType::Ordered
                            };
                            abstract_formats.entry(current_abstract_id.clone()).or_insert(lt);
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::End(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "abstractNum" => in_abstract = false,
                    "lvl" => in_level = false,
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    // Second pass: num -> abstractNumId, build numId -> ListType
    let mut result: HashMap<String, ListType> = HashMap::new();
    let mut reader2 = Reader::from_str(xml);
    reader2.trim_text(true);
    let mut buf2 = Vec::new();
    let mut in_num = false;
    let mut num_id = String::new();

    loop {
        match reader2.read_event_into(&mut buf2) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "num" if !in_num => {
                        in_num = true;
                        num_id = e.attributes().flatten()
                            .find(|a| a.key.as_ref() == b"w:numId")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string())
                            .unwrap_or_default();
                    }
                    "abstractNumId" if in_num => {
                        if let Some(abs_id) = e.attributes().flatten()
                            .find(|a| a.key.as_ref() == b"w:val")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string()) {
                            let lt = abstract_formats
                                .get(&abs_id)
                                .cloned()
                                .unwrap_or(ListType::Unordered);
                            result.insert(num_id.clone(), lt);
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::End(ref e)) => {
                if e.local_name().as_ref() == b"num" {
                    in_num = false;
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf2.clear();
    }
    result
}

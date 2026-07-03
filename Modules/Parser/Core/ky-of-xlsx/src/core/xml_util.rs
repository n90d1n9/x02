//! Internal helpers for navigating quick-xml events.

use crate::error::Result;
use quick_xml::events::{BytesStart, Event};
use quick_xml::Reader;
use std::collections::HashMap;
use std::io::BufRead;

/// Read all attributes of a start-tag into a `HashMap<String, String>`.
pub fn attrs(tag: &BytesStart) -> HashMap<String, String> {
    tag.attributes()
        .filter_map(|a| a.ok())
        .map(|a| {
            let key = String::from_utf8_lossy(a.key.as_ref()).into_owned();
            let val = String::from_utf8_lossy(a.value.as_ref()).into_owned();
            (key, val)
        })
        .collect()
}

/// Get a single attribute by name from a start-tag.
pub fn attr(tag: &BytesStart, name: &str) -> Option<String> {
    tag.attributes().filter_map(|a| a.ok()).find_map(|a| {
        if a.key.as_ref() == name.as_bytes() {
            Some(String::from_utf8_lossy(a.value.as_ref()).into_owned())
        } else {
            None
        }
    })
}

/// Collect inner text of the current element (reads until matching end tag).
pub fn read_text<R: BufRead>(reader: &mut Reader<R>, end_tag: &[u8]) -> Result<String> {
    let mut buf = Vec::new();
    let mut text = String::new();
    loop {
        match reader.read_event_into(&mut buf)? {
            Event::Text(t) => text.push_str(&t.unescape().unwrap_or_default()),
            Event::CData(c) => text.push_str(&String::from_utf8_lossy(&c)),
            Event::End(e) if e.name().as_ref() == end_tag => break,
            Event::Eof => break,
            _ => {}
        }
        buf.clear();
    }
    Ok(text)
}

/// Skip to the end of an element (consumes all nested children).
pub fn skip_element<R: BufRead>(reader: &mut Reader<R>, tag: &[u8]) -> Result<()> {
    let mut buf = Vec::new();
    let mut depth = 1usize;
    loop {
        match reader.read_event_into(&mut buf)? {
            Event::Start(e) if e.name().as_ref() == tag => depth += 1,
            Event::End(e) if e.name().as_ref() == tag => {
                depth -= 1;
                if depth == 0 {
                    break;
                }
            }
            Event::Eof => break,
            _ => {}
        }
        buf.clear();
    }
    Ok(())
}

//! Core extraction: metadata, plain text, images, bookmarks, form fields.

use base64::{engine::general_purpose::STANDARD as B64, Engine};
use lopdf::{Document, Object, ObjectId};

use crate::{
    error::{Error, Result},
    models::{BookmarkNode, FieldType, FormField, ImageFormat, ImageInfo, Metadata, PageText},
};

// ─────────────────────────────────────────────────────────────────────────────
// Metadata
// ─────────────────────────────────────────────────────────────────────────────

pub fn extract_metadata(doc: &Document) -> Result<Metadata> {
    let page_count = doc.get_pages().len();
    let pdf_version = format!("{}", doc.version);
    let is_encrypted = doc.is_encrypted();

    let mut meta = Metadata {
        page_count,
        pdf_version,
        is_encrypted,
        ..Default::default()
    };

    // Catalog
    if let Ok(cat_id) = doc.trailer.get(b"Root").and_then(|o| o.as_reference()) {
        if let Ok(catalog) = doc.get_object(cat_id) {
            if let Ok(dict) = catalog.as_dict() {
                if let Ok(Object::Name(layout)) = dict.get(b"PageLayout") {
                    meta.page_layout = Some(String::from_utf8_lossy(layout).into_owned());
                }
            }
        }
    }

    // Page 0 size
    let pages = doc.get_pages();
    if let Some(page_id) = pages.get(&1) {
        if let Ok(page_obj) = doc.get_object(*page_id) {
            if let Ok(d) = page_obj.as_dict() {
                if let Ok(Object::Array(mb)) = d.get(b"MediaBox") {
                    let ns: Vec<f64> = mb.iter().filter_map(obj_to_f64).collect();
                    if ns.len() >= 4 {
                        meta.page_size = Some([ns[2] - ns[0], ns[3] - ns[1]]);
                    }
                }
            }
        }
    }

    // Info dictionary
    if let Ok(info_id) = doc.trailer.get(b"Info").and_then(|o| o.as_reference()) {
        if let Ok(info_obj) = doc.get_object(info_id) {
            if let Ok(dict) = info_obj.as_dict() {
                meta.title = get_str(dict, b"Title");
                meta.author = get_str(dict, b"Author");
                meta.subject = get_str(dict, b"Subject");
                meta.keywords = get_str(dict, b"Keywords");
                meta.creator = get_str(dict, b"Creator");
                meta.producer = get_str(dict, b"Producer");
                meta.creation_date = get_str(dict, b"CreationDate").map(|s| normalize_date(&s));
                meta.modification_date = get_str(dict, b"ModDate").map(|s| normalize_date(&s));

                // Custom properties
                let standard = [
                    b"Title".as_slice(),
                    b"Author",
                    b"Subject",
                    b"Keywords",
                    b"Creator",
                    b"Producer",
                    b"CreationDate",
                    b"ModDate",
                    b"Trapped",
                ];
                for (key, val) in dict.iter() {
                    if standard.iter().any(|s| s == key) {
                        continue;
                    }
                    if let Some(v) = decode_obj_string(val) {
                        meta.custom_properties
                            .push((String::from_utf8_lossy(key).into_owned(), v));
                    }
                }
            }
        }
    }
    Ok(meta)
}

pub(crate) fn get_str(dict: &lopdf::Dictionary, key: &[u8]) -> Option<String> {
    dict.get(key).ok().and_then(|o| decode_obj_string(o))
}

pub(crate) fn decode_obj_string(obj: &Object) -> Option<String> {
    match obj {
        Object::String(bytes, _) => {
            if bytes.len() >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF {
                let chars: Vec<u16> = bytes[2..]
                    .chunks_exact(2)
                    .map(|c| u16::from_be_bytes([c[0], c[1]]))
                    .collect();
                String::from_utf16(&chars).ok()
            } else {
                Some(String::from_utf8_lossy(bytes).into_owned())
            }
        }
        Object::Name(bytes) => Some(String::from_utf8_lossy(bytes).into_owned()),
        _ => None,
    }
}

fn normalize_date(s: &str) -> String {
    let s = s.trim_start_matches("D:");
    if s.len() >= 8 {
        format!(
            "{}-{}-{}T{}:{}:{}",
            &s[0..4],
            if s.len() >= 6 { &s[4..6] } else { "01" },
            if s.len() >= 8 { &s[6..8] } else { "01" },
            if s.len() >= 10 { &s[8..10] } else { "00" },
            if s.len() >= 12 { &s[10..12] } else { "00" },
            if s.len() >= 14 { &s[12..14] } else { "00" }
        )
    } else {
        s.to_owned()
    }
}

fn obj_to_f64(o: &Object) -> Option<f64> {
    match o {
        Object::Integer(n) => Some(*n as f64),
        Object::Real(f) => Some(*f as f64),
        _ => None,
    }
}

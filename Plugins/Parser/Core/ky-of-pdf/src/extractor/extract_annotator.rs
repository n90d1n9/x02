//! Read and write PDF annotations (comments, highlights, links, stamps).

use crate::{
    error::{Error, Result},
    models::{Annotation, AnnotationKind},
};
use lopdf::{Document, Object, ObjectId};

/// Extract all annotations from every page.
pub fn extract_annotations(doc: &Document) -> Result<Vec<Annotation>> {
    let mut pages: Vec<(u32, ObjectId)> = doc.get_pages().into_iter().collect();
    pages.sort_by_key(|(n, _)| *n);
    let mut out = Vec::new();
    for (page_num, page_id) in &pages {
        let page_index = (*page_num as usize).saturating_sub(1);
        out.extend(extract_page_annotations(doc, *page_id, page_index)?);
    }
    Ok(out)
}

fn extract_page_annotations(
    doc: &Document,
    page_id: ObjectId,
    page_index: usize,
) -> Result<Vec<Annotation>> {
    let page_obj = doc.get_object(page_id)?;
    let page_dict = page_obj
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?;

    let annot_array = match page_dict.get(b"Annots") {
        Ok(Object::Array(a)) => a.clone(),
        Ok(Object::Reference(id)) => match doc.get_object(*id)? {
            Object::Array(a) => a.clone(),
            _ => return Ok(vec![]),
        },
        _ => return Ok(vec![]),
    };

    let mut annotations = Vec::new();
    for annot_ref in &annot_array {
        let annot_obj = match annot_ref {
            Object::Reference(id) => match doc.get_object(*id) {
                Ok(o) => o,
                Err(_) => continue,
            },
            other => other,
        };
        let dict = match annot_obj.as_dict() {
            Ok(d) => d,
            Err(_) => continue,
        };

        let subtype = dict
            .get(b"Subtype")
            .ok()
            .and_then(|o| o.as_name_str().ok().map(|s| s.to_owned()))
            .unwrap_or_default();

        let kind = match subtype.as_str() {
            "Text" => AnnotationKind::Text,
            "FreeText" => AnnotationKind::FreeText,
            "Highlight" => AnnotationKind::Highlight,
            "Underline" => AnnotationKind::Underline,
            "StrikeOut" => AnnotationKind::StrikeOut,
            "Squiggly" => AnnotationKind::Squiggly,
            "Link" => AnnotationKind::Link,
            "Stamp" => AnnotationKind::Stamp,
            "Ink" => AnnotationKind::Ink,
            "Widget" => AnnotationKind::Widget,
            _ => AnnotationKind::Unknown,
        };

        let contents = get_str(dict, b"Contents");
        let author = get_str(dict, b"T");
        let date = get_str(dict, b"M").map(|s| normalize_date(&s));

        let rect = dict
            .get(b"Rect")
            .ok()
            .and_then(|o| o.as_array().ok())
            .and_then(|a| {
                let ns: Vec<f64> = a.iter().filter_map(obj_to_f64).collect();
                if ns.len() == 4 {
                    Some([ns[0], ns[1], ns[2], ns[3]])
                } else {
                    None
                }
            });

        // Link URI
        let uri = if kind == AnnotationKind::Link {
            dict.get(b"A")
                .ok()
                .and_then(|o| o.as_dict().ok())
                .and_then(|d| d.get(b"URI").ok())
                .and_then(|o| match o {
                    Object::String(b, _) => Some(String::from_utf8_lossy(b).into_owned()),
                    _ => None,
                })
        } else {
            None
        };

        // Colour
        let color = dict
            .get(b"C")
            .ok()
            .and_then(|o| o.as_array().ok())
            .and_then(|a| {
                let ns: Vec<f64> = a.iter().filter_map(obj_to_f64).collect();
                match ns.len() {
                    1 => Some([ns[0], ns[0], ns[0], 1.0]),
                    3 => Some([ns[0], ns[1], ns[2], 1.0]),
                    4 => Some([ns[0], ns[1], ns[2], ns[3]]),
                    _ => None,
                }
            });

        annotations.push(Annotation {
            page_index,
            kind,
            contents,
            author,
            date,
            rect,
            uri,
            color,
        });
    }
    Ok(annotations)
}

fn get_str(dict: &lopdf::Dictionary, key: &[u8]) -> Option<String> {
    dict.get(key).ok().and_then(|o| match o {
        Object::String(b, _) => {
            if b.len() >= 2 && b[0] == 0xFE && b[1] == 0xFF {
                let chars: Vec<u16> = b[2..]
                    .chunks_exact(2)
                    .map(|c| u16::from_be_bytes([c[0], c[1]]))
                    .collect();
                String::from_utf16(&chars).ok()
            } else {
                Some(String::from_utf8_lossy(b).into_owned())
            }
        }
        Object::Name(b) => Some(String::from_utf8_lossy(b).into_owned()),
        _ => None,
    })
}

fn obj_to_f64(o: &Object) -> Option<f64> {
    match o {
        Object::Integer(n) => Some(*n as f64),
        Object::Real(f) => Some(*f as f64),
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

// ─── Write helpers ────────────────────────────────────────────────────────────

/// Add a text (sticky-note) annotation to a page in a mutable document.
///
/// `rect` = [x1, y1, x2, y2] in user units.
pub fn add_text_annotation(
    doc: &mut Document,
    page_index: usize,
    rect: [f64; 4],
    author: &str,
    contents: &str,
) -> Result<()> {
    let page_id = get_page_id(doc, page_index)?;
    let annot_id = doc.new_object_id();
    let annot = lopdf::Dictionary::from_iter(vec![
        (b"Type".to_vec(), Object::Name(b"Annot".to_vec())),
        (b"Subtype".to_vec(), Object::Name(b"Text".to_vec())),
        (b"Rect".to_vec(), Object::Array(rect_to_array(rect))),
        (b"Contents".to_vec(), Object::string_literal(contents)),
        (b"T".to_vec(), Object::string_literal(author)),
        (b"Open".to_vec(), Object::Boolean(false)),
    ]);
    doc.objects.insert(annot_id, Object::Dictionary(annot));
    push_annot_ref(doc, page_id, annot_id)?;
    Ok(())
}

/// Add a web-link annotation.
pub fn add_link_annotation(
    doc: &mut Document,
    page_index: usize,
    rect: [f64; 4],
    uri: &str,
) -> Result<()> {
    let page_id = get_page_id(doc, page_index)?;
    let action = lopdf::Dictionary::from_iter(vec![
        (b"S".to_vec(), Object::Name(b"URI".to_vec())),
        (b"URI".to_vec(), Object::string_literal(uri)),
    ]);
    let annot_id = doc.new_object_id();
    let annot = lopdf::Dictionary::from_iter(vec![
        (b"Type".to_vec(), Object::Name(b"Annot".to_vec())),
        (b"Subtype".to_vec(), Object::Name(b"Link".to_vec())),
        (b"Rect".to_vec(), Object::Array(rect_to_array(rect))),
        (b"A".to_vec(), Object::Dictionary(action)),
        (
            b"Border".to_vec(),
            Object::Array(vec![
                Object::Integer(0),
                Object::Integer(0),
                Object::Integer(1),
            ]),
        ),
    ]);
    doc.objects.insert(annot_id, Object::Dictionary(annot));
    push_annot_ref(doc, page_id, annot_id)?;
    Ok(())
}

/// Add a highlight annotation over a rectangle.
pub fn add_highlight_annotation(
    doc: &mut Document,
    page_index: usize,
    rect: [f64; 4],
    color: [f64; 3],
    author: &str,
) -> Result<()> {
    let page_id = get_page_id(doc, page_index)?;
    let annot_id = doc.new_object_id();
    let quad_points = vec![
        Object::Real(rect[0] as f32),
        Object::Real(rect[3] as f32),
        Object::Real(rect[2] as f32),
        Object::Real(rect[3] as f32),
        Object::Real(rect[0] as f32),
        Object::Real(rect[1] as f32),
        Object::Real(rect[2] as f32),
        Object::Real(rect[1] as f32),
    ];
    let annot = lopdf::Dictionary::from_iter(vec![
        (b"Type".to_vec(), Object::Name(b"Annot".to_vec())),
        (b"Subtype".to_vec(), Object::Name(b"Highlight".to_vec())),
        (b"Rect".to_vec(), Object::Array(rect_to_array(rect))),
        (b"QuadPoints".to_vec(), Object::Array(quad_points)),
        (
            b"C".to_vec(),
            Object::Array(vec![
                Object::Real(color[0] as f32),
                Object::Real(color[1] as f32),
                Object::Real(color[2] as f32),
            ]),
        ),
        (b"T".to_vec(), Object::string_literal(author)),
    ]);
    doc.objects.insert(annot_id, Object::Dictionary(annot));
    push_annot_ref(doc, page_id, annot_id)?;
    Ok(())
}

// helpers
fn get_page_id(doc: &Document, page_index: usize) -> Result<ObjectId> {
    let page_number = (page_index + 1) as u32;
    doc.get_pages()
        .get(&page_number)
        .copied()
        .ok_or_else(|| Error::PageOutOfRange(page_index, doc.get_pages().len()))
}

fn rect_to_array(r: [f64; 4]) -> Vec<Object> {
    r.iter().map(|&v| Object::Real(v as f32)).collect()
}

fn push_annot_ref(doc: &mut Document, page_id: ObjectId, annot_id: ObjectId) -> Result<()> {
    let page_obj = doc
        .get_object_mut(page_id)
        .map_err(|e| Error::Parse(e.to_string()))?;
    let dict = page_obj
        .as_dict_mut()
        .map_err(|e| Error::Parse(e.to_string()))?;
    let new_ref = Object::Reference(annot_id);
    match dict.get_mut(b"Annots") {
        Ok(Object::Array(arr)) => {
            arr.push(new_ref);
        }
        _ => {
            dict.set(b"Annots", Object::Array(vec![new_ref]));
        }
    }
    Ok(())
}

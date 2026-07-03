//! Document editing: page manipulation, watermarks, metadata updates, form fill, merge/split.

use crate::error::{Error, Result};
use lopdf::{Document, Object, ObjectId};

// ─────────────────────────────────────────────────────────────────────────────
// Page manipulation
// ─────────────────────────────────────────────────────────────────────────────

/// Remove a page (0-based index) from the document.
pub fn remove_page(doc: &mut Document, page_index: usize) -> Result<()> {
    let total = doc.get_pages().len();
    if page_index >= total {
        return Err(Error::PageOutOfRange(page_index, total));
    }
    doc.delete_pages(&[(page_index + 1) as u32]);
    Ok(())
}

/// Rotate a page by `degrees` (must be 0, 90, 180, or 270).
pub fn rotate_page(doc: &mut Document, page_index: usize, degrees: i64) -> Result<()> {
    if !matches!(degrees, 0 | 90 | 180 | 270) {
        return Err(Error::Internal(
            "rotation must be 0, 90, 180, or 270".into(),
        ));
    }
    let page_id = get_page_id(doc, page_index)?;
    let page_obj = doc
        .get_object_mut(page_id)
        .map_err(|e| Error::Parse(e.to_string()))?;
    let dict = page_obj
        .as_dict_mut()
        .map_err(|e| Error::Parse(e.to_string()))?;
    let existing = match dict.get(b"Rotate") {
        Ok(Object::Integer(n)) => *n,
        _ => 0,
    };
    dict.set(b"Rotate", Object::Integer((existing + degrees) % 360));
    Ok(())
}

/// Reorder all pages according to `new_order` (slice of 0-based page indices).
/// `new_order` must contain every page index exactly once.
pub fn reorder_pages(doc: &mut Document, new_order: &[usize]) -> Result<()> {
    let total = doc.get_pages().len();
    if new_order.len() != total {
        return Err(Error::Internal(format!(
            "new_order has {} entries but document has {total} pages",
            new_order.len()
        )));
    }
    let pages_map = doc.get_pages();
    let ordered: Vec<ObjectId> = new_order
        .iter()
        .map(|&idx| {
            pages_map
                .get(&((idx + 1) as u32))
                .copied()
                .ok_or(Error::PageOutOfRange(idx, total))
        })
        .collect::<Result<Vec<_>>>()?;

    // Rebuild Kids array in Pages node
    let root_id = doc
        .trailer
        .get(b"Root")
        .and_then(|o| o.as_reference())
        .map_err(|e| Error::Parse(e.to_string()))?;
    let catalog = doc
        .get_object(root_id)?
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?
        .clone();
    let pages_id = catalog
        .get(b"Pages")
        .and_then(|o| o.as_reference())
        .map_err(|e| Error::Parse(e.to_string()))?;

    let kids: Vec<Object> = ordered.iter().map(|id| Object::Reference(*id)).collect();
    let pages_obj = doc
        .get_object_mut(pages_id)
        .map_err(|e| Error::Parse(e.to_string()))?;
    let pages_dict = pages_obj
        .as_dict_mut()
        .map_err(|e| Error::Parse(e.to_string()))?;
    pages_dict.set(b"Kids", Object::Array(kids));
    Ok(())
}

/// Extract a subset of pages into a new `Document`.
/// `range` is an inclusive range of 0-based page indices.
pub fn extract_page_range(doc: &Document, from: usize, to: usize) -> Result<Document> {
    let total = doc.get_pages().len();
    if from > to || to >= total {
        return Err(Error::PageOutOfRange(to, total));
    }
    let mut new_doc = doc.clone();
    // Delete pages outside range (delete from end to avoid index shifts)
    let to_delete: Vec<u32> = (0..total)
        .filter(|&i| i < from || i > to)
        .map(|i| (i + 1) as u32)
        .rev()
        .collect();
    new_doc.delete_pages(&to_delete);
    new_doc.renumber_objects();
    Ok(new_doc)
}

/// Merge `other` document into `doc` by appending all of its pages.
pub fn merge_documents(doc: &mut Document, other: &Document) -> Result<()> {
    // Manually import all objects from `other` into `doc` with ID remapping
    let offset = doc.max_id + 1;
    for (&(id, gen), obj) in &other.objects {
        let new_id = (id + offset, gen);
        doc.objects.insert(new_id, obj.clone());
    }
    doc.max_id += other.max_id + 1;
    // Rebuild page tree by appending other's pages
    let root_id = doc
        .trailer
        .get(b"Root")
        .and_then(|o| o.as_reference())
        .map_err(|e| Error::Parse(e.to_string()))?;
    let catalog = doc
        .get_object(root_id)?
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?
        .clone();
    let pages_id = catalog
        .get(b"Pages")
        .and_then(|o| o.as_reference())
        .map_err(|e| Error::Parse(e.to_string()))?;

    let other_pages = other.get_pages();
    let mut other_sorted: Vec<(u32, lopdf::ObjectId)> = other_pages.into_iter().collect();
    other_sorted.sort_by_key(|(n, _)| *n);

    let pages_obj = doc
        .get_object_mut(pages_id)
        .map_err(|e| Error::Parse(e.to_string()))?;
    let pages_dict = pages_obj
        .as_dict_mut()
        .map_err(|e| Error::Parse(e.to_string()))?;
    let count = match pages_dict.get(b"Count") {
        Ok(Object::Integer(n)) => *n,
        _ => 0,
    };
    if let Ok(Object::Array(kids)) = pages_dict.get_mut(b"Kids") {
        for (_, page_id) in &other_sorted {
            kids.push(Object::Reference((page_id.0 + offset, page_id.1)));
        }
    }
    pages_dict.set(b"Count", Object::Integer(count + other_sorted.len() as i64));
    doc.renumber_objects();
    Ok(())
}

// ─────────────────────────────────────────────────────────────────────────────
// Watermarks
// ─────────────────────────────────────────────────────────────────────────────

/// Stamp a diagonal text watermark on every page.
///
/// `font_size` defaults to 48.0 if `None`.  
/// `opacity` is 0.0–1.0, defaults to 0.3.
pub fn watermark_text(
    doc: &mut Document,
    text: &str,
    font_size: Option<f64>,
    opacity: Option<f64>,
) -> Result<()> {
    let size = font_size.unwrap_or(48.0);
    let alpha = opacity.unwrap_or(0.3).clamp(0.0, 1.0);
    let pages: Vec<(u32, ObjectId)> = doc.get_pages().into_iter().collect();

    for (_, page_id) in &pages {
        stamp_text_on_page(doc, *page_id, text, size, alpha)?;
    }
    Ok(())
}

fn stamp_text_on_page(
    doc: &mut Document,
    page_id: ObjectId,
    text: &str,
    size: f64,
    alpha: f64,
) -> Result<()> {
    // Get page dimensions from MediaBox
    let (pw, ph) = {
        let page_obj = doc
            .get_object(page_id)
            .map_err(|e| Error::Parse(e.to_string()))?;
        let dict = page_obj
            .as_dict()
            .map_err(|e| Error::Parse(e.to_string()))?;
        let mb = match dict.get(b"MediaBox") {
            Ok(Object::Array(a)) => a.clone(),
            _ => vec![
                Object::Integer(0),
                Object::Integer(0),
                Object::Integer(612),
                Object::Integer(792),
            ],
        };
        let w = obj_f64(mb.get(2)).unwrap_or(612.0);
        let h = obj_f64(mb.get(3)).unwrap_or(792.0);
        (w, h)
    };

    // Build a very small content stream that draws rotated text at page centre
    let cx = pw / 2.0;
    let cy = ph / 2.0;
    let escaped = escape_pdf_string(text);
    let stream_bytes = format!(
        "q\n\
         /GS_WM gs\n\
         BT\n\
         /Helvetica {size:.1} Tf\n\
         {alpha:.3} {alpha:.3} {alpha:.3} rg\n\
         {cos:.6} {sin:.6} -{sin:.6} {cos:.6} {cx:.2} {cy:.2} Tm\n\
         ({escaped}) Tj\n\
         ET\n\
         Q\n",
        cos = 0.7071_f64,
        sin = 0.7071_f64,
    );

    // Register a graphics state with alpha (ExtGState)
    let gs_id = doc.new_object_id();
    let gs_dict = lopdf::Dictionary::from_iter(vec![
        (b"Type".to_vec(), Object::Name(b"ExtGState".to_vec())),
        (b"ca".to_vec(), Object::Real(alpha as f32)),
        (b"CA".to_vec(), Object::Real(alpha as f32)),
    ]);
    doc.objects.insert(gs_id, Object::Dictionary(gs_dict));

    // Add stream object
    let stream_id = doc.new_object_id();
    let mut stream_dict = lopdf::Dictionary::new();
    stream_dict.set(b"Length", Object::Integer(stream_bytes.len() as i64));
    doc.objects.insert(
        stream_id,
        Object::Stream(lopdf::Stream::new(stream_dict, stream_bytes.into_bytes())),
    );

    // Merge into page resources and append to Contents
    {
        let page_obj = doc
            .get_object_mut(page_id)
            .map_err(|e| Error::Parse(e.to_string()))?;
        let page_dict = page_obj
            .as_dict_mut()
            .map_err(|e| Error::Parse(e.to_string()))?;

        // Resources > ExtGState > GS_WM
        let res_entry = page_dict.get_mut(b"Resources");
        if let Ok(Object::Dictionary(res)) = res_entry {
            match res.get_mut(b"ExtGState") {
                Ok(Object::Dictionary(eg)) => {
                    eg.set(b"GS_WM", Object::Reference(gs_id));
                }
                _ => {
                    let mut eg = lopdf::Dictionary::new();
                    eg.set(b"GS_WM", Object::Reference(gs_id));
                    res.set(b"ExtGState", Object::Dictionary(eg));
                }
            }
            match res.get_mut(b"Font") {
                Ok(Object::Dictionary(fd)) => {
                    fd.set(b"Helvetica", make_helvetica_font_dict());
                }
                _ => {
                    let mut fd = lopdf::Dictionary::new();
                    fd.set(b"Helvetica", make_helvetica_font_dict());
                    res.set(b"Font", Object::Dictionary(fd));
                }
            }
        } else {
            let mut eg = lopdf::Dictionary::new();
            eg.set(b"GS_WM", Object::Reference(gs_id));
            let mut fd = lopdf::Dictionary::new();
            fd.set(b"Helvetica", make_helvetica_font_dict());
            let mut new_res = lopdf::Dictionary::new();
            new_res.set(b"ExtGState", Object::Dictionary(eg));
            new_res.set(b"Font", Object::Dictionary(fd));
            page_dict.set(b"Resources", Object::Dictionary(new_res));
        }

        // Append to Contents
        let new_ref = Object::Reference(stream_id);
        match page_dict.get_mut(b"Contents") {
            Ok(Object::Array(arr)) => {
                arr.push(new_ref);
            }
            Ok(Object::Reference(existing_id)) => {
                let eid = *existing_id;
                page_dict.set(
                    b"Contents",
                    Object::Array(vec![Object::Reference(eid), new_ref]),
                );
            }
            _ => {
                page_dict.set(b"Contents", Object::Array(vec![new_ref]));
            }
        }
    }
    Ok(())
}

fn make_helvetica_font_dict() -> Object {
    Object::Dictionary(lopdf::Dictionary::from_iter(vec![
        (b"Type".to_vec(), Object::Name(b"Font".to_vec())),
        (b"Subtype".to_vec(), Object::Name(b"Type1".to_vec())),
        (b"BaseFont".to_vec(), Object::Name(b"Helvetica".to_vec())),
    ]))
}

fn escape_pdf_string(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('(', "\\(")
        .replace(')', "\\)")
}

// ─────────────────────────────────────────────────────────────────────────────
// Inject plain text onto a page
// ─────────────────────────────────────────────────────────────────────────────

/// Inject a single line of text onto a page at position (x, y) from bottom-left.
pub fn inject_text(
    doc: &mut Document,
    page_index: usize,
    text: &str,
    x: f64,
    y: f64,
    font_size: f64,
) -> Result<()> {
    let page_id = get_page_id(doc, page_index)?;
    let escaped = escape_pdf_string(text);
    let stream_bytes =
        format!("q\nBT\n/Helvetica {font_size:.1} Tf\n{x:.2} {y:.2} Td\n({escaped}) Tj\nET\nQ\n");
    let stream_id = doc.new_object_id();
    let mut sd = lopdf::Dictionary::new();
    sd.set(b"Length", Object::Integer(stream_bytes.len() as i64));
    doc.objects.insert(
        stream_id,
        Object::Stream(lopdf::Stream::new(sd, stream_bytes.into_bytes())),
    );

    let page_obj = doc
        .get_object_mut(page_id)
        .map_err(|e| Error::Parse(e.to_string()))?;
    let page_dict = page_obj
        .as_dict_mut()
        .map_err(|e| Error::Parse(e.to_string()))?;

    // Ensure Helvetica is in font resources
    ensure_helvetica_in_resources(page_dict);

    let new_ref = Object::Reference(stream_id);
    match page_dict.get_mut(b"Contents") {
        Ok(Object::Array(arr)) => {
            arr.push(new_ref);
        }
        Ok(Object::Reference(eid)) => {
            let e = *eid;
            page_dict.set(
                b"Contents",
                Object::Array(vec![Object::Reference(e), new_ref]),
            );
        }
        _ => {
            page_dict.set(b"Contents", Object::Array(vec![new_ref]));
        }
    }
    Ok(())
}

fn ensure_helvetica_in_resources(page_dict: &mut lopdf::Dictionary) {
    let font_obj = make_helvetica_font_dict();
    match page_dict.get_mut(b"Resources") {
        Ok(Object::Dictionary(res)) => match res.get_mut(b"Font") {
            Ok(Object::Dictionary(fd)) => {
                fd.set(b"Helvetica", font_obj);
            }
            _ => {
                let mut fd = lopdf::Dictionary::new();
                fd.set(b"Helvetica", font_obj);
                res.set(b"Font", Object::Dictionary(fd));
            }
        },
        _ => {
            let mut fd = lopdf::Dictionary::new();
            fd.set(b"Helvetica", font_obj);
            let mut res = lopdf::Dictionary::new();
            res.set(b"Font", Object::Dictionary(fd));
            page_dict.set(b"Resources", Object::Dictionary(res));
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metadata editing
// ─────────────────────────────────────────────────────────────────────────────

/// Update Info dictionary fields. Pass `None` to leave a field unchanged.
pub fn update_metadata(
    doc: &mut Document,
    title: Option<&str>,
    author: Option<&str>,
    subject: Option<&str>,
    keywords: Option<&str>,
    creator: Option<&str>,
) -> Result<()> {
    // Get or create Info object
    let info_id = match doc.trailer.get(b"Info").and_then(|o| o.as_reference()) {
        Ok(id) => id,
        Err(_) => {
            let new_id = doc.new_object_id();
            doc.objects
                .insert(new_id, Object::Dictionary(lopdf::Dictionary::new()));
            doc.trailer.set(b"Info", Object::Reference(new_id));
            new_id
        }
    };

    let info_obj = doc
        .get_object_mut(info_id)
        .map_err(|e| Error::Parse(e.to_string()))?;
    let dict = info_obj
        .as_dict_mut()
        .map_err(|e| Error::Parse(e.to_string()))?;

    if let Some(v) = title {
        dict.set(b"Title", Object::string_literal(v));
    }
    if let Some(v) = author {
        dict.set(b"Author", Object::string_literal(v));
    }
    if let Some(v) = subject {
        dict.set(b"Subject", Object::string_literal(v));
    }
    if let Some(v) = keywords {
        dict.set(b"Keywords", Object::string_literal(v));
    }
    if let Some(v) = creator {
        dict.set(b"Creator", Object::string_literal(v));
    }

    // Update ModDate
    let now = pdf_date_now();
    dict.set(b"ModDate", Object::string_literal(now.as_str()));
    Ok(())
}

fn pdf_date_now() -> String {
    // Without chrono, use a fixed-format placeholder using std::time
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    // Very rough: days since epoch → yyyy-mm-dd
    let days = secs / 86400;
    let years_since_70 = days / 365;
    let year = 1970 + years_since_70;
    let remaining_days = days % 365;
    let month = (remaining_days / 30).clamp(0, 11) + 1;
    let day = (remaining_days % 30) + 1;
    let hour = (secs % 86400) / 3600;
    let min = (secs % 3600) / 60;
    let sec = secs % 60;
    format!("D:{year:04}{month:02}{day:02}{hour:02}{min:02}{sec:02}Z")
}

// ─────────────────────────────────────────────────────────────────────────────
// Form fill
// ─────────────────────────────────────────────────────────────────────────────

/// Set the value of a named AcroForm field.
pub fn set_field_value(doc: &mut Document, field_name: &str, value: &str) -> Result<()> {
    let catalog_id = doc
        .trailer
        .get(b"Root")
        .and_then(|o| o.as_reference())
        .map_err(|e| Error::Parse(e.to_string()))?;
    let catalog = doc
        .get_object(catalog_id)?
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?
        .clone();

    let acroform_id = match catalog.get(b"AcroForm") {
        Ok(Object::Reference(id)) => *id,
        _ => return Err(Error::ObjectNotFound("AcroForm".into())),
    };
    let acroform = doc
        .get_object(acroform_id)?
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?
        .clone();
    let fields = match acroform.get(b"Fields") {
        Ok(Object::Array(a)) => a.clone(),
        _ => return Err(Error::ObjectNotFound("AcroForm.Fields".into())),
    };

    for field_ref in &fields {
        if let Object::Reference(fid) = field_ref {
            if set_field_recursive(doc, *fid, "", field_name, value)? {
                return Ok(());
            }
        }
    }
    Err(Error::ObjectNotFound(format!("field '{field_name}'")))
}

fn set_field_recursive(
    doc: &mut Document,
    field_id: ObjectId,
    parent_name: &str,
    target: &str,
    value: &str,
) -> Result<bool> {
    let obj = doc
        .get_object(field_id)
        .map_err(|e| Error::Parse(e.to_string()))?
        .clone();
    let dict = obj
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?
        .clone();

    let partial = get_str_from_dict(&dict, b"T").unwrap_or_default();
    let full_name = if parent_name.is_empty() {
        partial.clone()
    } else {
        format!("{parent_name}.{partial}")
    };

    // Recurse into kids
    if let Ok(Object::Array(kids)) = dict.get(b"Kids") {
        let kids = kids.clone();
        for kid in &kids {
            if let Object::Reference(kid_id) = kid {
                if set_field_recursive(doc, *kid_id, &full_name, target, value)? {
                    return Ok(true);
                }
            }
        }
        return Ok(false);
    }

    if full_name == target {
        let field_obj = doc
            .get_object_mut(field_id)
            .map_err(|e| Error::Parse(e.to_string()))?;
        let fd = field_obj
            .as_dict_mut()
            .map_err(|e| Error::Parse(e.to_string()))?;
        fd.set(b"V", Object::string_literal(value));
        return Ok(true);
    }
    Ok(false)
}

fn get_str_from_dict(dict: &lopdf::Dictionary, key: &[u8]) -> Option<String> {
    match dict.get(key).ok()? {
        Object::String(b, _) => Some(String::from_utf8_lossy(b).into_owned()),
        Object::Name(b) => Some(String::from_utf8_lossy(b).into_owned()),
        _ => None,
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

fn get_page_id(doc: &Document, page_index: usize) -> Result<ObjectId> {
    let n = (page_index + 1) as u32;
    doc.get_pages()
        .get(&n)
        .copied()
        .ok_or_else(|| Error::PageOutOfRange(page_index, doc.get_pages().len()))
}

fn obj_f64(o: Option<&Object>) -> Option<f64> {
    match o? {
        Object::Integer(n) => Some(*n as f64),
        Object::Real(f) => Some(*f as f64),
        _ => None,
    }
}

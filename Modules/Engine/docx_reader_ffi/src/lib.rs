#![allow(non_snake_case)]

use docs_engine::{
    apply_document_edit, Block, BlockType, Document, DocumentEdit, DocumentEditOutcome,
    InlineStyle, TextSpan,
};
use serde::Serialize;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_uchar, c_ulonglong};

fn string_to_raw(value: impl Into<String>) -> *mut c_char {
    CString::new(value.into())
        .map(CString::into_raw)
        .unwrap_or(std::ptr::null_mut())
}

fn json_to_raw<T: Serialize>(value: &T) -> *mut c_char {
    match serde_json::to_string(value) {
        Ok(json) => string_to_raw(json),
        Err(_) => std::ptr::null_mut(),
    }
}

fn read_c_string(ptr: *const c_char) -> Option<String> {
    if ptr.is_null() {
        return None;
    }
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .ok()
        .map(str::to_owned)
}

// ============================================================================
// Version and Memory Management
// ============================================================================

#[no_mangle]
pub extern "C" fn docs_engine_version() -> *mut c_char {
    string_to_raw("docs_engine v0.1.0")
}

#[no_mangle]
pub extern "C" fn docs_engine_free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(s));
    }
}

#[no_mangle]
pub extern "C" fn docs_engine_free_document(doc: *mut Document) {
    if doc.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(doc));
    }
}

// ============================================================================
// Document Creation and Serialization
// ============================================================================

#[no_mangle]
pub extern "C" fn create_document(title_ptr: *const c_char) -> *mut Document {
    let title = read_c_string(title_ptr).unwrap_or_else(|| "Untitled".to_string());
    Box::into_raw(Box::new(Document::new(title)))
}

#[no_mangle]
pub extern "C" fn serialize_document(doc_ptr: *const Document) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let doc = unsafe { &*doc_ptr };
    json_to_raw(doc)
}

#[no_mangle]
pub extern "C" fn deserialize_document(json_ptr: *const c_char) -> *mut Document {
    let Some(json) = read_c_string(json_ptr) else {
        return std::ptr::null_mut();
    };

    match serde_json::from_str::<Document>(&json) {
        Ok(doc) => Box::into_raw(Box::new(doc)),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn document_to_json(doc_ptr: *const Document) -> *mut c_char {
    serialize_document(doc_ptr)
}

#[no_mangle]
pub extern "C" fn document_from_json(json_ptr: *const c_char) -> *mut Document {
    deserialize_document(json_ptr)
}

// ============================================================================
// Block Operations
// ============================================================================

#[no_mangle]
pub extern "C" fn add_paragraph(
    doc_ptr: *mut Document,
    text_ptr: *const c_char,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let text = read_c_string(text_ptr).unwrap_or_default();

    let doc = unsafe { &mut *doc_ptr };
    let mut block = Block::new(uuid::Uuid::new_v4().to_string(), BlockType::Paragraph);
    block.add_span(text, InlineStyle::default());
    let index = doc.blocks.len();
    doc.add_block(block);
    index as c_int
}

#[no_mangle]
pub extern "C" fn add_heading(
    doc_ptr: *mut Document,
    text_ptr: *const c_char,
    level: c_uchar,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let text = read_c_string(text_ptr).unwrap_or_default();
    let level = level.min(6); // Max heading level is 6

    let doc = unsafe { &mut *doc_ptr };
    let mut block = Block::new(uuid::Uuid::new_v4().to_string(), BlockType::Heading(level));
    block.add_span(text, InlineStyle::default());
    let index = doc.blocks.len();
    doc.add_block(block);
    index as c_int
}

#[no_mangle]
pub extern "C" fn add_list_item(
    doc_ptr: *mut Document,
    text_ptr: *const c_char,
    indent_level: c_uchar,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let text = read_c_string(text_ptr).unwrap_or_default();

    let doc = unsafe { &mut *doc_ptr };
    let mut block = Block::new(
        uuid::Uuid::new_v4().to_string(),
        BlockType::ListItem(indent_level),
    );
    block.add_span(text, InlineStyle::default());
    let index = doc.blocks.len();
    doc.add_block(block);
    index as c_int
}

#[no_mangle]
pub extern "C" fn add_code_block(
    doc_ptr: *mut Document,
    code_ptr: *const c_char,
    language_ptr: *const c_char,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let code = read_c_string(code_ptr).unwrap_or_default();
    let language = read_c_string(language_ptr).unwrap_or_else(|| "text".to_string());

    let doc = unsafe { &mut *doc_ptr };
    let mut block = Block::new(
        uuid::Uuid::new_v4().to_string(),
        BlockType::CodeBlock(language),
    );
    block.add_span(code, InlineStyle::default());
    let index = doc.blocks.len();
    doc.add_block(block);
    index as c_int
}

#[no_mangle]
pub extern "C" fn add_quote(
    doc_ptr: *mut Document,
    text_ptr: *const c_char,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let text = read_c_string(text_ptr).unwrap_or_default();

    let doc = unsafe { &mut *doc_ptr };
    let mut block = Block::new(uuid::Uuid::new_v4().to_string(), BlockType::Quote);
    block.add_span(text, InlineStyle::default());
    let index = doc.blocks.len();
    doc.add_block(block);
    index as c_int
}

#[no_mangle]
pub extern "C" fn delete_block(doc_ptr: *mut Document, block_index: c_int) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let doc = unsafe { &mut *doc_ptr };
    let index = block_index as usize;

    if index >= doc.blocks.len() {
        return -2;
    }

    doc.blocks.remove(index);
    0
}

// ============================================================================
// Text Editing Operations
// ============================================================================

#[no_mangle]
pub extern "C" fn insert_text(
    doc_ptr: *mut Document,
    block_index: c_int,
    span_index: c_int,
    char_offset: c_int,
    text_ptr: *const c_char,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let text = read_c_string(text_ptr).unwrap_or_default();
    let doc = unsafe { &mut *doc_ptr };

    match doc.insert_text(
        block_index as usize,
        span_index as usize,
        char_offset as usize,
        &text,
    ) {
        Ok(_) => 0,
        Err(_) => -2,
    }
}

#[no_mangle]
pub extern "C" fn split_block(
    doc_ptr: *mut Document,
    block_index: c_int,
    span_index: c_int,
    char_offset: c_int,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let doc = unsafe { &mut *doc_ptr };

    match doc.split_block(
        block_index as usize,
        span_index as usize,
        char_offset as usize,
    ) {
        Ok(_) => 0,
        Err(_) => -2,
    }
}

// ============================================================================
// High-level Edit Operations (CRDT-compatible)
// ============================================================================

#[no_mangle]
pub extern "C" fn apply_insert_text_edit(
    doc_ptr: *mut Document,
    block_index: c_ulonglong,
    span_index: c_ulonglong,
    char_offset: c_ulonglong,
    text_ptr: *const c_char,
) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let text = read_c_string(text_ptr).unwrap_or_default();
    let doc = unsafe { &mut *doc_ptr };

    let edit = DocumentEdit::InsertText {
        block_index: block_index as usize,
        span_index: span_index as usize,
        char_offset: char_offset as usize,
        text,
    };

    match apply_document_edit(doc, edit) {
        Ok(outcome) => json_to_raw(&outcome),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn apply_split_block_edit(
    doc_ptr: *mut Document,
    block_index: c_ulonglong,
    span_index: c_ulonglong,
    char_offset: c_ulonglong,
) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let doc = unsafe { &mut *doc_ptr };

    let edit = DocumentEdit::SplitBlock {
        block_index: block_index as usize,
        span_index: span_index as usize,
        char_offset: char_offset as usize,
    };

    match apply_document_edit(doc, edit) {
        Ok(outcome) => json_to_raw(&outcome),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn apply_add_block_edit(
    doc_ptr: *mut Document,
    block_json_ptr: *const c_char,
) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let Some(block_json) = read_c_string(block_json_ptr) else {
        return std::ptr::null_mut();
    };

    let block: Block = match serde_json::from_str(&block_json) {
        Ok(b) => b,
        Err(_) => return std::ptr::null_mut(),
    };

    let doc = unsafe { &mut *doc_ptr };
    let edit = DocumentEdit::AddBlock { block };

    match apply_document_edit(doc, edit) {
        Ok(outcome) => json_to_raw(&outcome),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn apply_delete_block_edit(
    doc_ptr: *mut Document,
    block_index: c_ulonglong,
) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let doc = unsafe { &mut *doc_ptr };

    let edit = DocumentEdit::DeleteBlock {
        block_index: block_index as usize,
    };

    match apply_document_edit(doc, edit) {
        Ok(outcome) => json_to_raw(&outcome),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn apply_replace_block_edit(
    doc_ptr: *mut Document,
    block_index: c_ulonglong,
    block_json_ptr: *const c_char,
) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let Some(block_json) = read_c_string(block_json_ptr) else {
        return std::ptr::null_mut();
    };

    let block: Block = match serde_json::from_str(&block_json) {
        Ok(b) => b,
        Err(_) => return std::ptr::null_mut(),
    };

    let doc = unsafe { &mut *doc_ptr };
    let edit = DocumentEdit::ReplaceBlock {
        block_index: block_index as usize,
        block,
    };

    match apply_document_edit(doc, edit) {
        Ok(outcome) => json_to_raw(&outcome),
        Err(_) => std::ptr::null_mut(),
    }
}

// ============================================================================
// Block Query Operations
// ============================================================================

#[no_mangle]
pub extern "C" fn get_block_count(doc_ptr: *const Document) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let doc = unsafe { &*doc_ptr };
    doc.blocks.len() as c_int
}

#[no_mangle]
pub extern "C" fn get_block_json(
    doc_ptr: *const Document,
    block_index: c_int,
) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let doc = unsafe { &*doc_ptr };
    let index = block_index as usize;

    match doc.blocks.get(index) {
        Some(block) => json_to_raw(block),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn get_document_title(doc_ptr: *const Document) -> *mut c_char {
    if doc_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let doc = unsafe { &*doc_ptr };
    string_to_raw(&doc.title)
}

#[no_mangle]
pub extern "C" fn set_document_title(
    doc_ptr: *mut Document,
    title_ptr: *const c_char,
) -> c_int {
    if doc_ptr.is_null() {
        return -1;
    }
    let title = read_c_string(title_ptr).unwrap_or_default();
    let doc = unsafe { &mut *doc_ptr };
    doc.title = title;
    0
}

// ============================================================================
// Safety Notes:
// - Callers must free returned strings with `docs_engine_free_string`
// - Callers must free documents with `docs_engine_free_document`
// - All pointers passed from Dart must remain valid for the duration of the call
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    fn take_string(ptr: *mut c_char) -> String {
        assert!(!ptr.is_null());
        let value = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_owned();
        docs_engine_free_string(ptr);
        value
    }

    #[test]
    fn test_create_and_serialize_document() {
        let title = CString::new("Test Document").unwrap();
        let doc_ptr = create_document(title.as_ptr());
        assert!(!doc_ptr.is_null());

        let json_ptr = serialize_document(doc_ptr);
        let json = take_string(json_ptr);

        assert!(json.contains("\"title\":\"Test Document\""));
        assert!(json.contains("\"blocks\":[]"));

        docs_engine_free_document(doc_ptr);
    }

    #[test]
    fn test_add_paragraph_and_insert_text() {
        let title = CString::new("Draft").unwrap();
        let doc_ptr = create_document(title.as_ptr());

        let text = CString::new("Hello").unwrap();
        let index = add_paragraph(doc_ptr, text.as_ptr());
        assert_eq!(index, 0);

        let insert_text = CString::new(" World").unwrap();
        let result = insert_text(doc_ptr, 0, 0, 5, insert_text.as_ptr());
        assert_eq!(result, 0);

        let json_ptr = serialize_document(doc_ptr);
        let json = take_string(json_ptr);
        assert!(json.contains("Hello World"));

        docs_engine_free_document(doc_ptr);
    }

    #[test]
    fn test_split_block() {
        let title = CString::new("Draft").unwrap();
        let doc_ptr = create_document(title.as_ptr());

        let text = CString::new("Hello World").unwrap();
        add_paragraph(doc_ptr, text.as_ptr());

        let result = split_block(doc_ptr, 0, 0, 6);
        assert_eq!(result, 0);

        let count = get_block_count(doc_ptr);
        assert_eq!(count, 2);

        docs_engine_free_document(doc_ptr);
    }

    #[test]
    fn test_add_heading_and_list_item() {
        let title = CString::new("Draft").unwrap();
        let doc_ptr = create_document(title.as_ptr());

        let heading_text = CString::new("My Heading").unwrap();
        add_heading(doc_ptr, heading_text.as_ptr(), 1);

        let list_text = CString::new("List item").unwrap();
        add_list_item(doc_ptr, list_text.as_ptr(), 0);

        let count = get_block_count(doc_ptr);
        assert_eq!(count, 2);

        let block0_json_ptr = get_block_json(doc_ptr, 0);
        let block0_json = take_string(block0_json_ptr);
        assert!(block0_json.contains("Heading(1)"));

        let block1_json_ptr = get_block_json(doc_ptr, 1);
        let block1_json = take_string(block1_json_ptr);
        assert!(block1_json.contains("ListItem(0)"));

        docs_engine_free_document(doc_ptr);
    }

    #[test]
    fn test_apply_insert_text_edit_returns_outcome() {
        let title = CString::new("Draft").unwrap();
        let doc_ptr = create_document(title.as_ptr());

        let text = CString::new("Hello").unwrap();
        add_paragraph(doc_ptr, text.as_ptr());

        let insert_text = CString::new(" World").unwrap();
        let outcome_ptr = apply_insert_text_edit(doc_ptr, 0, 0, 5, insert_text.as_ptr());
        assert!(!outcome_ptr.is_null());

        let outcome_json = take_string(outcome_ptr);
        assert!(outcome_json.contains("\"changed_blocks\":[0]"));

        docs_engine_free_document(doc_ptr);
    }

    #[test]
    fn test_document_json_roundtrip() {
        let title = CString::new("Roundtrip Test").unwrap();
        let doc_ptr = create_document(title.as_ptr());

        let text = CString::new("Test content").unwrap();
        add_paragraph(doc_ptr, text.as_ptr());

        let json_ptr = document_to_json(doc_ptr);
        let json = take_string(json_ptr);

        let json_cstring = CString::new(json).unwrap();
        let restored_doc_ptr = document_from_json(json_cstring.as_ptr());
        assert!(!restored_doc_ptr.is_null());

        let restored_title_ptr = get_document_title(restored_doc_ptr);
        let restored_title = take_string(restored_title_ptr);
        assert_eq!(restored_title, "Roundtrip Test");

        let count = get_block_count(restored_doc_ptr);
        assert_eq!(count, 1);

        docs_engine_free_document(doc_ptr);
        docs_engine_free_document(restored_doc_ptr);
    }
}
//! FFI bindings for DOCX parser integration with ky_docs Flutter plugin
//!
//! This crate provides C-compatible functions for parsing DOCX files
//! and converting them to the document engine's block format.

use docx_reader::{DocxReader, Document as DocxDocument, Block as DocxBlock, Paragraph, Run};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_uchar, c_ulonglong};
use std::slice;
use serde::Serialize;

// ============================================================================
// Helper Functions
// ============================================================================

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
// Parsed Document Structure for Engine
// ============================================================================

/// Intermediate representation of parsed DOCX content
#[derive(Debug, Clone, Serialize)]
pub struct ParsedDocxContent {
    pub title: String,
    pub author: Option<String>,
    pub blocks: Vec<EngineBlock>,
    pub metadata: DocxMetadata,
}

#[derive(Debug, Clone, Serialize)]
pub struct EngineBlock {
    pub block_type: String,
    pub text: String,
    pub level: Option<u8>,
    pub styles: Vec<EngineStyle>,
    pub list_info: Option<EngineListInfo>,
}

#[derive(Debug, Clone, Serialize)]
pub struct EngineStyle {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub font_size: Option<f32>,
    pub font_family: Option<String>,
    pub color: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct EngineListInfo {
    pub is_ordered: bool,
    pub level: u8,
}

#[derive(Debug, Clone, Default, Serialize)]
pub struct DocxMetadata {
    pub subject: Option<String>,
    pub keywords: Option<String>,
    pub created: Option<String>,
    pub modified: Option<String>,
    pub word_count: Option<u32>,
    pub character_count: Option<u32>,
}

// ============================================================================
// Version and Memory Management
// ============================================================================

#[no_mangle]
pub extern "C" fn docx_parser_version() -> *mut c_char {
    string_to_raw("ky-docs-parser-ffi v0.1.0")
}

#[no_mangle]
pub extern "C" fn docx_parser_free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(s));
    }
}

#[no_mangle]
pub extern "C" fn docx_parser_free_parsed_content(content: *mut ParsedDocxContent) {
    if content.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(content));
    }
}

// ============================================================================
// DOCX Parsing from Byte Array
// ============================================================================

/// Parse DOCX file from byte array
/// 
/// # Safety
/// - `data` must point to a valid memory region of `len` bytes
/// - Caller is responsible for freeing the returned ParsedDocxContent
#[no_mangle]
pub extern "C" fn parse_docx_from_bytes(
    data: *const c_uchar,
    len: c_ulonglong,
) -> *mut ParsedDocxContent {
    if data.is_null() || len == 0 {
        return std::ptr::null_mut();
    }

    let bytes = unsafe { slice::from_raw_parts(data, len as usize) };
    
    // Create temporary file or use in-memory reader
    match DocxReader::from_bytes(bytes.to_vec()) {
        Ok(reader) => {
            match reader.parse() {
                Ok(doc) => Box::into_raw(Box::new(convert_to_engine_format(doc))),
                Err(_) => std::ptr::null_mut(),
            }
        }
        Err(_) => std::ptr::null_mut(),
    }
}

/// Parse DOCX file from path (for desktop platforms)
/// 
/// # Safety
/// - `path` must be a valid null-terminated C string
#[no_mangle]
pub extern "C" fn parse_docx_from_path(path: *const c_char) -> *mut ParsedDocxContent {
    let Some(path_str) = read_c_string(path) else {
        return std::ptr::null_mut();
    };

    match DocxReader::open(&path_str) {
        Ok(reader) => {
            match reader.parse() {
                Ok(doc) => Box::into_raw(Box::new(convert_to_engine_format(doc))),
                Err(_) => std::ptr::null_mut(),
            }
        }
        Err(_) => std::ptr::null_mut(),
    }
}

// ============================================================================
// Conversion Functions
// ============================================================================

fn convert_to_engine_format(doc: DocxDocument) -> ParsedDocxContent {
    let mut blocks = Vec::new();
    
    for block in doc.body {
        if let Some(engine_block) = convert_docx_block(block) {
            blocks.push(engine_block);
        }
    }

    ParsedDocxContent {
        title: doc.metadata.title.unwrap_or_else(|| "Untitled Document".to_string()),
        author: doc.metadata.creator,
        blocks,
        metadata: DocxMetadata {
            subject: doc.metadata.subject,
            keywords: doc.metadata.keywords,
            created: doc.metadata.created,
            modified: doc.metadata.modified,
            word_count: doc.metadata.words,
            character_count: doc.metadata.characters,
        },
    }
}

fn convert_docx_block(block: DocxBlock) -> Option<EngineBlock> {
    match block {
        DocxBlock::Paragraph(para) => Some(convert_paragraph(para)),
        DocxBlock::Table(_) => {
            // TODO: Convert table to engine format
            Some(EngineBlock {
                block_type: "table".to_string(),
                text: "[Table not yet supported]".to_string(),
                level: None,
                styles: vec![],
                list_info: None,
            })
        }
        DocxBlock::SectionBreak => Some(EngineBlock {
            block_type: "section_break".to_string(),
            text: String::new(),
            level: None,
            styles: vec![],
            list_info: None,
        }),
    }
}

fn convert_paragraph(para: Paragraph) -> EngineBlock {
    let text = para.text();
    
    // Determine block type based on heading level or list info
    let (block_type, level) = if let Some(heading_level) = para.heading_level {
        (format!("heading_{}", heading_level), Some(heading_level))
    } else if let Some(list_info) = &para.list_info {
        ("list_item".to_string(), Some(list_info.level))
    } else {
        ("paragraph".to_string(), None)
    };

    // Extract styles from runs
    let styles = para.runs.iter().flat_map(|run| {
        convert_run_styles(run)
    }).collect();

    // Convert list info
    let list_info = para.list_info.map(|li| EngineListInfo {
        is_ordered: li.is_ordered,
        level: li.level,
    });

    EngineBlock {
        block_type,
        text,
        level,
        styles,
        list_info,
    }
}

fn convert_run_styles(run: &Run) -> Vec<EngineStyle> {
    let mut styles = Vec::new();
    
    // Check if run has any formatting
    if run.is_bold() || run.is_italic() || run.is_underline() {
        styles.push(EngineStyle {
            bold: run.is_bold(),
            italic: run.is_italic(),
            underline: run.is_underline(),
            font_size: run.font_size().map(|s| s as f32),
            font_family: run.font_family().map(String::from),
            color: run.color().map(|c| format!("{:06X}", c)),
        });
    }
    
    styles
}

// ============================================================================
// Export Functions
// ============================================================================

/// Get JSON representation of parsed content
#[no_mangle]
pub extern "C" fn parsed_content_to_json(content: *const ParsedDocxContent) -> *mut c_char {
    if content.is_null() {
        return std::ptr::null_mut();
    }
    
    let content_ref = unsafe { &*content };
    json_to_raw(content_ref)
}

/// Get block count from parsed content
#[no_mangle]
pub extern "C" fn parsed_content_block_count(content: *const ParsedDocxContent) -> usize {
    if content.is_null() {
        return 0;
    }
    
    unsafe { &*content }.blocks.len()
}

/// Get title from parsed content
#[no_mangle]
pub extern "C" fn parsed_content_title(content: *const ParsedDocxContent) -> *mut c_char {
    if content.is_null() {
        return std::ptr::null_mut();
    }
    
    string_to_raw(unsafe { &*content }.title.clone())
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version_string() {
        let version_ptr = docx_parser_version();
        assert!(!version_ptr.is_null());
        
        unsafe {
            let version = CStr::from_ptr(version_ptr).to_string_lossy();
            assert!(version.contains("ky-docs-parser-ffi"));
            docx_parser_free_string(version_ptr);
        }
    }
}

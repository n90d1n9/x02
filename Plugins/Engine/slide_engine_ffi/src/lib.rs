#![allow(non_snake_case)]

use serde::Serialize;
use slide_engine::{Geometry, Presentation, Shape, Slide, SlideRenderer, Fill, Stroke, TextBox, TextRun, TextAlign, VerticalAlign};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_double};
use std::io::Read;
use zip::ZipArchive;
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};

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

/// Import PPTX from bytes by parsing the ZIP archive and OpenXML content
fn import_pptx_bytes(bytes: &[u8]) -> Result<Presentation, String> {
    let cursor = std::io::Cursor::new(bytes);
    let mut archive = ZipArchive::new(cursor)
        .map_err(|e| format!("Failed to open PPTX ZIP: {}", e))?;

    let mut presentation = Presentation::new("Imported Presentation");

    // Read presentation.xml to get slide count
    let mut presentation_xml_content = String::new();
    if let Ok(mut file) = archive.by_name("ppt/presentation.xml") {
        file.read_to_string(&mut presentation_xml_content)
            .map_err(|e| format!("Failed to read presentation.xml: {}", e))?;
        
        // Parse slide IDs from presentation.xml
        if let Some(sld_id_lst_start) = presentation_xml_content.find("<p:sldIdLst") {
            if let Some(sld_id_lst_end) = presentation_xml_content[sld_id_lst_start..].find("</p:sldIdLst>") {
                let sld_id_lst = &presentation_xml_content[sld_id_lst_start..sld_id_lst_start + sld_id_lst_end + 13];
                
                // Count sldId elements
                let slide_count = sld_id_lst.matches("<p:sldId").count();
                
                // Create slides
                for i in 0..slide_count {
                    let slide_id = format!("slide_{}", i);
                    let mut slide = Slide::new(&slide_id);
                    
                    // Try to read slide XML
                    let slide_xml_name = format!("ppt/slides/slide{}.xml", i + 1);
                    if let Ok(mut slide_file) = archive.by_name(&slide_xml_name) {
                        let mut slide_xml_content = String::new();
                        if slide_file.read_to_string(&mut slide_xml_content).is_ok() {
                            // Parse shapes from slide XML
                            parse_slide_shapes(&slide_xml_content, &mut slide, &mut archive);
                        }
                    }
                    
                    presentation.add_slide(slide);
                }
            }
        }
    }

    // If no slides found, create a default slide
    if presentation.slides.is_empty() {
        presentation.add_slide(Slide::new("slide_0"));
    }

    Ok(presentation)
}

/// Parse shapes from slide XML content
fn parse_slide_shapes(
    xml_content: &str,
    slide: &mut Slide,
    archive: &mut ZipArchive<std::io::Cursor<&[u8]>>,
) {
    // Simple XML parsing for p:sp (shape) elements
    let mut shape_index = 0;
    let mut search_start = 0;
    
    while let Some(sp_start) = xml_content[search_start..].find("<p:sp") {
        let abs_start = search_start + sp_start;
        
        // Find the end of this shape element (simplified - looks for </p:sp>)
        if let Some(sp_end_rel) = xml_content[abs_start..].find("</p:sp>") {
            let sp_end = abs_start + sp_end_rel + 7;
            let sp_content = &xml_content[abs_start..sp_end];
            
            // Extract shape ID
            let shape_id = format!("shape_{}_{}", slide.id, shape_index);
            
            // Try to extract text content
            let text_content = extract_text_from_shape(sp_content);
            
            // Create a rectangle shape with text
            let mut shape = Shape::rect(
                &shape_id,
                slide_engine::Rect::new(
                    50.0 + (shape_index % 5) as f64 * 120.0,
                    50.0 + (shape_index / 5) as f64 * 80.0,
                    200.0,
                    60.0,
                ),
                "#4472C4",
            );
            
            // Add text box if text was found
            if !text_content.is_empty() {
                shape.text_box = Some(TextBox {
                    runs: vec![TextRun {
                        text: text_content,
                        font_family: Some("Arial".to_string()),
                        font_size: Some(18.0),
                        bold: Some(false),
                        italic: Some(false),
                        underline: Some(false),
                        color: Some("#000000".to_string()),
                    }],
                    align: TextAlign::Left,
                    vertical_align: VerticalAlign::Top,
                });
            }
            
            slide.add_shape(shape);
            shape_index += 1;
        }
        
        search_start = abs_start + 1;
    }
    
    // Also parse p:pic (picture/image) elements
    let mut image_index = 0;
    search_start = 0;
    
    while let Some(pic_start) = xml_content[search_start..].find("<p:pic") {
        let abs_start = search_start + pic_start;
        
        if let Some(pic_end_rel) = xml_content[abs_start..].find("</p:pic>") {
            let pic_end = abs_start + pic_end_rel + 8;
            let pic_content = &xml_content[abs_start..pic_end];
            
            // Extract image relationship ID
            if let Some(embed_start) = pic_content.find("r:embed=\"") {
                let embed_rest = &pic_content[embed_start + 9..];
                if let Some(embed_end) = embed_rest.find('\"') {
                    let rel_id = &embed_rest[..embed_end];
                    
                    // Try to find and load the image
                    if let Some(image_data) = load_image_by_rel_id(rel_id, archive) {
                        let image_id = format!("image_{}_{}", slide.id, image_index);
                        let mut shape = Shape::rect(
                            &image_id,
                            slide_engine::Rect::new(
                                100.0 + image_index as f64 * 150.0,
                                200.0,
                                150.0,
                                100.0,
                            ),
                            "#FFFFFF",
                        );
                        
                        // Set image fill
                        shape.fill = Some(Fill::Picture {
                            data: image_data,
                            content_type: "image/png".to_string(),
                            fit: slide_engine::ImageFit::Contain,
                        });
                        
                        slide.add_shape(shape);
                        image_index += 1;
                    }
                }
            }
        }
        
        search_start = abs_start + 1;
    }
}

/// Extract plain text from shape XML
fn extract_text_from_shape(xml_content: &str) -> String {
    let mut text = String::new();
    let mut search_start = 0;
    
    // Look for <a:t> elements which contain text
    while let Some(t_start) = xml_content[search_start..].find("<a:t>") {
        let abs_start = search_start + t_start;
        let content_start = abs_start + 5;
        
        if let Some(t_end_rel) = xml_content[content_start..].find("</a:t>") {
            let content = &xml_content[content_start..content_start + t_end_rel];
            if !text.is_empty() {
                text.push(' ');
            }
            text.push_str(content.trim());
            search_start = content_start + t_end_rel + 6;
        } else {
            break;
        }
    }
    
    text
}

/// Load image data by relationship ID
fn load_image_by_rel_id(
    rel_id: &str,
    archive: &mut ZipArchive<std::io::Cursor<&[u8]>>,
) -> Option<Vec<u8>> {
    // This is simplified - in a real implementation, we'd parse the .rels files
    // to map relationship IDs to actual image paths
    // For now, try common image paths
    let possible_paths = vec![
        format!("ppt/media/{}", rel_id),
        format!("ppt/media/image{}.png", rel_id.trim_start_matches("rId")),
        format!("ppt/media/image{}.jpeg", rel_id.trim_start_matches("rId")),
        format!("ppt/media/image{}.jpg", rel_id.trim_start_matches("rId")),
    ];
    
    for path in possible_paths {
        if let Ok(mut file) = archive.by_name(&path) {
            let mut data = Vec::new();
            if file.read_to_end(&mut data).is_ok() && !data.is_empty() {
                return Some(data);
            }
        }
    }
    
    None
}

fn render_first_slide_commands(pres: &Presentation) -> *mut c_char {
    let renderer = SlideRenderer::new();
    let cmds = pres
        .slides
        .first()
        .map(|slide| renderer.render(slide))
        .unwrap_or_default();
    json_to_raw(&cmds)
}

#[no_mangle]
pub extern "C" fn slide_engine_version() -> *mut c_char {
    string_to_raw("slide_engine v0.1.0")
}

#[no_mangle]
pub extern "C" fn slide_engine_free_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(s));
    }
}

#[no_mangle]
pub extern "C" fn slide_engine_free_presentation(pres: *mut Presentation) {
    if pres.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(pres));
    }
}

// ---------------------------------------------------------------------
// Presentation <-> JSON
// ---------------------------------------------------------------------
#[no_mangle]
pub extern "C" fn import_pptx_from_bytes(ptr: *const u8, len: usize) -> *mut c_char {
    // Import PPTX from bytes by parsing the ZIP archive and OpenXML content
    if ptr.is_null() && len > 0 {
        return std::ptr::null_mut();
    }
    
    let bytes = if !ptr.is_null() && len > 0 {
        unsafe { std::slice::from_raw_parts(ptr, len) }
    } else {
        &[]
    };
    
    match import_pptx_bytes(bytes) {
        Ok(presentation) => json_to_raw(&presentation),
        Err(e) => {
            eprintln!("PPTX import error: {}", e);
            // Return empty presentation on error to maintain stability
            json_to_raw(&Presentation::default())
        }
    }
}

#[no_mangle]
pub extern "C" fn serialize_presentation(pres_ptr: *const Presentation) -> *mut c_char {
    if pres_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let pres = unsafe { &*pres_ptr };
    json_to_raw(pres)
}

#[no_mangle]
pub extern "C" fn deserialize_presentation(json_ptr: *const c_char) -> *mut Presentation {
    let Some(json) = read_c_string(json_ptr) else {
        return std::ptr::null_mut();
    };

    match serde_json::from_str::<Presentation>(&json) {
        Ok(pres) => Box::into_raw(Box::new(pres)),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn export_presentation_json(pres_ptr: *const Presentation) -> *mut c_char {
    serialize_presentation(pres_ptr)
}

// ---------------------------------------------------------------------
// Shape manipulation
// ---------------------------------------------------------------------
#[no_mangle]
pub extern "C" fn add_shape(pres_ptr: *mut Presentation, shape_json: *const c_char) -> i32 {
    if pres_ptr.is_null() {
        return -1;
    }
    let Some(json) = read_c_string(shape_json) else {
        return -2;
    };
    let shape: Shape = match serde_json::from_str(&json) {
        Ok(shape) => shape,
        Err(_) => return -3,
    };

    // Clone current state before mutation to avoid borrowing conflicts
    let snapshot = unsafe { &*pres_ptr }.clone();
    let pres = unsafe { &mut *pres_ptr };
    pres.history.push_snapshot(&snapshot);

    if pres.slides.is_empty() {
        pres.add_slide(Slide::new("slide_0"));
    }
    if let Some(slide) = pres.slides.first_mut() {
        slide.add_shape(shape);
        0
    } else {
        -4
    }
}

#[no_mangle]
pub extern "C" fn remove_shape(pres_ptr: *mut Presentation, shape_id: *const c_char) -> i32 {
    if pres_ptr.is_null() {
        return -1;
    }
    let Some(id) = read_c_string(shape_id) else {
        return -2;
    };

    // Clone snapshot before mutating
    let snapshot = unsafe { &*pres_ptr }.clone();
    let pres = unsafe { &mut *pres_ptr };
    pres.history.push_snapshot(&snapshot);

    if let Some(slide) = pres.slides.first_mut() {
        slide.remove_shape(&id);
        0
    } else {
        -3
    }
}

#[no_mangle]
pub extern "C" fn move_shape(
    pres_ptr: *mut Presentation,
    shape_id: *const c_char,
    dx: c_double,
    dy: c_double,
) -> *mut c_char {
    if pres_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let Some(id) = read_c_string(shape_id) else {
        return std::ptr::null_mut();
    };

    // Clone snapshot before mutation
    let snapshot = unsafe { &*pres_ptr }.clone();
    let pres = unsafe { &mut *pres_ptr };
    pres.history.push_snapshot(&snapshot);

    if let Some(slide) = pres.slides.first_mut() {
        if let Some(shape) = slide.shapes.get_mut(&id) {
            shape.transform.tx += dx;
            shape.transform.ty += dy;
        }
    }

    render_first_slide_commands(pres)
}

#[no_mangle]
pub extern "C" fn resize_shape(
    pres_ptr: *mut Presentation,
    shape_id: *const c_char,
    dw: c_double,
    dh: c_double,
) -> *mut c_char {
    if pres_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let Some(id) = read_c_string(shape_id) else {
        return std::ptr::null_mut();
    };

    // Clone snapshot before mutation
    let snapshot = unsafe { &*pres_ptr }.clone();
    let pres = unsafe { &mut *pres_ptr };
    pres.history.push_snapshot(&snapshot);

    if let Some(slide) = pres.slides.first_mut() {
        if let Some(shape) = slide.shapes.get_mut(&id) {
            // geometry is not optional; directly modify size if applicable
            if let Geometry::Rectangle { .. } = &mut shape.geometry {
                // Only rectangles have width/height via bounds; adjust bounds instead
                shape.bounds.size.width = (shape.bounds.size.width + dw).max(1.0);
                shape.bounds.size.height = (shape.bounds.size.height + dh).max(1.0);
            } else if let Geometry::Ellipse = &mut shape.geometry {
                // For ellipse, treat similarly using bounds
                shape.bounds.size.width = (shape.bounds.size.width + dw).max(1.0);
                shape.bounds.size.height = (shape.bounds.size.height + dh).max(1.0);
            }
        }
    }

    render_first_slide_commands(pres)
}

#[no_mangle]
pub extern "C" fn update_shape_style(
    pres_ptr: *mut Presentation,
    shape_id: *const c_char,
    style_json: *const c_char,
) -> *mut c_char {
    // Placeholder implementation for updating shape style
    if pres_ptr.is_null() {
        return std::ptr::null_mut();
    }
    let Some(_id) = read_c_string(shape_id) else {
        return std::ptr::null_mut();
    };
    let Some(_json) = read_c_string(style_json) else {
        return std::ptr::null_mut();
    };

    // Clone snapshot before mutation
    let snapshot = unsafe { &*pres_ptr }.clone();
    let pres = unsafe { &mut *pres_ptr };
    pres.history.push_snapshot(&snapshot);

    // TODO: Merge style JSON into shape's fill/stroke/etc.

    render_first_slide_commands(pres)
}

// ---------------------------------------------------------------------
// History manipulation
// ---------------------------------------------------------------------
#[no_mangle]
pub extern "C" fn undo(pres_ptr: *mut Presentation) -> i32 {
    if pres_ptr.is_null() {
        return -1;
    }
    // Clone current state for undo operation
    let snapshot = unsafe { &*pres_ptr }.clone();
    let pres = unsafe { &mut *pres_ptr };
    if let Some(prev) = pres.history.undo(&snapshot) {
        *pres = prev;
        0
    } else {
        1 // nothing to undo
    }
}

#[no_mangle]
pub extern "C" fn redo(pres_ptr: *mut Presentation) -> i32 {
    if pres_ptr.is_null() {
        return -1;
    }
    // Clone current state for redo operation
    let snapshot = unsafe { &*pres_ptr }.clone();
    let pres = unsafe { &mut *pres_ptr };
    if let Some(next) = pres.history.redo(&snapshot) {
        *pres = next;
        0
    } else {
        1 // nothing to redo
    }
}

// ---------------------------------------------------------------------
// Safety: callers must free returned strings with `slide_engine_free_string`
// and presentations with `slide_engine_free_presentation`.
// ---------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;
    use slide_engine::{DrawCommand, Rect};
    use std::ffi::{CStr, CString};

    fn take_string(ptr: *mut c_char) -> String {
        assert!(!ptr.is_null());
        let value = unsafe { CStr::from_ptr(ptr) }.to_str().unwrap().to_owned();
        slide_engine_free_string(ptr);
        value
    }

    #[test]
    fn serialize_and_deserialize_presentation() {
        let mut presentation = Presentation::new("Deck");
        presentation.add_slide(Slide::new("slide-1"));
        let json = serde_json::to_string(&presentation).unwrap();
        let json = CString::new(json).unwrap();

        let ptr = deserialize_presentation(json.as_ptr());
        assert!(!ptr.is_null());

        let exported = take_string(serialize_presentation(ptr));
        assert!(exported.contains("\"title\":\"Deck\""));

        slide_engine_free_presentation(ptr);
    }

    #[test]
    fn add_and_move_shape_returns_render_commands() {
        let mut presentation = Presentation::new("Deck");
        presentation.add_slide(Slide::new("slide-1"));
        let pres_ptr = Box::into_raw(Box::new(presentation));

        let shape = Shape::rect("shape-1", Rect::new(0.0, 0.0, 100.0, 50.0), "#ff0000");
        let shape_json = CString::new(serde_json::to_string(&shape).unwrap()).unwrap();
        assert_eq!(add_shape(pres_ptr, shape_json.as_ptr()), 0);

        let shape_id = CString::new("shape-1").unwrap();
        let commands_json = take_string(move_shape(pres_ptr, shape_id.as_ptr(), 10.0, 20.0));
        let commands: Vec<DrawCommand> = serde_json::from_str(&commands_json).unwrap();

        assert!(commands.iter().any(|cmd| matches!(
            cmd,
            DrawCommand::PushTransform(transform) if transform.tx == 10.0 && transform.ty == 20.0
        )));

        slide_engine_free_presentation(pres_ptr);
    }
}

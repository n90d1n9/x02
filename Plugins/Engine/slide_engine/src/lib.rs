#![allow(non_snake_case)]

use serde::Serialize;
use slide_engine::{Geometry, Presentation, Shape, Slide, SlideRenderer};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_double};

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
    // Placeholder: real import will parse ZIP+XML. Keep the ABI stable and
    // return an empty presentation for now.
    if ptr.is_null() && len > 0 {
        return std::ptr::null_mut();
    }
    json_to_raw(&Presentation::default())
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

//! Optional C-compatible FFI layer (requires `--features ffi`).
//!
//! Compile the crate as `cdylib`, then link against it from C/C++/Python/etc.
//!
//! ```c
//! #include "xlsx_reader.h"
//!
//! XlsxWorkbook *wb = xlsx_open("report.xlsx");
//! int count = xlsx_sheet_count(wb);
//! for (int i = 0; i < count; i++) {
//!     const char *name = xlsx_sheet_name(wb, i);
//!     printf("Sheet %d: %s\n", i, name);
//! }
//! xlsx_close(wb);
//! ```

#![allow(unsafe_code, clippy::missing_safety_doc)]

use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_uint};
use std::ptr;

use crate::workbook::{OpenOptions, Workbook, WorkbookReader};

/// Opaque handle to an open workbook.
pub struct XlsxWorkbook(Workbook);

/// Opaque handle to a sheet (borrowed from a workbook).
pub struct XlsxSheet(*const crate::sheet::Sheet);

// ── Open / Close ──────────────────────────────────────────────────────────────

/// Open a workbook file.  Returns `NULL` on error.
#[no_mangle]
pub unsafe extern "C" fn xlsx_open(path: *const c_char) -> *mut XlsxWorkbook {
    if path.is_null() {
        return ptr::null_mut();
    }
    let path = unsafe { CStr::from_ptr(path) }.to_string_lossy();
    match Workbook::open(path.as_ref()) {
        Ok(wb) => Box::into_raw(Box::new(XlsxWorkbook(wb))),
        Err(e) => {
            log::error!("xlsx_open: {e}");
            ptr::null_mut()
        }
    }
}

/// Free a workbook handle.
#[no_mangle]
pub unsafe extern "C" fn xlsx_close(wb: *mut XlsxWorkbook) {
    if !wb.is_null() {
        unsafe { drop(Box::from_raw(wb)) };
    }
}

// ── Sheet enumeration ─────────────────────────────────────────────────────────

/// Return the number of sheets in the workbook.
#[no_mangle]
pub unsafe extern "C" fn xlsx_sheet_count(wb: *const XlsxWorkbook) -> c_int {
    if wb.is_null() {
        return -1;
    }
    unsafe { (*wb).0.sheet_count() as c_int }
}

/// Return the name of the sheet at `index`.
/// The returned pointer is valid until the workbook is closed.
/// Returns `NULL` if `index` is out of range.
#[no_mangle]
pub unsafe extern "C" fn xlsx_sheet_name(wb: *const XlsxWorkbook, index: c_int) -> *const c_char {
    if wb.is_null() || index < 0 {
        return ptr::null();
    }
    match unsafe { (*wb).0.sheet_by_index(index as usize) } {
        Ok(sheet) => {
            // Leak a CString — caller must NOT free it (lifetime tied to workbook).
            let cs = CString::new(sheet.name()).unwrap_or_default();
            cs.into_raw() as *const c_char
        }
        Err(_) => ptr::null(),
    }
}

/// Get a sheet handle by name.  Returns `NULL` if not found.
#[no_mangle]
pub unsafe extern "C" fn xlsx_get_sheet(
    wb: *const XlsxWorkbook,
    name: *const c_char,
) -> *const XlsxSheet {
    if wb.is_null() || name.is_null() {
        return ptr::null();
    }
    let name = unsafe { CStr::from_ptr(name) }.to_string_lossy();
    match unsafe { (*wb).0.sheet_by_name(&name) } {
        Ok(sheet) => Box::into_raw(Box::new(XlsxSheet(sheet as *const _))),
        Err(_) => ptr::null(),
    }
}

/// Free a sheet handle.
#[no_mangle]
pub unsafe extern "C" fn xlsx_sheet_free(sh: *mut XlsxSheet) {
    if !sh.is_null() {
        unsafe { drop(Box::from_raw(sh)) };
    }
}

// ── Sheet dimensions ──────────────────────────────────────────────────────────

/// Return the row count of the sheet, or 0 on error.
#[no_mangle]
pub unsafe extern "C" fn xlsx_row_count(sh: *const XlsxSheet) -> c_uint {
    if sh.is_null() {
        return 0;
    }
    unsafe { (*(*sh).0).meta().row_count }
}

/// Return the column count of the sheet, or 0 on error.
#[no_mangle]
pub unsafe extern "C" fn xlsx_col_count(sh: *const XlsxSheet) -> c_uint {
    if sh.is_null() {
        return 0;
    }
    unsafe { (*(*sh).0).meta().col_count as c_uint }
}

// ── Cell value retrieval ──────────────────────────────────────────────────────

/// Return the display value of the cell at (`row`, `col`) (0-based).
///
/// Returns an empty string for empty cells, `NULL` on error.
/// The caller is responsible for freeing the returned string with `xlsx_free_string`.
#[no_mangle]
pub unsafe extern "C" fn xlsx_cell_value(
    sh: *const XlsxSheet,
    row: c_uint,
    col: c_uint,
) -> *mut c_char {
    if sh.is_null() {
        return ptr::null_mut();
    }
    let sheet = unsafe { &*(*sh).0 };
    let addr = crate::cell::CellAddress::new(row, col as u16);
    let val = sheet
        .cell(addr)
        .map(|c| c.display_value())
        .unwrap_or_default();
    CString::new(val).unwrap_or_default().into_raw()
}

/// Free a string returned by this library.
#[no_mangle]
pub unsafe extern "C" fn xlsx_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe { drop(CString::from_raw(s)) };
    }
}

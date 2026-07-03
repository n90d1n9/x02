/**
 * xlsx_reader.h — C header for the ky-of-xlsx Rust library FFI layer.
 *
 * Build the library with:
 *   cargo build --release --features ffi
 *
 * Link against:
 *   -L./target/release -lky-of-xlsx
 *
 * Example compile:
 *   gcc main.c -o main -L./target/release -lky-of-xlsx -Wl,-rpath,./target/release
 */

#ifndef XLSX_READER_H
#define XLSX_READER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque handles */
typedef struct XlsxWorkbook XlsxWorkbook;
typedef struct XlsxSheet    XlsxSheet;

/* ── Workbook ──────────────────────────────────────────────────────────────── */

/**
 * Open a workbook file.
 * @param path  Null-terminated UTF-8 file path.
 * @return      Opaque workbook handle, or NULL on error.
 */
XlsxWorkbook *xlsx_open(const char *path);

/**
 * Close and free a workbook handle.
 */
void xlsx_close(XlsxWorkbook *wb);

/**
 * Return the number of sheets in the workbook.
 * @return  Number of sheets, or -1 on error.
 */
int xlsx_sheet_count(const XlsxWorkbook *wb);

/**
 * Return the display name of the sheet at `index` (0-based).
 * The returned pointer is valid until the workbook is closed.
 * @return  Null-terminated UTF-8 name, or NULL if out of range.
 */
const char *xlsx_sheet_name(const XlsxWorkbook *wb, int index);

/* ── Sheet ─────────────────────────────────────────────────────────────────── */

/**
 * Obtain a sheet handle by name.
 * Must be freed with xlsx_sheet_free().
 * @return  Sheet handle, or NULL if not found.
 */
const XlsxSheet *xlsx_get_sheet(const XlsxWorkbook *wb, const char *name);

/**
 * Free a sheet handle.
 */
void xlsx_sheet_free(XlsxSheet *sh);

/**
 * Return the number of non-empty rows in the sheet.
 */
unsigned int xlsx_row_count(const XlsxSheet *sh);

/**
 * Return the maximum column count across all rows in the sheet.
 */
unsigned int xlsx_col_count(const XlsxSheet *sh);

/* ── Cell ──────────────────────────────────────────────────────────────────── */

/**
 * Return the display value of the cell at (row, col) (0-based).
 * The caller is responsible for freeing the result with xlsx_free_string().
 * @return  Null-terminated UTF-8 string, or NULL on error.
 */
char *xlsx_cell_value(const XlsxSheet *sh, unsigned int row, unsigned int col);

/**
 * Free a string returned by xlsx_cell_value().
 */
void xlsx_free_string(char *s);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* XLSX_READER_H */

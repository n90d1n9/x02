use std::fs;
use std::path::Path;

const HEADER: &str = r#"#ifndef WARAQ_SLIDE_ENGINE_FFI_H
#define WARAQ_SLIDE_ENGINE_FFI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Presentation Presentation;

char *slide_engine_version(void);
void slide_engine_free_string(char *s);
void slide_engine_free_presentation(Presentation *pres);

char *import_pptx_from_bytes(const uint8_t *ptr, size_t len);
char *serialize_presentation(const Presentation *pres_ptr);
Presentation *deserialize_presentation(const char *json_ptr);
int32_t add_shape(Presentation *pres_ptr, const char *shape_json);
int32_t remove_shape(Presentation *pres_ptr, const char *shape_id);
char *export_presentation_json(const Presentation *pres_ptr);
char *move_shape(Presentation *pres_ptr, const char *shape_id, double dx, double dy);

#ifdef __cplusplus
}
#endif

#endif
"#;

fn main() {
    println!("cargo:rerun-if-changed=src/lib.rs");
    println!("cargo:rerun-if-changed=build.rs");

    let crate_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let output_path = Path::new(&crate_dir).join("slide_engine_ffi.h");

    let should_write = fs::read_to_string(&output_path)
        .map(|existing| existing != HEADER)
        .unwrap_or(true);

    if should_write {
        fs::write(output_path, HEADER).unwrap();
    }
}

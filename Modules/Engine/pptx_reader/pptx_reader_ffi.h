#ifndef WARAQ_pptx_reader_FFI_H
#define WARAQ_pptx_reader_FFI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Presentation Presentation;

char *pptx_reader_version(void);
void pptx_reader_free_string(char *s);
void pptx_reader_free_presentation(Presentation *pres);

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

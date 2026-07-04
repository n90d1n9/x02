


// ─────────────────────────────────────────────────────────────────────────────
// Images
// ─────────────────────────────────────────────────────────────────────────────

pub fn extract_images(doc: &Document) -> Result<Vec<ImageInfo>> {
    let mut pages: Vec<(u32, ObjectId)> = doc.get_pages().into_iter().collect();
    pages.sort_by_key(|(n, _)| *n);
    let mut images = Vec::new();
    let mut img_idx = 0usize;
    for (page_num, page_id) in &pages {
        let page_index = (*page_num as usize).saturating_sub(1);
        let (res_dict_opt, _) = doc.get_page_resources(*page_id);
        if let Some(res_dict) = res_dict_opt {
            if let Ok(xobj) = res_dict.get(b"XObject") {
                collect_xobject_images(doc, xobj, page_index, &mut img_idx, &mut images)?;
            }
        }
    }
    Ok(images)
}

fn collect_xobject_images(
    doc: &Document,
    xobjects: &Object,
    page_index: usize,
    img_idx: &mut usize,
    images: &mut Vec<ImageInfo>,
) -> Result<()> {
    let xobj_dict = match xobjects {
        Object::Dictionary(d) => d,
        Object::Reference(id) => {
            if let Ok(obj) = doc.get_object(*id) {
                return collect_xobject_images(doc, obj, page_index, img_idx, images);
            }
            return Ok(());
        }
        _ => return Ok(()),
    };

    for (_, xobj_ref) in xobj_dict.iter() {
        let xobj = match xobj_ref {
            Object::Reference(id) => match doc.get_object(*id) {
                Ok(o) => o,
                Err(_) => continue,
            },
            other => other,
        };
        if let Ok(stream) = xobj.as_stream() {
            let dict = &stream.dict;
            let subtype = dict
                .get(b"Subtype")
                .ok()
                .and_then(|o| o.as_name_str().ok())
                .unwrap_or("");
            if subtype == "Image" {
                let width = dict_u32(dict, b"Width");
                let height = dict_u32(dict, b"Height");
                let bits = dict_u32(dict, b"BitsPerComponent");
                let color_space = dict.get(b"ColorSpace").ok().and_then(|o| {
                    decode_obj_string(o).or_else(|| o.as_name_str().ok().map(|s| s.to_owned()))
                });
                let filters = collect_filters(dict);
                let data = stream.content.clone();
                let data_base64 = B64.encode(&data);
                let format = detect_format_from_filters(&filters, &data);

                images.push(ImageInfo {
                    page_index,
                    image_index: *img_idx,
                    width,
                    height,
                    color_space,
                    bits_per_component: bits,
                    filters,
                    format,
                    data,
                    data_base64,
                });
                *img_idx += 1;
            }
        }
    }
    Ok(())
}

fn detect_format_from_filters(filters: &[String], data: &[u8]) -> ImageFormat {
    for f in filters {
        match f.as_str() {
            "DCTDecode" => return ImageFormat::Jpeg,
            "FlateDecode" | "Fl" => return ImageFormat::Png,
            "JBIG2Decode" => return ImageFormat::Jbig2,
            "CCITTFaxDecode" => return ImageFormat::Ccitt,
            "LZWDecode" => return ImageFormat::Tiff,
            _ => {}
        }
    }
    if data.starts_with(&[0xFF, 0xD8, 0xFF]) {
        return ImageFormat::Jpeg;
    }
    if data.starts_with(&[0x89, b'P', b'N', b'G']) {
        return ImageFormat::Png;
    }
    ImageFormat::Raw
}

fn dict_u32(dict: &lopdf::Dictionary, key: &[u8]) -> Option<u32> {
    dict.get(key).ok().and_then(|o| match o {
        Object::Integer(n) => Some(*n as u32),
        Object::Real(f) => Some(*f as u32),
        _ => None,
    })
}

fn collect_filters(dict: &lopdf::Dictionary) -> Vec<String> {
    match dict.get(b"Filter") {
        Ok(Object::Name(n)) => vec![String::from_utf8_lossy(n).into_owned()],
        Ok(Object::Array(arr)) => arr
            .iter()
            .filter_map(|o| o.as_name_str().ok().map(|s| s.to_owned()))
            .collect(),
        _ => vec![],
    }
}

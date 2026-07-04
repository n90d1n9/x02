


// ─────────────────────────────────────────────────────────────────────────────
// Form fields
// ─────────────────────────────────────────────────────────────────────────────

pub fn extract_form_fields(doc: &Document) -> Result<Vec<FormField>> {
    let cat_id = doc
        .trailer
        .get(b"Root")
        .and_then(|o| o.as_reference())
        .map_err(|e| Error::Parse(e.to_string()))?;
    let catalog = doc.get_object(cat_id)?;
    let cat_dict = catalog.as_dict().map_err(|e| Error::Parse(e.to_string()))?;

    let acroform_id = match cat_dict.get(b"AcroForm") {
        Ok(Object::Reference(id)) => *id,
        _ => return Ok(vec![]),
    };
    let acroform = doc.get_object(acroform_id)?;
    let af_dict = acroform
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?;
    let fields_array = match af_dict.get(b"Fields") {
        Ok(Object::Array(a)) => a.clone(),
        _ => return Ok(vec![]),
    };

    let mut fields = Vec::new();
    for fr in &fields_array {
        if let Object::Reference(fid) = fr {
            collect_field(doc, *fid, "", &mut fields);
        }
    }
    Ok(fields)
}

fn collect_field(doc: &Document, field_id: ObjectId, parent_name: &str, out: &mut Vec<FormField>) {
    let obj = match doc.get_object(field_id) {
        Ok(o) => o,
        Err(_) => return,
    };
    let dict = match obj.as_dict() {
        Ok(d) => d,
        Err(_) => return,
    };

    let partial = get_str(dict, b"T").unwrap_or_default();
    let full_name = if parent_name.is_empty() {
        partial.clone()
    } else {
        format!("{parent_name}.{partial}")
    };

    if let Ok(Object::Array(kids)) = dict.get(b"Kids") {
        let kids = kids.clone();
        for kid in &kids {
            if let Object::Reference(kid_id) = kid {
                collect_field(doc, *kid_id, &full_name, out);
            }
        }
        return;
    }

    let ft_raw = dict
        .get(b"FT")
        .ok()
        .and_then(|o| o.as_name_str().ok().map(|s| s.to_owned()))
        .unwrap_or_default();
    let ff = dict_u32(dict, b"Ff").unwrap_or(0);
    let field_type = match ft_raw.as_str() {
        "Tx" => FieldType::Text,
        "Btn" => {
            if ff & (1 << 16) != 0 {
                FieldType::PushButton
            } else if ff & (1 << 15) != 0 {
                FieldType::RadioButton
            } else {
                FieldType::Checkbox
            }
        }
        "Ch" => {
            if ff & (1 << 17) != 0 {
                FieldType::ComboBox
            } else {
                FieldType::ListBox
            }
        }
        "Sig" => FieldType::Signature,
        _ => FieldType::Unknown,
    };

    let value = dict.get(b"V").ok().and_then(decode_obj_string);
    let default_value = dict.get(b"DV").ok().and_then(decode_obj_string);
    let read_only = ff & 1 != 0;
    let required = ff & 2 != 0;
    let options = extract_field_options(dict);

    // Rect and page from Widget annotation
    let rect = dict
        .get(b"Rect")
        .ok()
        .and_then(|o| o.as_array().ok())
        .and_then(|a| {
            let ns: Vec<f64> = a
                .iter()
                .filter_map(|o| match o {
                    Object::Integer(n) => Some(*n as f64),
                    Object::Real(f) => Some(*f as f64),
                    _ => None,
                })
                .collect();
            if ns.len() == 4 {
                Some([ns[0], ns[1], ns[2], ns[3]])
            } else {
                None
            }
        });

    out.push(FormField {
        name: full_name,
        field_type,
        value,
        default_value,
        read_only,
        required,
        options,
        rect,
        page_index: None,
    });
}

fn extract_field_options(dict: &lopdf::Dictionary) -> Vec<String> {
    let opt = match dict.get(b"Opt") {
        Ok(Object::Array(a)) => a,
        _ => return vec![],
    };
    opt.iter()
        .map(|o| match o {
            Object::Array(pair) => pair
                .get(1)
                .or_else(|| pair.first())
                .and_then(decode_obj_string)
                .unwrap_or_default(),
            other => decode_obj_string(other).unwrap_or_default(),
        })
        .collect()
}

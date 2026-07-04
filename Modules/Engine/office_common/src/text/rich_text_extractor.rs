//! Rich text extraction: styled spans with font name, size, colour, bold/italic.

use crate::{error::Result, models::RichSpan};
use lopdf::{Document, Object, ObjectId};

/// Extract rich text spans from all pages.
pub fn extract_rich_text_all(doc: &Document) -> Result<Vec<RichSpan>> {
    let mut pages: Vec<(u32, ObjectId)> = doc.get_pages().into_iter().collect();
    pages.sort_by_key(|(n, _)| *n);
    let mut out = Vec::new();
    for (page_num, page_id) in &pages {
        let page_index = (*page_num as usize).saturating_sub(1);
        out.extend(extract_rich_text_page(doc, *page_id, page_index)?);
    }
    Ok(out)
}

/// Extract rich text spans from a single page.
pub fn extract_rich_text_page(
    doc: &Document,
    page_id: ObjectId,
    page_index: usize,
) -> Result<Vec<RichSpan>> {
    // Build font map: resource_name → base_font_name
    let font_map = build_font_map(doc, page_id);

    let content = match doc.get_page_content(page_id) {
        Ok(c) => c,
        Err(_) => return Ok(vec![]),
    };

    Ok(parse_rich_content(&content, &font_map, page_index))
}

/// Map from PDF font resource name (e.g. "F1") → base font name (e.g. "Helvetica-Bold").
fn build_font_map(doc: &Document, page_id: ObjectId) -> std::collections::HashMap<String, String> {
    let mut map = std::collections::HashMap::new();
    let (res_dict_opt, _) = doc.get_page_resources(page_id);
    if let Some(res_dict) = res_dict_opt {
        if let Ok(Object::Dictionary(fonts)) = res_dict.get(b"Font") {
            for (key, val) in fonts.iter() {
                let key_str = String::from_utf8_lossy(key).into_owned();
                let font_obj = match val {
                    Object::Reference(id) => doc.get_object(*id).ok(),
                    other => Some(other),
                };
                if let Some(obj) = font_obj {
                    if let Ok(fd) = obj.as_dict() {
                        let base = fd
                            .get(b"BaseFont")
                            .ok()
                            .and_then(|o| o.as_name_str().ok().map(|s| s.to_owned()))
                            .unwrap_or_default();
                        map.insert(key_str, base);
                    }
                }
            }
        }
    }
    map
}

/// Parse a PDF content stream tracking the text state and emitting RichSpans.
fn parse_rich_content(
    data: &[u8],
    font_map: &std::collections::HashMap<String, String>,
    page_index: usize,
) -> Vec<RichSpan> {
    let mut spans = Vec::new();

    // Text state
    let mut current_font: String = String::new();
    let mut current_size: f64 = 12.0;
    let mut fill_r: f64 = 0.0;
    let mut fill_g: f64 = 0.0;
    let mut fill_b: f64 = 0.0;
    let mut tx: f64 = 0.0;
    let mut ty: f64 = 0.0;

    let tokens = tokenize(data);
    let mut i = 0;

    while i < tokens.len() {
        match tokens[i].as_slice() {
            // Tf  font size
            b"Tf" => {
                if i >= 2 {
                    current_font = String::from_utf8_lossy(&tokens[i - 2])
                        .trim_start_matches('/')
                        .to_owned();
                    current_size = parse_f64(&tokens[i - 1]).unwrap_or(12.0);
                }
            }
            // rg  — fill colour (RGB)
            b"rg" => {
                if i >= 3 {
                    fill_b = parse_f64(&tokens[i - 1]).unwrap_or(0.0);
                    fill_g = parse_f64(&tokens[i - 2]).unwrap_or(0.0);
                    fill_r = parse_f64(&tokens[i - 3]).unwrap_or(0.0);
                }
            }
            // g  — fill grey
            b"g" => {
                if i >= 1 {
                    let v = parse_f64(&tokens[i - 1]).unwrap_or(0.0);
                    fill_r = v;
                    fill_g = v;
                    fill_b = v;
                }
            }
            // Td / TD — move text position
            b"Td" | b"TD" => {
                if i >= 2 {
                    tx += parse_f64(&tokens[i - 2]).unwrap_or(0.0);
                    ty += parse_f64(&tokens[i - 1]).unwrap_or(0.0);
                }
            }
            // Tm — set text matrix (x at index 4, y at 5 out of 6 args)
            b"Tm" => {
                if i >= 6 {
                    tx = parse_f64(&tokens[i - 2]).unwrap_or(tx);
                    ty = parse_f64(&tokens[i - 1]).unwrap_or(ty);
                }
            }
            b"T*" => {
                ty -= current_size * 1.2;
            }
            // Tj — show string
            b"Tj" => {
                if i >= 1 {
                    if let Some(text) = decode_token_string(&tokens[i - 1]) {
                        if !text.trim().is_empty() {
                            spans.push(make_span(
                                &text,
                                &current_font,
                                font_map,
                                current_size,
                                [fill_r, fill_g, fill_b],
                                tx,
                                ty,
                                page_index,
                            ));
                        }
                    }
                }
            }
            // TJ — array of strings/kerning
            b"TJ" => {
                // Look back for the array — it was accumulated as individual tokens.
                // We scan backwards to collect strings between [ and ].
                let text = collect_tj_text(&tokens, i);
                if !text.trim().is_empty() {
                    spans.push(make_span(
                        &text,
                        &current_font,
                        font_map,
                        current_size,
                        [fill_r, fill_g, fill_b],
                        tx,
                        ty,
                        page_index,
                    ));
                }
            }
            _ => {}
        }
        i += 1;
    }
    spans
}

fn make_span(
    text: &str,
    font_key: &str,
    font_map: &std::collections::HashMap<String, String>,
    size: f64,
    color: [f64; 3],
    x: f64,
    y: f64,
    page_index: usize,
) -> RichSpan {
    let base_font = font_map.get(font_key).cloned();
    let lower = base_font.as_deref().unwrap_or("").to_lowercase();
    let bold = lower.contains("bold");
    let italic = lower.contains("italic") || lower.contains("oblique");
    RichSpan {
        page_index,
        text: text.to_owned(),
        font_name: font_key.to_owned(),
        base_font,
        font_size: size,
        color,
        bold,
        italic,
        x,
        y,
    }
}

// ─── tokenizer ────────────────────────────────────────────────────────────────

fn tokenize(data: &[u8]) -> Vec<Vec<u8>> {
    let mut tokens: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    let len = data.len();

    while i < len {
        // skip whitespace
        while i < len && is_ws(data[i]) {
            i += 1;
        }
        if i >= len {
            break;
        }

        if data[i] == b'(' {
            // literal string — keep as-is including parens so callers can detect
            let start = i;
            let mut depth = 0usize;
            i += 1;
            while i < len {
                match data[i] {
                    b'\\' => {
                        i += 2;
                    }
                    b'(' => {
                        depth += 1;
                        i += 1;
                    }
                    b')' => {
                        if depth == 0 {
                            i += 1;
                            break;
                        }
                        depth -= 1;
                        i += 1;
                    }
                    _ => {
                        i += 1;
                    }
                }
            }
            tokens.push(data[start..i].to_vec());
        } else if data[i] == b'<' && i + 1 < len && data[i + 1] != b'<' {
            let start = i;
            while i < len && data[i] != b'>' {
                i += 1;
            }
            if i < len {
                i += 1;
            }
            tokens.push(data[start..i].to_vec());
        } else if data[i] == b'[' || data[i] == b']' {
            tokens.push(vec![data[i]]);
            i += 1;
        } else if data[i] == b'<' && i + 1 < len && data[i + 1] == b'<' {
            // dict — skip entirely
            let mut depth = 0usize;
            while i + 1 < len {
                if data[i] == b'<' && data[i + 1] == b'<' {
                    depth += 1;
                    i += 2;
                } else if data[i] == b'>' && data[i + 1] == b'>' {
                    depth -= 1;
                    i += 2;
                    if depth == 0 {
                        break;
                    }
                } else {
                    i += 1;
                }
            }
        } else {
            let start = i;
            while i < len
                && !is_ws(data[i])
                && data[i] != b'('
                && data[i] != b'<'
                && data[i] != b'['
                && data[i] != b']'
            {
                i += 1;
            }
            if i > start {
                tokens.push(data[start..i].to_vec());
            }
        }
    }
    tokens
}

fn is_ws(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0C | 0x00)
}

fn parse_f64(tok: &[u8]) -> Option<f64> {
    std::str::from_utf8(tok).ok()?.trim().parse().ok()
}

fn decode_token_string(tok: &[u8]) -> Option<String> {
    if tok.starts_with(b"(") && tok.ends_with(b")") {
        let inner = &tok[1..tok.len() - 1];
        Some(decode_literal_string(inner))
    } else if tok.starts_with(b"<") && tok.ends_with(b">") {
        let hex = &tok[1..tok.len() - 1];
        if let Ok(bytes) = hex::decode(hex) {
            Some(decode_bytes_to_string(&bytes))
        } else {
            None
        }
    } else {
        None
    }
}

fn decode_literal_string(data: &[u8]) -> String {
    let mut out = Vec::new();
    let mut i = 0;
    while i < data.len() {
        if data[i] == b'\\' && i + 1 < data.len() {
            i += 1;
            match data[i] {
                b'n' => out.push(b'\n'),
                b'r' => out.push(b'\r'),
                b't' => out.push(b'\t'),
                b'(' => out.push(b'('),
                b')' => out.push(b')'),
                b'\\' => out.push(b'\\'),
                b'0'..=b'7' => {
                    let mut v = data[i] - b'0';
                    let mut j = 1;
                    while j < 3 && i + j < data.len() && data[i + j] >= b'0' && data[i + j] <= b'7'
                    {
                        v = v * 8 + (data[i + j] - b'0');
                        j += 1;
                    }
                    out.push(v);
                    i += j - 1;
                }
                _ => out.push(data[i]),
            }
        } else {
            out.push(data[i]);
        }
        i += 1;
    }
    decode_bytes_to_string(&out)
}

fn decode_bytes_to_string(bytes: &[u8]) -> String {
    if bytes.len() >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF {
        let chars: Vec<u16> = bytes[2..]
            .chunks_exact(2)
            .map(|c| u16::from_be_bytes([c[0], c[1]]))
            .collect();
        String::from_utf16(&chars).unwrap_or_else(|_| String::from_utf8_lossy(bytes).into_owned())
    } else {
        String::from_utf8_lossy(bytes).into_owned()
    }
}

fn collect_tj_text(tokens: &[Vec<u8>], tj_pos: usize) -> String {
    // Walk back past ']' scanning for string tokens
    let mut text = String::new();
    let mut pos = tj_pos;
    // find the matching ']'
    while pos > 0 && tokens[pos] != b"]" {
        pos = pos.saturating_sub(1);
        if pos == 0 {
            break;
        }
    }
    // find '[' going further back
    let end = pos;
    while pos > 0 && tokens[pos] != b"[" {
        pos = pos.saturating_sub(1);
    }
    let start = pos + 1;
    for tok in &tokens[start..end] {
        if let Some(s) = decode_token_string(tok) {
            text.push_str(&s);
        } else if let Ok(n) = std::str::from_utf8(tok).unwrap_or("").trim().parse::<f64>() {
            if n < -100.0 {
                text.push(' ');
            }
        }
    }
    text
}

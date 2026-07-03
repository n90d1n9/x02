


// ─────────────────────────────────────────────────────────────────────────────
// Plain text
// ─────────────────────────────────────────────────────────────────────────────

pub fn extract_all_text(doc: &Document) -> Result<Vec<PageText>> {
    let mut pages: Vec<(u32, ObjectId)> = doc.get_pages().into_iter().collect();
    pages.sort_by_key(|(n, _)| *n);
    let mut result = Vec::with_capacity(pages.len());
    for (page_num, page_id) in &pages {
        let text = extract_page_text(doc, *page_id)?;
        result.push(PageText::new((*page_num as usize).saturating_sub(1), text));
    }
    Ok(result)
}

pub fn extract_page_text(doc: &Document, page_id: ObjectId) -> Result<String> {
    let content = match doc.get_page_content(page_id) {
        Ok(c) => c,
        Err(_) => return Ok(String::new()),
    };
    Ok(parse_content_stream(&content))
}

fn parse_content_stream(data: &[u8]) -> String {
    let mut out = String::new();
    let mut i = 0;
    let len = data.len();

    while i < len {
        while i < len && is_ws(data[i]) {
            i += 1;
        }
        if i >= len {
            break;
        }

        if data[i] == b'(' {
            let (s, consumed) = read_pdf_literal(&data[i..]);
            i += consumed;
            out.push_str(&s);
            continue;
        }
        if data[i] == b'<' && i + 1 < len && data[i + 1] != b'<' {
            let end = data[i..].iter().position(|&b| b == b'>').unwrap_or(1);
            let hex_data = &data[i + 1..i + end];
            // Remove whitespace from hex
            let hex_clean: String = hex_data
                .iter()
                .filter(|&&b| !is_ws(b))
                .map(|&b| b as char)
                .collect();
            if let Ok(bytes) = hex::decode(&hex_clean) {
                out.push_str(&decode_bytes(&bytes));
            }
            i += end + 1;
            continue;
        }

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
            match &data[start..i] {
                b"Td" | b"TD" | b"T*" | b"ET" => {
                    if !out.ends_with('\n') {
                        out.push('\n');
                    }
                }
                _ => {}
            }
        }

        if i < len && data[i] == b'[' {
            i += 1;
            while i < len && data[i] != b']' {
                if data[i] == b'(' {
                    let (s, consumed) = read_pdf_literal(&data[i..]);
                    i += consumed;
                    out.push_str(&s);
                } else if data[i] == b'<' && i + 1 < len && data[i + 1] != b'<' {
                    let end = data[i..].iter().position(|&b| b == b'>').unwrap_or(1);
                    let hex_data = &data[i + 1..i + end];
                    let hex_clean: String = hex_data
                        .iter()
                        .filter(|&&b| !is_ws(b))
                        .map(|&b| b as char)
                        .collect();
                    if let Ok(bytes) = hex::decode(&hex_clean) {
                        out.push_str(&decode_bytes(&bytes));
                    }
                    i += end + 1;
                } else {
                    let ts = i;
                    while i < len && data[i] != b'(' && data[i] != b']' && data[i] != b'<' {
                        i += 1;
                    }
                    if i > ts {
                        if let Ok(s) = std::str::from_utf8(&data[ts..i]) {
                            if let Ok(n) = s.trim().parse::<f64>() {
                                if n < -100.0 {
                                    out.push(' ');
                                }
                            }
                        }
                    }
                }
            }
            if i < len {
                i += 1;
            }
        }
    }
    let re = regex::Regex::new(r"\n{3,}").unwrap();
    re.replace_all(out.trim(), "\n\n").into_owned()
}

fn is_ws(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0C | 0x00)
}

fn read_pdf_literal(data: &[u8]) -> (String, usize) {
    debug_assert_eq!(data[0], b'(');
    let mut raw = Vec::new();
    let mut depth = 0usize;
    let mut i = 1;
    while i < data.len() {
        match data[i] {
            b'\\' if i + 1 < data.len() => {
                i += 1;
                match data[i] {
                    b'n' => raw.push(b'\n'),
                    b'r' => raw.push(b'\r'),
                    b't' => raw.push(b'\t'),
                    b'(' => raw.push(b'('),
                    b')' => raw.push(b')'),
                    b'\\' => raw.push(b'\\'),
                    b'0'..=b'7' => {
                        let mut v = data[i] - b'0';
                        let mut j = 1;
                        while j < 3
                            && i + j < data.len()
                            && data[i + j] >= b'0'
                            && data[i + j] <= b'7'
                        {
                            v = v * 8 + (data[i + j] - b'0');
                            j += 1;
                        }
                        raw.push(v);
                        i += j - 1;
                    }
                    _ => raw.push(data[i]),
                }
                i += 1;
            }
            b'(' => {
                depth += 1;
                raw.push(b'(');
                i += 1;
            }
            b')' => {
                if depth == 0 {
                    i += 1;
                    break;
                }
                depth -= 1;
                raw.push(b')');
                i += 1;
            }
            b => {
                raw.push(b);
                i += 1;
            }
        }
    }
    (decode_bytes(&raw), i)
}

fn decode_bytes(bytes: &[u8]) -> String {
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

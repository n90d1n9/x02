
// ---------------------------------------------------------------------------
// Headers / Footers
// ---------------------------------------------------------------------------

/// Parse a header or footer XML part and return paragraphs.
pub fn parse_header_footer(xml: &str) -> Vec<Paragraph> {
    let mut paragraphs = Vec::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(false);
    let mut buf = Vec::new();
    let mut in_para = false;
    let mut current_para = Paragraph::default();
    let mut in_run = false;
    let mut in_t = false;
    let mut current_text = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "p" => { in_para = true; current_para = Paragraph::default(); }
                    "r" if in_para => in_run = true,
                    "t" if in_run => in_t = true,
                    _ => {}
                }
            }
            Ok(Event::Text(ref t)) if in_t => {
                current_text.push_str(&t.unescape().unwrap_or_default());
            }
            Ok(Event::End(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "t" => in_t = false,
                    "r" if in_para => {
                        if !current_text.is_empty() {
                            current_para.runs.push(Run {
                                text: current_text.clone(),
                                ..Default::default()
                            });
                            current_text.clear();
                        }
                        in_run = false;
                    }
                    "p" if in_para => {
                        paragraphs.push(current_para.clone());
                        current_para = Paragraph::default();
                        in_para = false;
                    }
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    paragraphs
}

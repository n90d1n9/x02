
// ---------------------------------------------------------------------------
// Footnotes / Endnotes
// ---------------------------------------------------------------------------

pub fn parse_footnotes(xml: &str) -> Vec<Footnote> {
    parse_note_part(xml)
        .into_iter()
        .filter(|(id, _)| id != "0" && id != "-1")
        .map(|(id, paragraphs)| Footnote { id, paragraphs })
        .collect()
}

pub fn parse_endnotes(xml: &str) -> Vec<Endnote> {
    parse_note_part(xml)
        .into_iter()
        .filter(|(id, _)| id != "0" && id != "-1")
        .map(|(id, paragraphs)| Endnote { id, paragraphs })
        .collect()
}

fn parse_note_part(xml: &str) -> Vec<(String, Vec<Paragraph>)> {
    let mut notes = Vec::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(false);
    let mut buf = Vec::new();
    let mut in_note = false;
    let mut note_id = String::new();
    let mut paras: Vec<Paragraph> = Vec::new();
    let mut current_para = Paragraph::default();
    let mut in_run = false;
    let mut in_t = false;
    let mut current_text = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "footnote" | "endnote" => {
                        in_note = true;
                        paras.clear();
                        note_id = e.attributes().flatten()
                            .find(|a| a.key.as_ref() == b"w:id")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string())
                            .unwrap_or_default();
                    }
                    "p" if in_note => current_para = Paragraph::default(),
                    "r" if in_note => in_run = true,
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
                    "r" if in_note => {
                        if !current_text.is_empty() {
                            current_para.runs.push(Run {
                                text: current_text.clone(),
                                ..Default::default()
                            });
                            current_text.clear();
                        }
                        in_run = false;
                    }
                    "p" if in_note => {
                        paras.push(current_para.clone());
                        current_para = Paragraph::default();
                    }
                    "footnote" | "endnote" => {
                        notes.push((note_id.clone(), paras.clone()));
                        in_note = false;
                    }
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    notes
}

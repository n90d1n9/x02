
// ---------------------------------------------------------------------------
// Styles
// ---------------------------------------------------------------------------

pub fn parse_styles(xml: &str) -> Vec<StyleDef> {
    let mut styles = Vec::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();

    let mut in_style = false;
    let mut current = StyleDef {
        id: String::new(),
        name: String::new(),
        style_type: StyleType::Unknown,
        based_on: None,
        next_style: None,
        paragraph_formatting: None,
        run_formatting: None,
    };
    let mut in_ppr = false;
    let mut in_rpr = false;
    let mut pf = ParagraphFormatting::default();
    let mut rf = RunFormatting::default();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "style" => {
                        in_style = true;
                        current = StyleDef {
                            id: String::new(),
                            name: String::new(),
                            style_type: StyleType::Unknown,
                            based_on: None,
                            next_style: None,
                            paragraph_formatting: None,
                            run_formatting: None,
                        };
                        pf = ParagraphFormatting::default();
                        rf = RunFormatting::default();
                        in_ppr = false;
                        in_rpr = false;
                        for attr in e.attributes().flatten() {
                            match attr.key.as_ref() {
                                b"w:styleId" => current.id = String::from_utf8_lossy(&attr.value).to_string(),
                                b"w:type" => {
                                    current.style_type = match attr.value.as_ref() {
                                        b"paragraph" => StyleType::Paragraph,
                                        b"character" => StyleType::Character,
                                        b"table" => StyleType::Table,
                                        b"numbering" => StyleType::Numbering,
                                        _ => StyleType::Unknown,
                                    }
                                }
                                _ => {}
                            }
                        }
                    }
                    "name" if in_style => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                current.name = String::from_utf8_lossy(&attr.value).to_string();
                            }
                        }
                    }
                    "basedOn" if in_style => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                current.based_on = Some(String::from_utf8_lossy(&attr.value).to_string());
                            }
                        }
                    }
                    "next" if in_style => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                current.next_style = Some(String::from_utf8_lossy(&attr.value).to_string());
                            }
                        }
                    }
                    "pPr" if in_style => in_ppr = true,
                    "rPr" if in_style => in_rpr = true,
                    "jc" if in_ppr => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                pf.alignment = parse_alignment(&String::from_utf8_lossy(&attr.value));
                            }
                        }
                    }
                    "outlineLvl" if in_ppr => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                pf.outline_level = String::from_utf8_lossy(&attr.value).parse().ok();
                            }
                        }
                    }
                    "b" if in_rpr => rf.bold = true,
                    "i" if in_rpr => rf.italic = true,
                    "u" if in_rpr => rf.underline = true,
                    "sz" if in_rpr => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                rf.size = String::from_utf8_lossy(&attr.value).parse().ok();
                            }
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::End(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "style" if in_style => {
                        current.paragraph_formatting = Some(pf.clone());
                        current.run_formatting = Some(rf.clone());
                        styles.push(current.clone());
                        in_style = false;
                        in_ppr = false;
                        in_rpr = false;
                    }
                    "pPr" => in_ppr = false,
                    "rPr" => in_rpr = false,
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    styles
}

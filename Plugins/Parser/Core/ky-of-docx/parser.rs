use quick_xml::events::Event;
use quick_xml::Reader;
use std::collections::HashMap;

use crate::error::{DocxError, Result};
use crate::models::*;

// ---------------------------------------------------------------------------
// Relationship map
// ---------------------------------------------------------------------------

/// Parse a `_rels/*.rels` file and return `{ rId -> (type, target) }`.
pub fn parse_relationships(xml: &str) -> HashMap<String, (String, String)> {
    let mut map = HashMap::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);

    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) => {
                if e.local_name().as_ref() == b"Relationship" {
                    let mut id = String::new();
                    let mut typ = String::new();
                    let mut target = String::new();
                    for attr in e.attributes().flatten() {
                        match attr.key.as_ref() {
                            b"Id" => id = String::from_utf8_lossy(&attr.value).to_string(),
                            b"Type" => typ = String::from_utf8_lossy(&attr.value).to_string(),
                            b"Target" => target = String::from_utf8_lossy(&attr.value).to_string(),
                            _ => {}
                        }
                    }
                    if !id.is_empty() {
                        map.insert(id, (typ, target));
                    }
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    map
}

// ---------------------------------------------------------------------------
// Content-type map
// ---------------------------------------------------------------------------

/// Parse `[Content_Types].xml` and return `{ part_path -> content_type }`.
pub fn parse_content_types(xml: &str) -> HashMap<String, String> {
    let mut map = HashMap::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Empty(ref e)) | Ok(Event::Start(ref e)) => {
                let name = e.local_name();
                if name.as_ref() == b"Override" {
                    let mut part = String::new();
                    let mut ct = String::new();
                    for attr in e.attributes().flatten() {
                        match attr.key.as_ref() {
                            b"PartName" => part = String::from_utf8_lossy(&attr.value).to_string(),
                            b"ContentType" => ct = String::from_utf8_lossy(&attr.value).to_string(),
                            _ => {}
                        }
                    }
                    if !part.is_empty() {
                        map.insert(part.trim_start_matches('/').to_string(), ct);
                    }
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    map
}

// ---------------------------------------------------------------------------
// Metadata
// ---------------------------------------------------------------------------

pub fn parse_core_props(xml: &str) -> Metadata {
    let mut meta = Metadata::default();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut current_tag = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                current_tag = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
            }
            Ok(Event::Text(ref t)) => {
                let val = t.unescape().unwrap_or_default().to_string();
                match current_tag.as_str() {
                    "title" => meta.title = Some(val),
                    "subject" => meta.subject = Some(val),
                    "creator" => meta.creator = Some(val),
                    "description" => meta.description = Some(val),
                    "keywords" => meta.keywords = Some(val),
                    "lastModifiedBy" => meta.last_modified_by = Some(val),
                    "revision" => meta.revision = val.parse().ok(),
                    "created" => meta.created = Some(val),
                    "modified" => meta.modified = Some(val),
                    "category" => meta.category = Some(val),
                    "contentStatus" => meta.content_status = Some(val),
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    meta
}

pub fn parse_app_props(xml: &str, meta: &mut Metadata) {
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut current_tag = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                current_tag = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
            }
            Ok(Event::Text(ref t)) => {
                let val = t.unescape().unwrap_or_default().to_string();
                match current_tag.as_str() {
                    "Pages" => meta.pages = val.parse().ok(),
                    "Words" => meta.words = val.parse().ok(),
                    "Characters" => meta.characters = val.parse().ok(),
                    "Application" => meta.application = Some(val),
                    "AppVersion" => meta.app_version = Some(val),
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
}

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
                                b"w:styleId" => {
                                    current.id = String::from_utf8_lossy(&attr.value).to_string()
                                }
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
                                current.based_on =
                                    Some(String::from_utf8_lossy(&attr.value).to_string());
                            }
                        }
                    }
                    "next" if in_style => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                current.next_style =
                                    Some(String::from_utf8_lossy(&attr.value).to_string());
                            }
                        }
                    }
                    "pPr" if in_style => in_ppr = true,
                    "rPr" if in_style => in_rpr = true,
                    "jc" if in_ppr => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                pf.alignment =
                                    parse_alignment(&String::from_utf8_lossy(&attr.value));
                            }
                        }
                    }
                    "outlineLvl" if in_ppr => {
                        for attr in e.attributes().flatten() {
                            if attr.key.as_ref() == b"w:val" {
                                pf.outline_level =
                                    String::from_utf8_lossy(&attr.value).parse().ok();
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

// ---------------------------------------------------------------------------
// Document body
// ---------------------------------------------------------------------------

/// Full parser state machine for `word/document.xml`.
pub struct DocumentParser<'a> {
    pub rels: &'a HashMap<String, (String, String)>,
    pub styles_map: &'a HashMap<String, String>, // styleId -> name
    pub numbering_map: &'a HashMap<String, ListType>, // numId -> type
}

impl<'a> DocumentParser<'a> {
    pub fn parse(&self, xml: &str) -> Result<(Vec<Block>, Vec<TrackedChange>, Vec<ImageRef>)> {
        let mut blocks: Vec<Block> = Vec::new();
        let mut tracked: Vec<TrackedChange> = Vec::new();
        let mut images: Vec<ImageRef> = Vec::new();

        let mut reader = Reader::from_str(xml);
        reader.trim_text(false);
        let mut buf = Vec::new();

        // --- parser state ---
        let mut in_body = false;
        let mut para_stack: Vec<Paragraph> = Vec::new();
        let mut table_stack: Vec<Table> = Vec::new();
        let mut row_stack: Vec<TableRow> = Vec::new();
        let mut cell_stack: Vec<TableCell> = Vec::new();
        let mut run: Option<Run> = None;
        let mut in_run = false;
        let mut hyperlink_url: Option<String> = None;
        let mut in_del = false;
        let mut in_ins = false;
        let mut tc_author = String::new();
        let mut tc_date = String::new();
        let mut tc_id = String::new();
        let mut tc_text = String::new();
        let mut in_t = false;
        let mut in_instrtext = false;
        let mut field_mode = false;
        let mut field_result = String::new();
        let mut depth_para: u32 = 0;
        let mut depth_table: u32 = 0;
        let mut depth_row: u32 = 0;
        let mut depth_cell: u32 = 0;
        let mut in_drawing = false;
        let mut img_rel_id: Option<String> = None;
        let mut img_width: Option<i64> = None;
        let mut img_height: Option<i64> = None;
        let mut img_desc: Option<String> = None;

        macro_rules! attr_val {
            ($e:expr, $key:expr) => {
                $e.attributes()
                    .flatten()
                    .find(|a| a.key.as_ref() == $key)
                    .map(|a| String::from_utf8_lossy(&a.value).to_string())
            };
        }

        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) => {
                    let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                    match local.as_str() {
                        "body" => in_body = true,
                        "p" if in_body => {
                            depth_para += 1;
                            if depth_para == 1 {
                                para_stack.push(Paragraph::default());
                            }
                        }
                        "tbl" if in_body => {
                            depth_table += 1;
                            if depth_table == 1 {
                                table_stack.push(Table::default());
                            }
                        }
                        "tr" if in_body => {
                            depth_row += 1;
                            if depth_row == 1 {
                                row_stack.push(TableRow::default());
                            }
                        }
                        "tc" if in_body => {
                            depth_cell += 1;
                            if depth_cell == 1 {
                                cell_stack.push(TableCell {
                                    col_span: 1,
                                    row_span: 1,
                                    ..Default::default()
                                });
                            }
                        }
                        "r" if in_body && !in_del => {
                            in_run = true;
                            run = Some(Run {
                                hyperlink: hyperlink_url.clone(),
                                ..Default::default()
                            });
                        }
                        "hyperlink" => {
                            if let Some(rid) = attr_val!(e, b"r:id") {
                                if let Some((_, target)) = self.rels.get(&rid) {
                                    hyperlink_url = Some(target.clone());
                                }
                            }
                        }
                        "del" => {
                            in_del = true;
                            tc_id = attr_val!(e, b"w:id").unwrap_or_default();
                            tc_author = attr_val!(e, b"w:author").unwrap_or_default();
                            tc_date = attr_val!(e, b"w:date").unwrap_or_default();
                            tc_text.clear();
                        }
                        "ins" => {
                            in_ins = true;
                            tc_id = attr_val!(e, b"w:id").unwrap_or_default();
                            tc_author = attr_val!(e, b"w:author").unwrap_or_default();
                            tc_date = attr_val!(e, b"w:date").unwrap_or_default();
                            tc_text.clear();
                            // Also open a run for the inserted text
                            in_run = true;
                            run = Some(Run {
                                hyperlink: hyperlink_url.clone(),
                                ..Default::default()
                            });
                        }
                        "t" if in_run => in_t = true,
                        "delText" if in_del => in_t = true,
                        "instrText" => {
                            in_instrtext = true;
                            field_mode = true;
                        }
                        "drawing" => in_drawing = true,
                        "blip" if in_drawing => {
                            if let Some(rid) = attr_val!(e, b"r:embed") {
                                img_rel_id = Some(rid);
                            }
                        }
                        "extent" if in_drawing => {
                            img_width = attr_val!(e, b"cx").and_then(|v| v.parse().ok());
                            img_height = attr_val!(e, b"cy").and_then(|v| v.parse().ok());
                        }
                        "docPr" if in_drawing => {
                            img_desc = attr_val!(e, b"descr");
                        }
                        "pStyle" => {
                            if let Some(p) = para_stack.last_mut() {
                                if let Some(style_id) = attr_val!(e, b"w:val") {
                                    let name = self
                                        .styles_map
                                        .get(&style_id)
                                        .cloned()
                                        .unwrap_or(style_id.clone());
                                    p.style = Some(name.clone());
                                    // Derive heading level from style name
                                    if name.to_lowercase().starts_with("heading") {
                                        if let Some(level_str) = name.split_whitespace().last() {
                                            p.heading_level = level_str.parse().ok();
                                        }
                                    }
                                    // Also check styleId directly (e.g. "Heading1")
                                    if p.heading_level.is_none() {
                                        let lower_id = style_id.to_lowercase();
                                        if lower_id.starts_with("heading") {
                                            let digits: String = lower_id
                                                .chars()
                                                .filter(|c| c.is_ascii_digit())
                                                .collect();
                                            p.heading_level = digits.parse().ok();
                                        }
                                    }
                                }
                            }
                        }
                        "numId" => {
                            if let Some(p) = para_stack.last_mut() {
                                if let Some(num_id) = attr_val!(e, b"w:val") {
                                    let lt = self
                                        .numbering_map
                                        .get(&num_id)
                                        .cloned()
                                        .unwrap_or(ListType::Unordered);
                                    p.list_info = Some(ListInfo {
                                        num_id,
                                        level: p.list_info.as_ref().map_or(0, |li| li.level),
                                        list_type: lt,
                                    });
                                }
                            }
                        }
                        "ilvl" => {
                            if let Some(p) = para_stack.last_mut() {
                                if let Some(level) = attr_val!(e, b"w:val") {
                                    if let Some(li) = p.list_info.as_mut() {
                                        li.level = level.parse().unwrap_or(0);
                                    }
                                }
                            }
                        }
                        "jc" if depth_para > 0 => {
                            if let Some(p) = para_stack.last_mut() {
                                if let Some(val) = attr_val!(e, b"w:val") {
                                    p.alignment = parse_alignment(&val);
                                }
                            }
                        }
                        "b" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.bold = true;
                            }
                        }
                        "i" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.italic = true;
                            }
                        }
                        "u" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.underline = true;
                            }
                        }
                        "strike" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.strikethrough = true;
                            }
                        }
                        "vertAlign" if in_run => {
                            if let Some(r) = run.as_mut() {
                                if let Some(val) = attr_val!(e, b"w:val") {
                                    r.formatting.vertical_align = Some(match val.as_str() {
                                        "superscript" => VerticalAlign::Superscript,
                                        "subscript" => VerticalAlign::Subscript,
                                        _ => VerticalAlign::Baseline,
                                    });
                                    r.formatting.superscript = val == "superscript";
                                    r.formatting.subscript = val == "subscript";
                                }
                            }
                        }
                        "color" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.color = attr_val!(e, b"w:val");
                            }
                        }
                        "sz" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.size =
                                    attr_val!(e, b"w:val").and_then(|v| v.parse().ok());
                            }
                        }
                        "highlight" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.highlight = attr_val!(e, b"w:val");
                            }
                        }
                        "rStyle" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.formatting.style = attr_val!(e, b"w:val");
                            }
                        }
                        "footnoteReference" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.footnote_ref = attr_val!(e, b"w:id");
                            }
                        }
                        "endnoteReference" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.endnote_ref = attr_val!(e, b"w:id");
                            }
                        }
                        "tcW" if depth_cell > 0 => {
                            if let Some(c) = cell_stack.last_mut() {
                                c.width = attr_val!(e, b"w:w").and_then(|v| v.parse().ok());
                            }
                        }
                        "gridSpan" if depth_cell > 0 => {
                            if let Some(c) = cell_stack.last_mut() {
                                c.col_span = attr_val!(e, b"w:val")
                                    .and_then(|v| v.parse().ok())
                                    .unwrap_or(1);
                            }
                        }
                        "vMerge" if depth_cell > 0 => {
                            if let Some(c) = cell_stack.last_mut() {
                                // Determine row span based on vMerge attribute value
                                c.row_span = match attr_val!(e, b"w:val").as_deref() {
                                    Some("restart") | None => 1, // start of merge
                                    Some("continue") => 0,       // continuation of merge
                                    _ => 1,
                                };
                            }
                        }
                        "shd" if depth_cell > 0 => {
                            if let Some(c) = cell_stack.last_mut() {
                                c.background_color = attr_val!(e, b"w:fill");
                            }
                        }
                        "trPr" if depth_row > 0 => {}
                        "tblHeader" if depth_row > 0 => {
                            if let Some(row) = row_stack.last_mut() {
                                row.is_header = true;
                            }
                        }
                        _ => {}
                    }
                }
                Ok(Event::Empty(ref e)) => {
                    let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                    match local.as_str() {
                        "br" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.text.push('\n');
                            }
                        }
                        "tab" if in_run => {
                            if let Some(r) = run.as_mut() {
                                r.text.push('\t');
                            }
                        }
                        "blip" if in_drawing => {
                            // r:embed attribute
                            for attr in e.attributes().flatten() {
                                if attr.key.as_ref() == b"r:embed" {
                                    img_rel_id =
                                        Some(String::from_utf8_lossy(&attr.value).to_string());
                                }
                            }
                        }
                        "extent" if in_drawing => {
                            img_width = e
                                .attributes()
                                .flatten()
                                .find(|a| a.key.as_ref() == b"cx")
                                .and_then(|a| String::from_utf8_lossy(&a.value).parse().ok());
                            img_height = e
                                .attributes()
                                .flatten()
                                .find(|a| a.key.as_ref() == b"cy")
                                .and_then(|a| String::from_utf8_lossy(&a.value).parse().ok());
                        }
                        _ => {}
                    }
                }
                Ok(Event::Text(ref t)) => {
                    let text = t.unescape().unwrap_or_default().to_string();
                    if in_t && in_run {
                        if in_del {
                            tc_text.push_str(&text);
                        } else {
                            if let Some(r) = run.as_mut() {
                                r.text.push_str(&text);
                            }
                            if in_ins {
                                tc_text.push_str(&text);
                            }
                        }
                    } else if in_instrtext {
                        field_result.push_str(&text);
                    }
                }
                Ok(Event::End(ref e)) => {
                    let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                    match local.as_str() {
                        "t" | "delText" => in_t = false,
                        "instrText" => {
                            in_instrtext = false;
                        }
                        "r" if in_run && !in_del => {
                            if let Some(mut r) = run.take() {
                                if field_mode && !field_result.is_empty() {
                                    r.field_text = Some(field_result.clone());
                                    field_result.clear();
                                    field_mode = false;
                                }
                                push_run_to_context(r, &mut para_stack, &mut cell_stack);
                            }
                            in_run = false;
                            if in_ins {
                                // run ended; ins tracking continues
                            }
                        }
                        "hyperlink" => {
                            hyperlink_url = None;
                        }
                        "del" => {
                            tracked.push(TrackedChange {
                                id: tc_id.clone(),
                                change_type: ChangeType::Deletion,
                                author: tc_author.clone(),
                                date: if tc_date.is_empty() {
                                    None
                                } else {
                                    Some(tc_date.clone())
                                },
                                text: tc_text.clone(),
                            });
                            in_del = false;
                            in_run = false;
                            run = None;
                        }
                        "ins" => {
                            tracked.push(TrackedChange {
                                id: tc_id.clone(),
                                change_type: ChangeType::Insertion,
                                author: tc_author.clone(),
                                date: if tc_date.is_empty() {
                                    None
                                } else {
                                    Some(tc_date.clone())
                                },
                                text: tc_text.clone(),
                            });
                            // Commit the run
                            if let Some(r) = run.take() {
                                push_run_to_context(r, &mut para_stack, &mut cell_stack);
                            }
                            in_ins = false;
                            in_run = false;
                        }
                        "drawing" => {
                            if let Some(rid) = img_rel_id.take() {
                                if let Some((_, target)) = self.rels.get(&rid) {
                                    images.push(ImageRef {
                                        rel_id: rid.clone(),
                                        target: format!(
                                            "word/{}",
                                            target.trim_start_matches("../")
                                        ),
                                        content_type: String::new(), // filled later
                                        width_emu: img_width,
                                        height_emu: img_height,
                                        description: img_desc.take(),
                                    });
                                    // Also reference from run
                                    if let Some(r) = run.as_mut() {
                                        r.image_rel_id = Some(rid.clone());
                                    }
                                }
                            }
                            img_width = None;
                            img_height = None;
                            in_drawing = false;
                        }
                        "p" if in_body && depth_para == 1 => {
                            if let Some(para) = para_stack.pop() {
                                if depth_cell > 0 {
                                    if let Some(cell) = cell_stack.last_mut() {
                                        cell.paragraphs.push(para);
                                    }
                                } else if depth_row == 0 {
                                    blocks.push(Block::Paragraph(para));
                                }
                            }
                            depth_para = depth_para.saturating_sub(1);
                        }
                        "p" if in_body => {
                            depth_para = depth_para.saturating_sub(1);
                        }
                        "tc" if depth_cell == 1 => {
                            if let Some(cell) = cell_stack.pop() {
                                if let Some(row) = row_stack.last_mut() {
                                    row.cells.push(cell);
                                }
                            }
                            depth_cell = depth_cell.saturating_sub(1);
                        }
                        "tc" => {
                            depth_cell = depth_cell.saturating_sub(1);
                        }
                        "tr" if depth_row == 1 => {
                            if let Some(row) = row_stack.pop() {
                                if let Some(table) = table_stack.last_mut() {
                                    table.rows.push(row);
                                }
                            }
                            depth_row = depth_row.saturating_sub(1);
                        }
                        "tr" => {
                            depth_row = depth_row.saturating_sub(1);
                        }
                        "tbl" if depth_table == 1 => {
                            if let Some(table) = table_stack.pop() {
                                blocks.push(Block::Table(table));
                            }
                            depth_table = depth_table.saturating_sub(1);
                        }
                        "tbl" => {
                            depth_table = depth_table.saturating_sub(1);
                        }
                        _ => {}
                    }
                }
                Ok(Event::Eof) => break,
                Err(e) => {
                    return Err(DocxError::XmlParse {
                        part: "document.xml".to_string(),
                        source: e,
                    })
                }
                _ => {}
            }
            buf.clear();
        }

        Ok((blocks, tracked, images))
    }
}

fn push_run_to_context(run: Run, para_stack: &mut Vec<Paragraph>, cell_stack: &mut Vec<TableCell>) {
    // Runs go into the innermost paragraph in the cell or document body.
    if let Some(para) = para_stack.last_mut() {
        para.runs.push(run);
    }
    let _ = cell_stack; // cell paragraphs are pushed via para_stack indirectly
}

// ---------------------------------------------------------------------------
// Comments
// ---------------------------------------------------------------------------

pub fn parse_comments(xml: &str) -> Vec<Comment> {
    let mut comments = Vec::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(false);
    let mut buf = Vec::new();
    let mut in_comment = false;
    let mut current = Comment {
        id: String::new(),
        author: String::new(),
        date: None,
        initials: None,
        paragraphs: Vec::new(),
        parent_id: None,
    };
    let mut in_run = false;
    let mut in_t = false;
    let mut current_text = String::new();
    let mut current_para = Paragraph::default();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "comment" => {
                        in_comment = true;
                        current = Comment {
                            id: String::new(),
                            author: String::new(),
                            date: None,
                            initials: None,
                            paragraphs: Vec::new(),
                            parent_id: None,
                        };
                        for attr in e.attributes().flatten() {
                            match attr.key.as_ref() {
                                b"w:id" => {
                                    current.id = String::from_utf8_lossy(&attr.value).to_string()
                                }
                                b"w:author" => {
                                    current.author =
                                        String::from_utf8_lossy(&attr.value).to_string()
                                }
                                b"w:date" => {
                                    current.date =
                                        Some(String::from_utf8_lossy(&attr.value).to_string())
                                }
                                b"w:initials" => {
                                    current.initials =
                                        Some(String::from_utf8_lossy(&attr.value).to_string())
                                }
                                b"w:paraIdParent" => {
                                    current.parent_id =
                                        Some(String::from_utf8_lossy(&attr.value).to_string())
                                }
                                _ => {}
                            }
                        }
                    }
                    "r" if in_comment => in_run = true,
                    "t" if in_run => in_t = true,
                    "p" if in_comment => current_para = Paragraph::default(),
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
                    "r" if in_comment => {
                        if !current_text.is_empty() {
                            current_para.runs.push(Run {
                                text: current_text.clone(),
                                ..Default::default()
                            });
                            current_text.clear();
                        }
                        in_run = false;
                    }
                    "p" if in_comment => {
                        current.paragraphs.push(current_para.clone());
                        current_para = Paragraph::default();
                    }
                    "comment" => {
                        comments.push(current.clone());
                        in_comment = false;
                    }
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    comments
}

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
                        note_id = e
                            .attributes()
                            .flatten()
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

// ---------------------------------------------------------------------------
// Numbering
// ---------------------------------------------------------------------------

/// Parse `word/numbering.xml` and return `{ numId -> ListType }`.
pub fn parse_numbering(xml: &str) -> HashMap<String, ListType> {
    // First pass: abstractNumId -> format
    let mut abstract_formats: HashMap<String, ListType> = HashMap::new();
    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut current_abstract_id = String::new();
    let mut in_abstract = false;
    let mut in_level = false;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "abstractNum" => {
                        in_abstract = true;
                        current_abstract_id = e
                            .attributes()
                            .flatten()
                            .find(|a| a.key.as_ref() == b"w:abstractNumId")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string())
                            .unwrap_or_default();
                    }
                    "lvl" if in_abstract => in_level = true,
                    "numFmt" if in_level => {
                        if let Some(val) = e
                            .attributes()
                            .flatten()
                            .find(|a| a.key.as_ref() == b"w:val")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string())
                        {
                            let lt = if val == "bullet" || val == "none" {
                                ListType::Unordered
                            } else {
                                ListType::Ordered
                            };
                            abstract_formats
                                .entry(current_abstract_id.clone())
                                .or_insert(lt);
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::End(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "abstractNum" => in_abstract = false,
                    "lvl" => in_level = false,
                    _ => {}
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    // Second pass: num -> abstractNumId, build numId -> ListType
    let mut result: HashMap<String, ListType> = HashMap::new();
    let mut reader2 = Reader::from_str(xml);
    reader2.trim_text(true);
    let mut buf2 = Vec::new();
    let mut in_num = false;
    let mut num_id = String::new();

    loop {
        match reader2.read_event_into(&mut buf2) {
            Ok(Event::Start(ref e)) | Ok(Event::Empty(ref e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).to_string();
                match local.as_str() {
                    "num" if !in_num => {
                        in_num = true;
                        num_id = e
                            .attributes()
                            .flatten()
                            .find(|a| a.key.as_ref() == b"w:numId")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string())
                            .unwrap_or_default();
                    }
                    "abstractNumId" if in_num => {
                        if let Some(abs_id) = e
                            .attributes()
                            .flatten()
                            .find(|a| a.key.as_ref() == b"w:val")
                            .map(|a| String::from_utf8_lossy(&a.value).to_string())
                        {
                            let lt = abstract_formats
                                .get(&abs_id)
                                .cloned()
                                .unwrap_or(ListType::Unordered);
                            result.insert(num_id.clone(), lt);
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::End(ref e)) => {
                if e.local_name().as_ref() == b"num" {
                    in_num = false;
                }
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf2.clear();
    }
    result
}

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
                    "p" => {
                        in_para = true;
                        current_para = Paragraph::default();
                    }
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

pub fn parse_alignment(val: &str) -> Option<Alignment> {
    Some(match val {
        "left" | "start" => Alignment::Left,
        "center" => Alignment::Center,
        "right" | "end" => Alignment::Right,
        "both" | "distribute" => Alignment::Justify,
        _ => return None,
    })
}

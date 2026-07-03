


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
    pub fn parse(
        &self,
        xml: &str,
    ) -> Result<(Vec<Block>, Vec<TrackedChange>, Vec<ImageRef>)> {
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
        let mut in_hyperlink = false;
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
        let mut in_fldchar = false;
        let mut _fldchar_type = String::new();

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
                            in_hyperlink = true;
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
                            img_width = attr_val!(e, b"cx")
                                .and_then(|v| v.parse().ok());
                            img_height = attr_val!(e, b"cy")
                                .and_then(|v| v.parse().ok());
                        }
                        "docPr" if in_drawing => {
                            img_desc = attr_val!(e, b"descr");
                        }
                        "fldChar" => {
                            _fldchar_type = attr_val!(e, b"w:fldCharType").unwrap_or_default();
                            in_fldchar = true;
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
                                            let digits: String = lower_id.chars().filter(|c| c.is_ascii_digit()).collect();
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
                                r.formatting.size = attr_val!(e, b"w:val").and_then(|v| v.parse().ok());
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
                                    img_rel_id = Some(String::from_utf8_lossy(&attr.value).to_string());
                                }
                            }
                        }
                        "extent" if in_drawing => {
                            img_width = e.attributes().flatten()
                                .find(|a| a.key.as_ref() == b"cx")
                                .and_then(|a| String::from_utf8_lossy(&a.value).parse().ok());
                            img_height = e.attributes().flatten()
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
                                push_run_to_context(
                                    r,
                                    &mut para_stack,
                                    &mut cell_stack,
                                );
                            }
                            in_run = false;
                            if in_ins {
                                // run ended; ins tracking continues
                            }
                        }
                        "hyperlink" => {
                            in_hyperlink = false;
                            hyperlink_url = None;
                        }
                        "del" => {
                            tracked.push(TrackedChange {
                                id: tc_id.clone(),
                                change_type: ChangeType::Deletion,
                                author: tc_author.clone(),
                                date: if tc_date.is_empty() { None } else { Some(tc_date.clone()) },
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
                                date: if tc_date.is_empty() { None } else { Some(tc_date.clone()) },
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
                                        target: format!("word/{}", target.trim_start_matches("../")),
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
                Err(e) => return Err(DocxError::XmlParse {
                    part: "document.xml".to_string(),
                    source: e,
                }),
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

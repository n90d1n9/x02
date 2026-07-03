// src/parser.rs

use crate::writer::{CellValue, XlsxDateTime};
use chrono::{Datelike, NaiveDate, NaiveDateTime, Timelike};
use meval::eval_str;
use quick_xml::events::Event;
use quick_xml::Reader;
use std::io::Read;
use zip::ZipArchive;

/// Request to parse an XLSX workbook from in‑memory bytes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct XlsxParseRequest {
    pub bytes: Vec<u8>,
}

impl XlsxParseRequest {
    pub fn from_bytes(bytes: impl Into<Vec<u8>>) -> Self {
        Self {
            bytes: bytes.into(),
        }
    }
    pub fn byte_len(&self) -> usize {
        self.bytes.len()
    }
}

/// Result of a lightweight parse – currently just sheet names.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct XlsxParseResult {
    /// Names of the worksheets present in the workbook.
    pub sheet_names: Vec<String>,
}

/// Parse the workbook XML to obtain sheet names.
pub fn parse_xlsx(data: &[u8]) -> Result<XlsxParseResult, &'static str> {
    let cursor = std::io::Cursor::new(data);
    let mut archive = ZipArchive::new(cursor).map_err(|_| "Failed to read ZIP archive")?;

    // 1. Extract sheet names from xl/workbook.xml
    let mut workbook_xml = String::new();
    {
        let mut wb_file = archive
            .by_name("xl/workbook.xml")
            .map_err(|_| "Missing xl/workbook.xml")?;
        wb_file
            .read_to_string(&mut workbook_xml)
            .map_err(|_| "Failed to read workbook.xml")?;
    }

    let mut sheet_names = Vec::new();
    let mut reader = Reader::from_str(&workbook_xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    loop {
        let ev = reader
            .read_event_into(&mut buf)
            .map_err(|_| "Failed to parse workbook.xml")?;
        match ev {
            Event::Empty(e) if e.name().as_ref() == b"sheet" => {
                if let Some(attr) = e
                    .attributes()
                    .filter_map(|a| a.ok())
                    .find(|a| a.key.as_ref() == b"name")
                {
                    let name = attr
                        .unescape_value()
                        .map_err(|_| "attr decode error")?
                        .to_string();
                    sheet_names.push(name);
                }
            }
            Event::Eof => break,
            _ => {}
        }
        buf.clear();
    }
    Ok(XlsxParseResult { sheet_names })
}

/// Helper: parse shared strings into a Vec<String>.
fn parse_shared_strings<R: Read + std::io::Seek>(
    archive: &mut ZipArchive<R>,
) -> Result<Vec<String>, &'static str> {
    let mut ss_xml = String::new();
    let mut ss_file = archive
        .by_name("xl/sharedStrings.xml")
        .map_err(|_| "Missing sharedStrings.xml")?;
    ss_file
        .read_to_string(&mut ss_xml)
        .map_err(|_| "Failed to read sharedStrings.xml")?;
    let mut reader = Reader::from_str(&ss_xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut strings = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) if e.name().as_ref() == b"t" => {
                // Text node inside <si>
                if let Ok(Event::Text(t)) = reader.read_event_into(&mut buf) {
                    let txt = t.unescape().unwrap_or_default().into_owned();
                    strings.push(txt);
                }
            }
            Ok(Event::Eof) => break,
            Err(_) => return Err("Failed to parse sharedStrings.xml"),
            _ => {}
        }
        buf.clear();
    }
    Ok(strings)
}

/// Read a specific cell value from a sheet.
/// Returns a `CellValue` enum matching the stored type.
pub fn read_cell(
    request: &XlsxParseRequest,
    sheet_name: &str,
    cell_ref: &str,
) -> Result<CellValue, &'static str> {
    // Open archive once.
    let cursor = std::io::Cursor::new(&request.bytes);
    let mut archive = ZipArchive::new(cursor).map_err(|_| "Failed to read ZIP archive")?;

    // Resolve sheet index.
    let result = parse_xlsx(&request.bytes)?;
    let sheet_idx = result
        .sheet_names
        .iter()
        .position(|n| n == sheet_name)
        .ok_or("Sheet not found")?;
    let sheet_path = format!("xl/worksheets/sheet{}.xml", sheet_idx + 1);

    // Load worksheet XML.
    let mut sheet_xml = String::new();
    {
        let mut sheet_file = archive
            .by_name(&sheet_path)
            .map_err(|_| "Missing worksheet XML")?;
        sheet_file
            .read_to_string(&mut sheet_xml)
            .map_err(|_| "Failed to read worksheet XML")?;
    }

    // Parse shared strings if needed (lazy – only when we encounter a shared string).
    let mut shared_strings: Option<Vec<String>> = None;

    // Scan for the target cell, handling strings, numbers, booleans, dates, and formulas.
    let mut reader = Reader::from_str(&sheet_xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut in_target = false;
    let mut cell_type: Option<String> = None;
    let mut cell_value: Option<String> = None;
    let mut in_formula = false;
    let mut formula_text: Option<String> = None;
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) if e.name().as_ref() == b"c" => {
                // Determine if this is the cell we want and capture its type.
                let mut is_target = false;
                let mut typ: Option<String> = None;
                for attr in e.attributes().filter_map(|a| a.ok()) {
                    match attr.key.as_ref() {
                        b"r" => {
                            let cref = attr.unescape_value().unwrap_or_default();
                            if cref == cell_ref {
                                is_target = true;
                            }
                        }
                        b"t" => {
                            typ = Some(attr.unescape_value().unwrap_or_default().to_string());
                        }
                        _ => {}
                    }
                }
                if is_target {
                    in_target = true;
                    cell_type = typ;
                }
            }
            Ok(Event::Start(e)) if in_target && e.name().as_ref() == b"f" => {
                // Start of a formula element.
                in_formula = true;
                formula_text = Some(String::new());
            }
            Ok(Event::Text(e)) if in_target => {
                if in_formula {
                    // Accumulate formula characters.
                    if let Some(ref mut txt) = formula_text {
                        txt.push_str(&e.unescape().unwrap_or_default());
                    }
                } else {
                    cell_value = Some(e.unescape().unwrap_or_default().into_owned());
                }
            }
            Ok(Event::End(e)) if e.name().as_ref() == b"c" => {
                if in_target {
                    // Resolve based on captured data.
                    if let Some(fml) = formula_text.take() {
                        // Try to evaluate the formula as a numeric expression.
                        // If evaluation succeeds, return Number, otherwise keep raw formula.
                        if let Ok(val) = eval_str(&fml) {
                            return Ok(CellValue::Number(val));
                        } else {
                            return Ok(CellValue::Formula(fml));
                        }
                    }
                    let raw = cell_value.ok_or("Cell has no value")?;
                    let result = match cell_type.as_deref() {
                        Some("s") => {
                            // Shared string – resolve index.
                            let idx: usize =
                                raw.parse().map_err(|_| "Invalid shared string index")?;
                            if shared_strings.is_none() {
                                shared_strings = Some(parse_shared_strings(&mut archive)?);
                            }
                            let ss = shared_strings.as_ref().unwrap();
                            let txt = ss.get(idx).ok_or("Shared string out of range")?.clone();
                            CellValue::String(txt)
                        }
                        Some("b") => {
                            let b = raw == "1";
                            CellValue::Bool(b)
                        }
                        Some("d") => xlsx_datetime_from_iso(&raw)
                            .map(CellValue::DateTime)
                            .unwrap_or(CellValue::String(raw)),
                        Some("str") | Some("inlineStr") => CellValue::String(raw),
                        _ => {
                            let n: f64 = raw.parse().map_err(|_| "Invalid number")?;
                            CellValue::Number(n)
                        }
                    };
                    return Ok(result);
                }
                // Reset state for next cell.
                in_target = false;
                in_formula = false;
                cell_type = None;
                cell_value = None;
                formula_text = None;
            }
            Ok(Event::End(e)) if e.name().as_ref() == b"f" => {
                // End of formula element – nothing to do here.
                in_formula = false;
            }
            Ok(Event::Eof) => break,
            Err(_) => return Err("Failed to parse worksheet XML"),
            _ => {}
        }
        buf.clear();
    }
    Err("Cell not found")
}

fn xlsx_datetime_from_iso(raw: &str) -> Option<XlsxDateTime> {
    if let Ok(dt) = NaiveDateTime::parse_from_str(raw, "%Y-%m-%dT%H:%M:%S") {
        return XlsxDateTime::new(
            dt.year(),
            dt.month(),
            dt.day(),
            dt.hour(),
            dt.minute(),
            dt.second(),
        );
    }

    let date = NaiveDate::parse_from_str(raw, "%Y-%m-%d").ok()?;
    XlsxDateTime::new(date.year(), date.month(), date.day(), 0, 0, 0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::writer::{write_xlsx, CellValue, XlsxWriteRequest};

    #[test]
    fn tracks_request_size() {
        let request = XlsxParseRequest::from_bytes([1, 2, 3]);
        assert_eq!(request.byte_len(), 3);
    }

    #[test]
    fn reads_cells_round_trip() {
        // Build a simple workbook.
        let mut req = XlsxWriteRequest::new(["Sheet1"]);
        req.add_cell("Sheet1", "A1", CellValue::String("Hello".into()));
        req.add_cell("Sheet1", "B2", CellValue::Number(42.0));
        req.add_cell("Sheet1", "C3", CellValue::Bool(true));
        let data = write_xlsx(&req).expect("write failed");
        let parse_req = XlsxParseRequest::from_bytes(data);
        // Verify each cell.
        let a1 = read_cell(&parse_req, "Sheet1", "A1").expect("read A1");
        assert_eq!(a1, CellValue::String("Hello".into()));
        let b2 = read_cell(&parse_req, "Sheet1", "B2").expect("read B2");
        assert_eq!(b2, CellValue::Number(42.0));
        let c3 = read_cell(&parse_req, "Sheet1", "C3").expect("read C3");
        assert_eq!(c3, CellValue::Bool(true));
    }
}

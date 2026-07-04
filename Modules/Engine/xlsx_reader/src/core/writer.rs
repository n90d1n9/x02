// src/writer.rs

#[cfg(feature = "chart")]
use crate::chart::Chart;
#[cfg(feature = "chart")]
use crate::image::ImageAnchor;
#[cfg(feature = "chart")]
use serde_json;
use std::collections::HashMap;
use std::io::Write;
use zip::write::{FileOptions, ZipWriter};
use zip::CompressionMethod;

/// Represents a Gregorian date-time value that can be written as an Excel serial number.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct XlsxDateTime {
    /// Gregorian calendar year.
    pub year: i32,
    /// Gregorian calendar month, from 1 to 12.
    pub month: u32,
    /// Gregorian calendar day, valid for the selected month and year.
    pub day: u32,
    /// Hour of day in 24-hour time.
    pub hour: u32,
    /// Minute within the hour.
    pub minute: u32,
    /// Second within the minute.
    pub second: u32,
}

/// Binary image payload attached to a worksheet cell anchor.

#[cfg(feature = "chart")]
const TRANSPARENT_PNG: &[u8] = &[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x00, 0x00, 0x00,
    0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
];
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageData {
    /// Raw image bytes to write into the XLSX media folder.
    pub data: Vec<u8>,
    /// Media type such as `image/png` or `image/jpeg`.
    pub mime_type: String,
}

impl XlsxDateTime {
    /// Create a validated date-time value for XLSX serialization.
    pub fn new(
        year: i32,
        month: u32,
        day: u32,
        hour: u32,
        minute: u32,
        second: u32,
    ) -> Option<Self> {
        if !(1..=12).contains(&month)
            || day == 0
            || day > days_in_month(year, month)
            || hour > 23
            || minute > 59
            || second > 59
        {
            return None;
        }

        Some(Self {
            year,
            month,
            day,
            hour,
            minute,
            second,
        })
    }

    /// Convert the date-time into the serial number Excel stores in cells.
    pub fn excel_serial_number(&self) -> f64 {
        let epoch_days = days_from_civil(1899, 12, 30);
        let date_days = days_from_civil(self.year, self.month, self.day);
        let seconds = self.hour as f64 * 3_600.0 + self.minute as f64 * 60.0 + self.second as f64;

        (date_days - epoch_days) as f64 + seconds / 86_400.0
    }
}

/// Request model for generating a workbook in memory.
#[derive(Debug, Clone, PartialEq)]
pub struct XlsxWriteRequest {
    /// Ordered worksheet names to create in the workbook.
    pub sheet_names: Vec<String>,
    /// Map of sheet name to cell references and values.
    pub sheet_cells: HashMap<String, Vec<(String, CellValue)>>,
    /// Map of sheet name to merged cell ranges in A1 notation.
    pub merged_cells: HashMap<String, Vec<(String, String)>>,
    /// Map of sheet name to image anchors and image payloads.
    pub images: HashMap<String, Vec<(String, ImageData)>>,
    #[cfg(feature = "chart")]
    /// Map of sheet name to charts and their anchors.
    pub charts: HashMap<String, Vec<(Chart, ImageAnchor)>>,
}

/// Describes the supported primitive values that can be written into an XLSX cell.
#[derive(Debug, Clone, PartialEq)]
pub enum CellValue {
    /// UTF-8 string stored through the shared string table.
    String(String),
    /// Floating-point numeric value.
    Number(f64),
    /// Boolean value.
    Bool(bool),
    /// Date-time value written as an Excel serial number.
    DateTime(XlsxDateTime),
    /// Formula expression without a cached value.
    Formula(String),
}

impl XlsxWriteRequest {
    pub fn new<S: Into<String>, I: IntoIterator<Item = S>>(sheet_names: I) -> Self {
        Self {
            sheet_names: sheet_names.into_iter().map(Into::into).collect(),
            sheet_cells: HashMap::new(),
            merged_cells: HashMap::new(),
            images: HashMap::new(),
            #[cfg(feature = "chart")]
            charts: HashMap::new(),
        }
    }

    /// Add a merged cell range to a specific sheet.
    /// `start_ref` and `end_ref` are in A1 notation (e.g., "A1", "C3").
    pub fn add_merged_range<S: Into<String>>(&mut self, sheet_name: S, start_ref: S, end_ref: S) {
        let name = sheet_name.into();
        self.merged_cells
            .entry(name)
            .or_insert_with(Vec::new)
            .push((start_ref.into(), end_ref.into()));
    }

    /// Add an image to a specific sheet.
    /// `cell_ref` indicates the top‑left cell where the image should be anchored.
    /// `data` is the raw image bytes, `mime_type` is the image media type (e.g., "image/png").
    pub fn add_image<S: Into<String>>(
        &mut self,
        sheet_name: S,
        cell_ref: S,
        data: Vec<u8>,
        mime_type: String,
    ) {
        let name = sheet_name.into();
        let img = ImageData { data, mime_type };
        self.images
            .entry(name)
            .or_insert_with(Vec::new)
            .push((cell_ref.into(), img));
    }

    /// Add a chart to a specific sheet.
    /// `anchor` defines the placement similar to an image anchor.
    #[cfg(feature = "chart")]
    pub fn add_chart<S: Into<String>>(&mut self, sheet_name: S, chart: Chart, anchor: ImageAnchor) {
        let name = sheet_name.into();
        self.charts
            .entry(name)
            .or_insert_with(Vec::new)
            .push((chart, anchor));
    }

    pub fn sheet_count(&self) -> usize {
        self.sheet_names.len()
    }

    /// Add a cell value to a specific sheet.
    /// `cell_ref` should be in A1 notation.
    pub fn add_cell<S: Into<String>>(&mut self, sheet_name: S, cell_ref: S, value: CellValue) {
        let name = sheet_name.into();
        self.sheet_cells
            .entry(name)
            .or_insert_with(Vec::new)
            .push((cell_ref.into(), value));
    }
}

/// Write an XLSX workbook to an in‑memory buffer according to the request.
/// Returns the binary XLSX data.
pub fn write_xlsx(request: &XlsxWriteRequest) -> Result<Vec<u8>, &'static str> {
    let buffer = std::io::Cursor::new(Vec::new());
    let mut zip = ZipWriter::new(buffer);
    let options = FileOptions::default().compression_method(CompressionMethod::Stored);

    let mut shared_strings: Vec<String> = Vec::new();
    for cells in request.sheet_cells.values() {
        for (_, val) in cells {
            if let CellValue::String(s) = val {
                if !shared_strings.contains(s) {
                    shared_strings.push(s.clone());
                }
            }
        }
    }

    let mut content_types = String::from(
        r#"<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
"#,
    );
    for (i, _name) in request.sheet_names.iter().enumerate() {
        content_types.push_str(&format!(
            "    <Override PartName=\"/xl/worksheets/sheet{}.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.worksheet+xml\"/>\n",
            i + 1
        ));
        #[cfg(feature = "chart")]
        if request
            .charts
            .get(_name)
            .map(|c| !c.is_empty())
            .unwrap_or(false)
        {
            content_types.push_str(&format!(
                "    <Override PartName=\"/xl/drawings/drawing{}.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.drawing+xml\"/>\n",
                i + 1
            ));
        }
    }
    if !shared_strings.is_empty() {
        content_types.push_str("    <Override PartName=\"/xl/sharedStrings.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings.xml\"/\n");
        // Add default content types for PNG and JSON extensions
        content_types.push_str("    <Default Extension=\"png\" ContentType=\"image/png\"/>\n");
        content_types
            .push_str("    <Default Extension=\"json\" ContentType=\"application/json\"/>\n");
    }
    content_types.push_str("</Types>\n");
    zip.start_file("[Content_Types].xml", options)
        .map_err(|_| "zip write error")?;
    zip.write_all(content_types.as_bytes())
        .map_err(|_| "zip write error")?;

    let rels = r#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
"#;
    zip.start_file("_rels/.rels", options)
        .map_err(|_| "zip write error")?;
    zip.write_all(rels.as_bytes())
        .map_err(|_| "zip write error")?;

    let mut workbook_xml = String::from(
        r#"<?xml version="1.0" encoding="UTF-8"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
    <sheets>
"#,
    );
    for (idx, name) in request.sheet_names.iter().enumerate() {
        let rid = format!("rId{}", idx + 1);
        let sheet_id = idx + 1;
        workbook_xml.push_str(&format!(
            "        <sheet name=\"{}\" sheetId=\"{}\" r:id=\"{}\"/>\n",
            xml_escape(name),
            sheet_id,
            rid
        ));
    }
    workbook_xml.push_str("    </sheets>\n</workbook>\n");
    zip.start_file("xl/workbook.xml", options)
        .map_err(|_| "zip write error")?;
    zip.write_all(workbook_xml.as_bytes())
        .map_err(|_| "zip write error")?;

    let mut wb_rels = String::from(
        r#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
"#,
    );
    for (idx, _name) in request.sheet_names.iter().enumerate() {
        let rid = format!("rId{}", idx + 1);
        wb_rels.push_str(&format!(
            "    <Relationship Id=\"{}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet{}.xml\"/>\n",
            rid, idx + 1
        ));
    }
    if !shared_strings.is_empty() {
        let shared_rid = format!("rId{}", request.sheet_names.len() + 1);
        wb_rels.push_str(&format!(
            "    <Relationship Id=\"{}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings\" Target=\"sharedStrings.xml\"/>\n",
            shared_rid
        ));
    }
    wb_rels.push_str("</Relationships>\n");
    zip.start_file("xl/_rels/workbook.xml.rels", options)
        .map_err(|_| "zip write error")?;
    zip.write_all(wb_rels.as_bytes())
        .map_err(|_| "zip write error")?;

    if !shared_strings.is_empty() {
        let mut ss_xml = String::from(
            r#"<?xml version="1.0" encoding="UTF-8"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="{count}" uniqueCount="{unique}">
"#,
        );
        ss_xml = ss_xml.replace("{count}", &shared_strings.len().to_string());
        ss_xml = ss_xml.replace("{unique}", &shared_strings.len().to_string());
        for s in &shared_strings {
            ss_xml.push_str(&format!("    <si><t>{}</t></si>\n", xml_escape(s)));
        }
        ss_xml.push_str("</sst>\n");
        zip.start_file("xl/sharedStrings.xml", options)
            .map_err(|_| "zip write error")?;
        zip.write_all(ss_xml.as_bytes())
            .map_err(|_| "zip write error")?;
    }

    let worksheet_start = r#"<?xml version="1.0" encoding="UTF-8"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
    <sheetData>
"#;
    for (idx, name) in request.sheet_names.iter().enumerate() {
        let mut ws = String::from(worksheet_start);
        if let Some(cells) = request.sheet_cells.get(name) {
            let mut rows: HashMap<usize, Vec<(String, CellValue)>> = HashMap::new();
            for (cell_ref, val) in cells {
                if let Some((row, _col)) = parse_cell_ref(cell_ref) {
                    rows.entry(row)
                        .or_default()
                        .push((cell_ref.clone(), val.clone()));
                }
            }
            let mut row_keys: Vec<usize> = rows.keys().cloned().collect();
            row_keys.sort_unstable();
            for row in row_keys {
                ws.push_str(&format!("        <row r=\"{}\">\n", row));
                for (cell_ref, val) in &rows[&row] {
                    match val {
                        CellValue::String(s) => {
                            let idx = shared_strings.iter().position(|x| x == s).unwrap();
                            ws.push_str(&format!(
                                "            <c r=\"{}\" t=\"s\"><v>{}</v></c>\n",
                                cell_ref, idx
                            ));
                        }
                        CellValue::Number(n) => {
                            ws.push_str(&format!(
                                "            <c r=\"{}\"><v>{}</v></c>\n",
                                cell_ref, n
                            ));
                        }
                        CellValue::Bool(b) => {
                            ws.push_str(&format!(
                                "            <c r=\"{}\" t=\"b\"><v>{}</v></c>\n",
                                cell_ref,
                                if *b { 1 } else { 0 }
                            ));
                        }
                        CellValue::DateTime(dt) => {
                            let serial = dt.excel_serial_number();
                            ws.push_str(&format!(
                                "            <c r=\"{}\"><v>{}</v></c>\n",
                                cell_ref, serial
                            ));
                        }
                        CellValue::Formula(f) => {
                            ws.push_str(&format!(
                                "            <c r=\"{}\"><f>{}</f></c>\n",
                                cell_ref,
                                xml_escape(f)
                            ));
                        }
                    }
                }
                ws.push_str("        </row>\n");
            }
        }
        ws.push_str("    </sheetData>\n");
        if let Some(merged) = request.merged_cells.get(name) {
            if !merged.is_empty() {
                ws.push_str("    <mergeCells count=\"");
                ws.push_str(&merged.len().to_string());
                ws.push_str("\">\n");
                for (start, end) in merged {
                    ws.push_str(&format!("        <mergeCell ref=\"{}:{}\"/>\n", start, end));
                }
                ws.push_str("    </mergeCells>\n");
            }
        }
        #[cfg(feature = "chart")]
        let has_charts = request
            .charts
            .get(name)
            .map(|c| !c.is_empty())
            .unwrap_or(false);
        #[cfg(not(feature = "chart"))]
        let has_charts = false;

        if has_charts {
            ws.push_str("    <drawing r:id=\"rIdDrawing\"/>\n");
        }
        ws.push_str("</worksheet>\n");
        let path = format!("xl/worksheets/sheet{}.xml", idx + 1);
        zip.start_file(&path, options)
            .map_err(|_| "zip write error")?;
        zip.write_all(ws.as_bytes())
            .map_err(|_| "zip write error")?;

        #[cfg(feature = "chart")]
        if has_charts {
            let sheet_rels = format!(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rIdDrawing" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="../drawings/drawing{}.xml"/>
</Relationships>
"#,
                idx + 1
            );
            zip.start_file(
                &format!("xl/worksheets/_rels/sheet{}.xml.rels", idx + 1),
                options,
            )
            .map_err(|_| "zip write error")?;
            zip.write_all(sheet_rels.as_bytes())
                .map_err(|_| "zip write error")?;

            let mut drawing_xml = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
"#,
            );
            let mut drawing_rels = String::from(
                r#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
"#,
            );

            if let Some(chs) = request.charts.get(name) {
                for (cidx, (_chart, anchor)) in chs.iter().enumerate() {
                    let rid = format!("rId{}", cidx + 1);
                    drawing_rels.push_str(&format!(
                        "    <Relationship Id=\"{}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"../media/chart{}_{}.png\"/>\n",
                        rid, idx + 1, cidx + 1
                    ));

                    let (col, row, col_to, row_to) = match anchor {
                        ImageAnchor::TwoCell { from, to, .. } => {
                            (from.col as u32, from.row, to.col as u32, to.row)
                        }
                        ImageAnchor::OneCell { from, .. } => (
                            from.col as u32,
                            from.row,
                            from.col as u32 + 10,
                            from.row + 15,
                        ),
                        ImageAnchor::Absolute { .. } => (0, 0, 10, 15),
                    };

                    drawing_xml.push_str(&format!(
                        r#"    <xdr:twoCellAnchor>
        <xdr:from><xdr:col>{}</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>{}</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from>
        <xdr:to><xdr:col>{}</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>{}</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to>
        <xdr:pic>
            <xdr:nvPicPr><xdr:cNvPr id="{}" name="Chart {}"/><xdr:cNvPicPr/></xdr:nvPicPr>
            <xdr:blipFill><a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="{}"/></xdr:blipFill>
            <xdr:spPr><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr>
        </xdr:pic>
        <xdr:clientData/>
    </xdr:twoCellAnchor>
"#,
                        col, row, col_to, row_to, cidx + 1, cidx + 1, rid
                    ));
                }
            }
            drawing_rels.push_str("</Relationships>\n");
            drawing_xml.push_str("</xdr:wsDr>\n");

            zip.start_file(
                &format!("xl/drawings/_rels/drawing{}.xml.rels", idx + 1),
                options,
            )
            .map_err(|_| "zip write error")?;
            zip.write_all(drawing_rels.as_bytes())
                .map_err(|_| "zip write error")?;

            zip.start_file(&format!("xl/drawings/drawing{}.xml", idx + 1), options)
                .map_err(|_| "zip write error")?;
            zip.write_all(drawing_xml.as_bytes())
                .map_err(|_| "zip write error")?;
        }
    }
    #[cfg(feature = "chart")]
    // Write chart JSON files and placeholder PNGs for each sheet
    for (idx, name) in request.sheet_names.iter().enumerate() {
        if let Some(chs) = request.charts.get(name) {
            for (cidx, (chart, _anchor)) in chs.iter().enumerate() {
                // Serialize chart to JSON
                let json_path = format!("xl/tenun/charts/chart{}_{}.json", idx + 1, cidx + 1);
                let json_bytes = serde_json::to_vec(chart).map_err(|_| "json serialize error")?;
                zip.start_file(&json_path, options)
                    .map_err(|_| "zip write error")?;
                zip.write_all(&json_bytes).map_err(|_| "zip write error")?;
                // Write transparent PNG placeholder
                let png_path = format!("xl/media/chart{}_{}.png", idx + 1, cidx + 1);
                zip.start_file(&png_path, options)
                    .map_err(|_| "zip write error")?;
                zip.write_all(TRANSPARENT_PNG)
                    .map_err(|_| "zip write error")?;
            }
        }
    }
    let buffer = zip.finish().map_err(|_| "zip finish error")?;
    Ok(buffer.into_inner())
}

// Helper: simple XML escape.
fn xml_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

// Parse an A1 style cell reference into (row number, column).
fn parse_cell_ref(cell_ref: &str) -> Option<(usize, String)> {
    let mut col = String::new();
    let mut row = String::new();
    for c in cell_ref.chars() {
        if c.is_ascii_alphabetic() {
            col.push(c);
        } else if c.is_ascii_digit() {
            row.push(c);
        } else {
            return None;
        }
    }
    if col.is_empty() || row.is_empty() {
        return None;
    }
    row.parse::<usize>().ok().map(|r| (r, col))
}

fn days_in_month(year: i32, month: u32) -> u32 {
    match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 if is_leap_year(year) => 29,
        2 => 28,
        _ => 0,
    }
}

fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

fn days_from_civil(year: i32, month: u32, day: u32) -> i64 {
    let year = year - (month <= 2) as i32;
    let era = if year >= 0 { year } else { year - 399 } / 400;
    let year_of_era = (year - era * 400) as u32;
    let month_position = if month > 2 { month - 3 } else { month + 9 };
    let day_of_year = (153 * month_position + 2) / 5 + day - 1;
    let day_of_era = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year;

    (era as i64) * 146_097 + day_of_era as i64 - 719_468
}

#[cfg(test)]
mod tests {
    use super::*;
    use calamine::{open_workbook_from_rs, Reader, Xlsx};

    #[test]
    fn tracks_requested_sheet_count() {
        let request = XlsxWriteRequest::new(["Sheet1", "Budget"]);
        assert_eq!(request.sheet_count(), 2);
    }

    #[test]
    fn writes_workbook_with_correct_sheet_names_and_values() {
        let mut req = XlsxWriteRequest::new(["Alpha", "Beta", "Gamma"]);
        req.add_cell("Alpha", "A1", CellValue::String("Hello".into()));
        req.add_cell("Beta", "B2", CellValue::Number(42.0));
        req.add_cell("Gamma", "C3", CellValue::Bool(true));
        let data = write_xlsx(&req).expect("write failed");
        let cursor = std::io::Cursor::new(data);
        let mut workbook: Xlsx<std::io::Cursor<Vec<u8>>> =
            open_workbook_from_rs(cursor).expect("open failed");
        // Verify sheet names
        assert_eq!(workbook.sheet_names(), vec!["Alpha", "Beta", "Gamma"]);
        // Verify string cell value in Alpha sheet
        if let Some(Ok(range)) = workbook.worksheet_range("Alpha") {
            // Access the first cell directly (A1 => row 0, col 0)
            if let Some(cell) = range.get((0, 0)) {
                use calamine::DataType;
                match cell {
                    DataType::String(s) => assert_eq!(s, "Hello"),
                    _ => panic!("Expected string in A1"),
                }
            } else {
                panic!("Cell A1 missing");
            }
        } else {
            panic!("Alpha sheet missing");
        }
    }

    #[test]
    fn converts_date_time_to_excel_serial_number() {
        let unix_epoch = XlsxDateTime::new(1970, 1, 1, 0, 0, 0).unwrap();
        let noon = XlsxDateTime::new(1970, 1, 1, 12, 0, 0).unwrap();

        assert_eq!(unix_epoch.excel_serial_number(), 25_569.0);
        assert_eq!(noon.excel_serial_number(), 25_569.5);
        assert!(XlsxDateTime::new(2026, 2, 29, 0, 0, 0).is_none());
    }
}

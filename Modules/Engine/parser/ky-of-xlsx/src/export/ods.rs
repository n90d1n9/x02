//! Minimal ODS export for XLSX write requests.

use crate::cell::CellAddress;
use crate::writer::{CellValue, XlsxWriteRequest};
use std::collections::BTreeMap;
use std::io::{Cursor, Write};
use zip::write::FileOptions;
use zip::{CompressionMethod, ZipWriter};

/// Write an [`XlsxWriteRequest`] as a minimal OpenDocument Spreadsheet package.
pub fn write_ods(request: &XlsxWriteRequest) -> Result<Vec<u8>, &'static str> {
    if request.sheet_names.is_empty() {
        return Err("No sheets to export");
    }

    let mut archive = ZipWriter::new(Cursor::new(Vec::new()));
    let stored = FileOptions::default().compression_method(CompressionMethod::Stored);
    let deflated = FileOptions::default().compression_method(CompressionMethod::Deflated);

    archive
        .start_file("mimetype", stored)
        .map_err(|_| "Failed to start ODS mimetype")?;
    archive
        .write_all(b"application/vnd.oasis.opendocument.spreadsheet")
        .map_err(|_| "Failed to write ODS mimetype")?;

    archive
        .start_file("META-INF/manifest.xml", deflated)
        .map_err(|_| "Failed to start ODS manifest")?;
    archive
        .write_all(manifest_xml().as_bytes())
        .map_err(|_| "Failed to write ODS manifest")?;

    archive
        .start_file("content.xml", deflated)
        .map_err(|_| "Failed to start ODS content")?;
    archive
        .write_all(content_xml(request).as_bytes())
        .map_err(|_| "Failed to write ODS content")?;

    archive
        .finish()
        .map(|cursor| cursor.into_inner())
        .map_err(|_| "Failed to finish ODS archive")
}

fn manifest_xml() -> String {
    r#"<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">
  <manifest:file-entry manifest:full-path="/" manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>
  <manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>
</manifest:manifest>"#
        .to_string()
}

fn content_xml(request: &XlsxWriteRequest) -> String {
    let mut xml = String::from(
        r#"<?xml version="1.0" encoding="UTF-8"?>
<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" office:version="1.2">
  <office:body>
    <office:spreadsheet>
"#,
    );

    for sheet_name in &request.sheet_names {
        xml.push_str(&format!(
            r#"      <table:table table:name="{}">
"#,
            escape_xml(sheet_name)
        ));
        xml.push_str(&sheet_rows_xml(
            request
                .sheet_cells
                .get(sheet_name)
                .map(Vec::as_slice)
                .unwrap_or_default(),
        ));
        xml.push_str("      </table:table>\n");
    }

    xml.push_str(
        r#"    </office:spreadsheet>
  </office:body>
</office:document-content>
"#,
    );
    xml
}

fn sheet_rows_xml(cells: &[(String, CellValue)]) -> String {
    let mut by_row: BTreeMap<u32, BTreeMap<u16, &CellValue>> = BTreeMap::new();
    for (cell_ref, value) in cells {
        if let Ok(address) = CellAddress::from_a1(cell_ref) {
            by_row
                .entry(address.row)
                .or_default()
                .insert(address.col, value);
        }
    }

    let mut xml = String::new();
    let mut next_row = 0;
    for (row, values) in by_row {
        if row > next_row {
            xml.push_str(&empty_rows_xml(row - next_row));
        }

        xml.push_str("        <table:table-row>");
        let mut next_col = 0;
        for (col, value) in values {
            if col as u32 > next_col {
                xml.push_str(&empty_cells_xml(col as u32 - next_col));
            }
            xml.push_str(&cell_xml(value));
            next_col = col as u32 + 1;
        }
        xml.push_str("</table:table-row>\n");
        next_row = row + 1;
    }

    xml
}

fn empty_rows_xml(count: u32) -> String {
    match count {
        0 => String::new(),
        1 => "        <table:table-row/>\n".to_string(),
        _ => format!(r#"        <table:table-row table:number-rows-repeated="{count}"/>"#) + "\n",
    }
}

fn empty_cells_xml(count: u32) -> String {
    match count {
        0 => String::new(),
        1 => r#"<table:table-cell/>"#.to_string(),
        _ => format!(r#"<table:table-cell table:number-columns-repeated="{count}"/>"#),
    }
}

fn cell_xml(value: &CellValue) -> String {
    match value {
        CellValue::String(text) => format!(
            r#"<table:table-cell office:value-type="string"><text:p>{}</text:p></table:table-cell>"#,
            escape_xml(text)
        ),
        CellValue::Number(number) => format!(
            r#"<table:table-cell office:value-type="float" office:value="{number}"><text:p>{number}</text:p></table:table-cell>"#
        ),
        CellValue::Bool(value) => format!(
            r#"<table:table-cell office:value-type="boolean" office:boolean-value="{value}"><text:p>{}</text:p></table:table-cell>"#,
            if *value { "TRUE" } else { "FALSE" }
        ),
        CellValue::DateTime(value) => {
            let formatted = format!(
                "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}",
                value.year, value.month, value.day, value.hour, value.minute, value.second
            );
            format!(
                r#"<table:table-cell office:value-type="date" office:date-value="{formatted}"><text:p>{formatted}</text:p></table:table-cell>"#
            )
        }
        CellValue::Formula(formula) => format!(
            r#"<table:table-cell office:value-type="string"><text:p>={}</text:p></table:table-cell>"#,
            escape_xml(formula)
        ),
    }
}

fn escape_xml(value: &str) -> String {
    value
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::writer::XlsxWriteRequest;

    #[test]
    fn writes_minimal_ods_archive() {
        let mut request = XlsxWriteRequest::new(["Sheet1"]);
        request.add_cell("Sheet1", "A1", CellValue::String("Hello ODS".to_string()));

        let bytes = write_ods(&request).unwrap();

        assert!(bytes.starts_with(b"PK"));
    }
}

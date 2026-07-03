use super::*;
use ky-of-xlsx::writer::{write_xlsx, CellValue, XlsxWriteRequest};

#[test]
fn summarizes_workbook_bytes_with_loaded_cell_counts() {
    let mut request = XlsxWriteRequest::new(["Data", "Calc"]);
    request.add_cell("Data", "A1", CellValue::String("Revenue".to_owned()));
    request.add_cell("Data", "B1", CellValue::Number(42.0));
    request.add_cell("Calc", "A1", CellValue::Bool(true));
    let bytes = write_xlsx(&request).expect("write workbook");

    let summary = summarize_workbook_bytes("book", &bytes, XlsxImportOptions::new())
        .expect("summarize workbook");

    assert_eq!(summary.sheet_names(), vec!["Data", "Calc"]);
    assert_eq!(summary.total_cell_count(), 3);
}

#[test]
fn applies_import_row_limit() {
    let mut request = XlsxWriteRequest::new(["Data"]);
    request.add_cell("Data", "A1", CellValue::String("Included".to_owned()));
    request.add_cell("Data", "A2", CellValue::String("Skipped".to_owned()));
    let bytes = write_xlsx(&request).expect("write workbook");

    let summary = summarize_workbook_bytes("book", &bytes, XlsxImportOptions::new().max_rows(1))
        .expect("summarize workbook");

    assert_eq!(summary.sheets[0].row_count, 1);
    assert_eq!(summary.total_cell_count(), 1);
}

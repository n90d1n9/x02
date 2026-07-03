use super::*;
use crate::{CellPosition, XlsxSheetClipboardPayload, XlsxSheetRange, XlsxWorkbookError};

#[test]
fn encodes_payload_as_spreadsheet_tsv() {
    let payload = XlsxSheetClipboardPayload::new(
        "Data",
        XlsxSheetRange::new(CellPosition::new(0, 0), CellPosition::new(2, 1)),
        vec![
            Some("Revenue".to_owned()),
            Some("North\tQ1".to_owned()),
            None,
            Some("Line 1\nLine 2".to_owned()),
            Some("quoted \"value\"".to_owned()),
            Some("120".to_owned()),
        ],
    );

    let text = XlsxClipboardTextCodec::encode(&payload).expect("tsv");

    assert_eq!(
        text,
        "Revenue\t\"North\tQ1\"\t\n\"Line 1\nLine 2\"\t\"quoted \"\"value\"\"\"\t120",
    );
}

#[test]
fn encodes_with_crlf_and_trailing_newline_options() {
    let payload = XlsxSheetClipboardPayload::new(
        "Data",
        XlsxSheetRange::new(CellPosition::new(0, 0), CellPosition::new(1, 1)),
        vec![
            Some("A".to_owned()),
            Some("B".to_owned()),
            Some("C".to_owned()),
            Some("D".to_owned()),
        ],
    );

    let text = XlsxClipboardTextCodec::encode_with_options(
        &payload,
        XlsxClipboardTextOptions::new()
            .with_crlf()
            .with_trailing_newline(),
    )
    .expect("tsv");

    assert_eq!(text, "A\tB\r\nC\tD\r\n");
}

#[test]
fn encodes_empty_string_distinct_from_clear_cell() {
    let payload = XlsxSheetClipboardPayload::new(
        "Data",
        XlsxSheetRange::new(CellPosition::new(0, 0), CellPosition::new(2, 0)),
        vec![Some("A".to_owned()), None, Some(String::new())],
    );

    let text = XlsxClipboardTextCodec::encode(&payload).expect("tsv");
    let restored = XlsxClipboardTextCodec::decode("clipboard", &text).expect("payload");

    assert_eq!(text, "A\t\t\"\"");
    assert_eq!(
        restored.raw_values(),
        &[Some("A".to_owned()), None, Some(String::new())],
    );
}

#[test]
fn decodes_tsv_and_pads_ragged_rows() {
    let payload =
        XlsxClipboardTextCodec::decode("clipboard", "Revenue\t\"North\tQ1\"\n\"Line 1\nLine 2\"")
            .expect("payload");

    assert_eq!(payload.source_sheet_name, "clipboard");
    assert_eq!(payload.source_range.start(), CellPosition::new(0, 0));
    assert_eq!(payload.source_range.end(), CellPosition::new(1, 1));
    assert_eq!(
        payload.raw_values(),
        &[
            Some("Revenue".to_owned()),
            Some("North\tQ1".to_owned()),
            Some("Line 1\nLine 2".to_owned()),
            None,
        ],
    );
}

#[test]
fn decodes_empty_unquoted_fields_as_clear_cells() {
    let payload = XlsxClipboardTextCodec::decode("clipboard", "\t\"\"\n").expect("payload");

    assert_eq!(payload.raw_values(), &[None, Some(String::new())],);
}

#[test]
fn reports_malformed_quoted_clipboard_text() {
    let error =
        XlsxClipboardTextCodec::decode("clipboard", "\"A\"B").expect_err("bad clipboard text");

    assert_eq!(
        error,
        XlsxWorkbookError::ClipboardTextParseFailed {
            row: 1,
            col: 1,
            message: "unexpected character after closing quote".to_owned(),
        },
    );
}

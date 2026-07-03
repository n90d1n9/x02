use super::{
    options::XlsxClipboardTextOptions,
    parser::{checked_range, parse_tsv, push_encoded_field},
};
use crate::{CellPosition, XlsxSheetClipboardPayload, XlsxWorkbookError};

/// Text codec for interoperating with spreadsheet clipboard TSV payloads.
pub struct XlsxClipboardTextCodec;

impl XlsxClipboardTextCodec {
    /// Encode a clipboard payload as tab-separated text.
    pub fn encode(payload: &XlsxSheetClipboardPayload) -> Result<String, XlsxWorkbookError> {
        Self::encode_with_options(payload, XlsxClipboardTextOptions::default())
    }

    /// Encode a clipboard payload as tab-separated text with explicit options.
    pub fn encode_with_options(
        payload: &XlsxSheetClipboardPayload,
        options: XlsxClipboardTextOptions,
    ) -> Result<String, XlsxWorkbookError> {
        payload.validate_cell_count()?;

        let mut text = String::new();
        for row in 0..payload.height() {
            if row > 0 {
                text.push_str(options.line_ending.as_str());
            }

            for col in 0..payload.width() {
                if col > 0 {
                    text.push('\t');
                }
                let value_index = row * payload.width() + col;
                if let Some(raw_content) = &payload.raw_values()[value_index] {
                    push_encoded_field(&mut text, raw_content);
                }
            }
        }

        if options.trailing_newline {
            text.push_str(options.line_ending.as_str());
        }

        Ok(text)
    }

    /// Decode tab-separated text into a clipboard payload starting at A1.
    pub fn decode(
        source_sheet_name: impl Into<String>,
        text: &str,
    ) -> Result<XlsxSheetClipboardPayload, XlsxWorkbookError> {
        Self::decode_at(source_sheet_name, CellPosition::new(0, 0), text)
    }

    /// Decode tab-separated text into a clipboard payload with an explicit source start.
    pub fn decode_at(
        source_sheet_name: impl Into<String>,
        source_start: CellPosition,
        text: &str,
    ) -> Result<XlsxSheetClipboardPayload, XlsxWorkbookError> {
        let rows = parse_tsv(text)?;
        let width = rows.iter().map(Vec::len).max().unwrap_or(1).max(1);
        let height = rows.len().max(1);
        let source_range = checked_range(source_start, width, height)?;
        let mut raw_values = Vec::with_capacity(width * height);

        for row in rows {
            let row_len = row.len();
            for field in row {
                raw_values.push(field.into_raw_value());
            }
            raw_values.extend(std::iter::repeat(None).take(width - row_len));
        }

        if raw_values.is_empty() {
            raw_values.push(None);
        }

        Ok(XlsxSheetClipboardPayload::new(
            source_sheet_name,
            source_range,
            raw_values,
        ))
    }
}

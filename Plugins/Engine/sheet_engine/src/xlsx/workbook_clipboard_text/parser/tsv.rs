//! TSV scanner for spreadsheet clipboard text.

use crate::XlsxWorkbookError;

use super::field::ParsedClipboardField;

pub(in crate::xlsx::workbook_clipboard_text) fn parse_tsv(
    text: &str,
) -> Result<Vec<Vec<ParsedClipboardField>>, XlsxWorkbookError> {
    let mut rows = vec![Vec::new()];
    let mut current = String::new();
    let mut current_quoted = false;
    let mut field_started = false;
    let mut in_quotes = false;
    let mut just_closed_quote = false;
    let mut ended_with_row_break = false;
    let mut row_index = 0usize;
    let mut col_index = 0usize;
    let mut chars = text.chars().peekable();

    while let Some(ch) = chars.next() {
        if in_quotes {
            match ch {
                '"' if chars.peek() == Some(&'"') => {
                    chars.next();
                    current.push('"');
                }
                '"' => {
                    in_quotes = false;
                    just_closed_quote = true;
                }
                _ => current.push(ch),
            }
            continue;
        }

        match ch {
            '"' if !field_started => {
                current_quoted = true;
                field_started = true;
                in_quotes = true;
                ended_with_row_break = false;
            }
            '\t' => {
                finish_field(&mut rows, &mut current, &mut current_quoted);
                field_started = false;
                just_closed_quote = false;
                ended_with_row_break = false;
                col_index += 1;
            }
            '\n' => {
                finish_row(
                    &mut rows,
                    &mut current,
                    &mut current_quoted,
                    &mut field_started,
                    &mut just_closed_quote,
                );
                ended_with_row_break = true;
                row_index += 1;
                col_index = 0;
            }
            '\r' => {
                if chars.peek() == Some(&'\n') {
                    chars.next();
                }
                finish_row(
                    &mut rows,
                    &mut current,
                    &mut current_quoted,
                    &mut field_started,
                    &mut just_closed_quote,
                );
                ended_with_row_break = true;
                row_index += 1;
                col_index = 0;
            }
            _ if just_closed_quote => {
                return Err(XlsxWorkbookError::ClipboardTextParseFailed {
                    row: row_index + 1,
                    col: col_index + 1,
                    message: "unexpected character after closing quote".to_owned(),
                });
            }
            '"' => {
                current.push(ch);
                field_started = true;
                just_closed_quote = false;
                ended_with_row_break = false;
            }
            _ => {
                current.push(ch);
                field_started = true;
                just_closed_quote = false;
                ended_with_row_break = false;
            }
        }
    }

    if in_quotes {
        return Err(XlsxWorkbookError::ClipboardTextParseFailed {
            row: row_index + 1,
            col: col_index + 1,
            message: "unterminated quoted field".to_owned(),
        });
    }

    if ended_with_row_break {
        if rows.last().is_some_and(Vec::is_empty) {
            rows.pop();
        }
    } else {
        finish_field(&mut rows, &mut current, &mut current_quoted);
    }

    if rows.is_empty() {
        rows.push(vec![ParsedClipboardField::new(String::new(), false)]);
    }

    Ok(rows)
}

fn finish_field(
    rows: &mut [Vec<ParsedClipboardField>],
    current: &mut String,
    current_quoted: &mut bool,
) {
    let field = ParsedClipboardField::new(std::mem::take(current), *current_quoted);
    rows.last_mut()
        .expect("parser always keeps a current row")
        .push(field);
    *current_quoted = false;
}

fn finish_row(
    rows: &mut Vec<Vec<ParsedClipboardField>>,
    current: &mut String,
    current_quoted: &mut bool,
    field_started: &mut bool,
    just_closed_quote: &mut bool,
) {
    finish_field(rows, current, current_quoted);
    rows.push(Vec::new());
    *field_started = false;
    *just_closed_quote = false;
}

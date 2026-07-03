//! Spreadsheet text field encoding helpers.

pub(in crate::xlsx::workbook_clipboard_text) fn push_encoded_field(text: &mut String, value: &str) {
    let needs_quotes = value.is_empty()
        || value.contains('\t')
        || value.contains('\n')
        || value.contains('\r')
        || value.contains('"');
    if !needs_quotes {
        text.push_str(value);
        return;
    }

    text.push('"');
    for ch in value.chars() {
        if ch == '"' {
            text.push('"');
        }
        text.push(ch);
    }
    text.push('"');
}

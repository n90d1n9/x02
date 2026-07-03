//! Parsed clipboard field model.

#[derive(Debug, Clone, PartialEq, Eq)]
pub(in crate::xlsx::workbook_clipboard_text) struct ParsedClipboardField {
    value: String,
    quoted: bool,
}

impl ParsedClipboardField {
    pub(in crate::xlsx::workbook_clipboard_text::parser) fn new(
        value: String,
        quoted: bool,
    ) -> Self {
        Self { value, quoted }
    }

    pub(in crate::xlsx::workbook_clipboard_text) fn into_raw_value(self) -> Option<String> {
        if !self.quoted && self.value.is_empty() {
            None
        } else {
            Some(self.value)
        }
    }
}

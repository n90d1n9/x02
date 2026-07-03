use serde::{Deserialize, Serialize};

/// Result returned after copying a workbook sheet range as plain text.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxClipboardTextResult {
    pub sheet_name: String,
    pub text: String,
}

impl XlsxClipboardTextResult {
    /// Create a copied text result with the resolved workbook sheet name.
    pub fn new(sheet_name: impl Into<String>, text: impl Into<String>) -> Self {
        Self {
            sheet_name: sheet_name.into(),
            text: text.into(),
        }
    }
}

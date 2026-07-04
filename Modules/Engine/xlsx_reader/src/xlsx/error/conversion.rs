//! Lower-level XLSX error conversions.

use super::XlsxWorkbookError;

impl From<parser-xlsx::Error> for XlsxWorkbookError {
    fn from(value: parser-xlsx::Error) -> Self {
        Self::ReadFailed(value.to_string())
    }
}

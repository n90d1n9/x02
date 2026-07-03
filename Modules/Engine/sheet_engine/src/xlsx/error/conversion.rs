//! Lower-level XLSX error conversions.

use super::XlsxWorkbookError;

impl From<ky-of-xlsx::Error> for XlsxWorkbookError {
    fn from(value: ky-of-xlsx::Error) -> Self {
        Self::ReadFailed(value.to_string())
    }
}

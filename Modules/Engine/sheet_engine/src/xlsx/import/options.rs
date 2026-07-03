use ky-of-xlsx::OpenOptions;

/// Options for importing or summarizing workbook bytes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct XlsxImportOptions {
    /// File extension hint used by the lower-level reader.
    pub extension: String,
    /// Maximum number of rows to load per sheet; `0` means unlimited.
    pub max_rows: u32,
    /// Maximum number of columns to load per sheet; `0` means unlimited.
    pub max_cols: u16,
    /// Whether empty rows should be retained in the loaded workbook.
    pub include_empty_rows: bool,
}

impl Default for XlsxImportOptions {
    fn default() -> Self {
        Self {
            extension: "xlsx".to_owned(),
            max_rows: 0,
            max_cols: 0,
            include_empty_rows: false,
        }
    }
}

impl XlsxImportOptions {
    /// Create default import options for XLSX content.
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the file extension hint used by the reader.
    pub fn extension(mut self, extension: impl Into<String>) -> Self {
        self.extension = extension.into().trim_start_matches('.').to_owned();
        self
    }

    /// Limit loaded rows per sheet; `0` means unlimited.
    pub fn max_rows(mut self, max_rows: u32) -> Self {
        self.max_rows = max_rows;
        self
    }

    /// Limit loaded columns per sheet; `0` means unlimited.
    pub fn max_cols(mut self, max_cols: u16) -> Self {
        self.max_cols = max_cols;
        self
    }

    /// Retain empty rows in the loaded workbook.
    pub fn include_empty_rows(mut self, include_empty_rows: bool) -> Self {
        self.include_empty_rows = include_empty_rows;
        self
    }

    pub(crate) fn to_open_options(&self) -> OpenOptions {
        let mut options = OpenOptions::new()
            .max_rows(self.max_rows)
            .max_cols(self.max_cols);
        options.include_empty_rows = self.include_empty_rows;
        options
    }
}

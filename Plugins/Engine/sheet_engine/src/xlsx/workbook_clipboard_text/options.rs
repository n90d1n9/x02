use serde::{Deserialize, Serialize};

/// Line ending used when serializing a sheet clipboard payload as plain text.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum XlsxClipboardLineEnding {
    /// Use line-feed row separators.
    Lf,
    /// Use carriage-return and line-feed row separators.
    CrLf,
}

impl XlsxClipboardLineEnding {
    pub(crate) fn as_str(self) -> &'static str {
        match self {
            Self::Lf => "\n",
            Self::CrLf => "\r\n",
        }
    }
}

/// Options for converting sheet clipboard payloads to interoperability text.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxClipboardTextOptions {
    pub line_ending: XlsxClipboardLineEnding,
    pub trailing_newline: bool,
}

impl XlsxClipboardTextOptions {
    /// Create options with LF row separators and no trailing newline.
    pub fn new() -> Self {
        Self::default()
    }

    /// Return options using CRLF row separators.
    pub fn with_crlf(mut self) -> Self {
        self.line_ending = XlsxClipboardLineEnding::CrLf;
        self
    }

    /// Return options that append a final row separator after the last row.
    pub fn with_trailing_newline(mut self) -> Self {
        self.trailing_newline = true;
        self
    }
}

impl Default for XlsxClipboardTextOptions {
    fn default() -> Self {
        Self {
            line_ending: XlsxClipboardLineEnding::Lf,
            trailing_newline: false,
        }
    }
}

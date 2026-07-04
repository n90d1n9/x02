//! Per-cell update contract used by range edit transactions.

use serde::{Deserialize, Serialize};

use crate::{CellFormat, CellPosition, SheetEdit};

/// Per-cell update used by an XLSX range edit.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum XlsxRangeCellUpdate {
    /// Set a cell to the provided raw content.
    Set { raw_content: String },
    /// Set a cell to the provided raw content and format.
    SetWithFormat {
        raw_content: String,
        format: CellFormat,
    },
    /// Set only the cell format while preserving raw content.
    SetFormat { format: CellFormat },
    /// Remove a cell from the sheet.
    Clear,
}

impl XlsxRangeCellUpdate {
    /// Build a cell update that writes raw content.
    pub fn set(raw_content: impl Into<String>) -> Self {
        Self::Set {
            raw_content: raw_content.into(),
        }
    }

    /// Build a cell update that writes raw content and format together.
    pub fn set_with_format(raw_content: impl Into<String>, format: CellFormat) -> Self {
        Self::SetWithFormat {
            raw_content: raw_content.into(),
            format,
        }
    }

    /// Build a cell update that only writes format.
    pub fn set_format(format: CellFormat) -> Self {
        Self::SetFormat { format }
    }

    /// Build a cell update that clears the target cell.
    pub fn clear() -> Self {
        Self::Clear
    }

    pub(crate) fn to_sheet_edit(&self, position: CellPosition) -> SheetEdit {
        match self {
            Self::Set { raw_content } => SheetEdit::SetCell {
                position,
                raw_content: raw_content.clone(),
            },
            Self::SetWithFormat {
                raw_content,
                format,
            } => SheetEdit::SetCellWithFormat {
                position,
                raw_content: raw_content.clone(),
                format: format.clone(),
            },
            Self::SetFormat { format } => SheetEdit::SetCellFormat {
                position,
                format: format.clone(),
            },
            Self::Clear => SheetEdit::ClearCell { position },
        }
    }
}

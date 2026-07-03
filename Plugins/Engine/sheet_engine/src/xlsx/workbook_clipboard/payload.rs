//! Clipboard payload model and formula translation for copied workbook ranges.

use serde::{Deserialize, Serialize};

use crate::{
    translate_formula_references, CellFormat, FormulaReferenceOffset, XlsxRangeCellUpdate,
    XlsxSheetRange, XlsxWorkbookError,
};

/// Clipboard payload for a copied XLSX sheet range.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxSheetClipboardPayload {
    pub source_sheet_name: String,
    pub source_range: XlsxSheetRange,
    raw_values: Vec<Option<String>>,
    #[serde(default)]
    formats: Vec<Option<CellFormat>>,
}

impl XlsxSheetClipboardPayload {
    /// Create a clipboard payload from row-major raw values.
    pub fn new(
        source_sheet_name: impl Into<String>,
        source_range: XlsxSheetRange,
        raw_values: Vec<Option<String>>,
    ) -> Self {
        Self {
            source_sheet_name: source_sheet_name.into(),
            source_range,
            raw_values,
            formats: Vec::new(),
        }
    }

    /// Create a clipboard payload from row-major raw values and optional formats.
    pub fn new_with_formats(
        source_sheet_name: impl Into<String>,
        source_range: XlsxSheetRange,
        raw_values: Vec<Option<String>>,
        formats: Vec<Option<CellFormat>>,
    ) -> Self {
        Self {
            source_sheet_name: source_sheet_name.into(),
            source_range,
            raw_values,
            formats,
        }
    }

    /// Return copied values in row-major range order.
    pub fn raw_values(&self) -> &[Option<String>] {
        &self.raw_values
    }

    /// Return copied formats in row-major range order when available.
    pub fn formats(&self) -> &[Option<CellFormat>] {
        &self.formats
    }

    /// Return the copied range width.
    pub fn width(&self) -> usize {
        self.source_range.width()
    }

    /// Return the copied range height.
    pub fn height(&self) -> usize {
        self.source_range.height()
    }

    /// Return the number of copied cells expected by the source range.
    pub fn expected_cell_count(&self) -> usize {
        self.source_range.cell_count()
    }

    /// Return true when all copied cells are empty.
    pub fn is_empty(&self) -> bool {
        self.raw_values.iter().all(Option::is_none)
    }

    pub(crate) fn validate_cell_count(&self) -> Result<(), XlsxWorkbookError> {
        let expected = self.expected_cell_count();
        let actual = self.raw_values.len();
        if actual != expected {
            return Err(XlsxWorkbookError::ClipboardPayloadCellCountMismatch { expected, actual });
        }
        let actual_formats = self.formats.len();
        if actual_formats != 0 && actual_formats != expected {
            return Err(XlsxWorkbookError::ClipboardPayloadFormatCountMismatch {
                expected,
                actual: actual_formats,
            });
        }
        Ok(())
    }

    pub(crate) fn to_updates(&self) -> Vec<XlsxRangeCellUpdate> {
        self.raw_values
            .iter()
            .enumerate()
            .map(|(index, value)| self.to_update_at(index, value.as_ref().cloned()))
            .collect()
    }

    pub(crate) fn to_updates_for_target_range(
        &self,
        target_range: XlsxSheetRange,
        translate_formulas: bool,
    ) -> Vec<XlsxRangeCellUpdate> {
        if !translate_formulas {
            return self.to_updates();
        }

        self.source_range
            .positions()
            .into_iter()
            .zip(target_range.positions())
            .zip(self.raw_values.iter().enumerate())
            .map(|((source_position, target_position), value)| match value {
                (index, Some(raw_content)) if raw_content.starts_with('=') => {
                    let offset = FormulaReferenceOffset::from_cells(
                        source_position.col,
                        source_position.row,
                        target_position.col,
                        target_position.row,
                    );
                    self.to_update_at(
                        index,
                        Some(translate_formula_references(raw_content, offset)),
                    )
                }
                (index, raw_content) => self.to_update_at(index, raw_content.as_ref().cloned()),
            })
            .collect()
    }

    fn to_update_at(&self, index: usize, raw_content: Option<String>) -> XlsxRangeCellUpdate {
        let format = self.formats.get(index).and_then(Clone::clone);
        match (raw_content, format) {
            (Some(raw_content), Some(format)) => {
                XlsxRangeCellUpdate::set_with_format(raw_content, format)
            }
            (Some(raw_content), None) => XlsxRangeCellUpdate::set(raw_content),
            (None, Some(format)) => XlsxRangeCellUpdate::set_with_format("", format),
            (None, None) => XlsxRangeCellUpdate::clear(),
        }
    }
}

//! Reusable cell format patch model for toolbar and range actions.

use serde::{Deserialize, Serialize};

use crate::CellFormat;

use super::XlsxOptionalStringFormatPatch;

/// Partial cell format update for toolbar and range-format actions.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxCellFormatPatch {
    bold: Option<bool>,
    italic: Option<bool>,
    background_color: Option<XlsxOptionalStringFormatPatch>,
    text_color: Option<XlsxOptionalStringFormatPatch>,
    number_format: Option<XlsxOptionalStringFormatPatch>,
}

impl XlsxCellFormatPatch {
    /// Create an empty cell format patch.
    pub fn new() -> Self {
        Self::default()
    }

    /// Set whether the target cells should be bold.
    pub fn bold(mut self, value: bool) -> Self {
        self.bold = Some(value);
        self
    }

    /// Set whether the target cells should be italic.
    pub fn italic(mut self, value: bool) -> Self {
        self.italic = Some(value);
        self
    }

    /// Set the target cell background color.
    pub fn background_color(mut self, value: impl Into<String>) -> Self {
        self.background_color = Some(XlsxOptionalStringFormatPatch::Set(value.into()));
        self
    }

    /// Clear the target cell background color.
    pub fn clear_background_color(mut self) -> Self {
        self.background_color = Some(XlsxOptionalStringFormatPatch::Clear);
        self
    }

    /// Set the target cell text color.
    pub fn text_color(mut self, value: impl Into<String>) -> Self {
        self.text_color = Some(XlsxOptionalStringFormatPatch::Set(value.into()));
        self
    }

    /// Clear the target cell text color.
    pub fn clear_text_color(mut self) -> Self {
        self.text_color = Some(XlsxOptionalStringFormatPatch::Clear);
        self
    }

    /// Set the target cell number format.
    pub fn number_format(mut self, value: impl Into<String>) -> Self {
        self.number_format = Some(XlsxOptionalStringFormatPatch::Set(value.into()));
        self
    }

    /// Clear the target cell number format.
    pub fn clear_number_format(mut self) -> Self {
        self.number_format = Some(XlsxOptionalStringFormatPatch::Clear);
        self
    }

    /// Return true when this patch does not change any format field.
    pub fn is_empty(&self) -> bool {
        self.bold.is_none()
            && self.italic.is_none()
            && self.background_color.is_none()
            && self.text_color.is_none()
            && self.number_format.is_none()
    }

    /// Apply this patch to an existing cell format.
    pub fn apply_to(&self, format: &CellFormat) -> CellFormat {
        let mut next = format.clone();
        if let Some(value) = self.bold {
            next.bold = value;
        }
        if let Some(value) = self.italic {
            next.italic = value;
        }
        if let Some(update) = &self.background_color {
            update.apply_to(&mut next.background_color);
        }
        if let Some(update) = &self.text_color {
            update.apply_to(&mut next.text_color);
        }
        if let Some(update) = &self.number_format {
            update.apply_to(&mut next.number_format);
        }
        next
    }
}

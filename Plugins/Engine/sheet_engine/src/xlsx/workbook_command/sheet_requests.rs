//! Sheet lifecycle request contracts used by workbook command execution.

use serde::{Deserialize, Serialize};
use waraq_core::DocumentId;

use crate::XlsxWorkbookError;

/// Request for adding a new sheet to an XLSX workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxAddSheetRequest {
    sheet_name: String,
    document_id: Option<DocumentId>,
    index: Option<usize>,
}

impl XlsxAddSheetRequest {
    /// Create a request that appends a sheet and activates it.
    pub fn new(sheet_name: impl Into<String>) -> Self {
        Self {
            sheet_name: sheet_name.into(),
            document_id: None,
            index: None,
        }
    }

    /// Attach an explicit core document id for the new sheet.
    pub fn with_document_id(mut self, document_id: impl Into<DocumentId>) -> Self {
        self.document_id = Some(document_id.into());
        self
    }

    /// Insert the sheet at a specific workbook index.
    pub fn at_index(mut self, index: usize) -> Self {
        self.index = Some(index);
        self
    }

    /// Return the requested sheet name.
    pub fn sheet_name(&self) -> &str {
        &self.sheet_name
    }

    /// Return the requested document id, if provided.
    pub fn document_id(&self) -> Option<&DocumentId> {
        self.document_id.as_ref()
    }

    pub(crate) fn normalized_sheet_name(&self) -> String {
        self.sheet_name.trim().to_owned()
    }

    pub(crate) fn resolved_document_id(&self, workbook_id: &str, sheet_name: &str) -> DocumentId {
        self.document_id
            .clone()
            .unwrap_or_else(|| DocumentId::new(format!("{workbook_id}/{sheet_name}")))
    }

    pub(crate) fn insert_index(&self, sheet_count: usize) -> Result<usize, XlsxWorkbookError> {
        let index = self.index.unwrap_or(sheet_count);
        if index > sheet_count {
            return Err(XlsxWorkbookError::SheetIndexOutOfRange { index, sheet_count });
        }
        Ok(index)
    }
}

/// Request for renaming a sheet in an XLSX workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxRenameSheetRequest {
    sheet_name: String,
    new_sheet_name: String,
}

impl XlsxRenameSheetRequest {
    /// Create a request that renames an existing sheet.
    pub fn new(sheet_name: impl Into<String>, new_sheet_name: impl Into<String>) -> Self {
        Self {
            sheet_name: sheet_name.into(),
            new_sheet_name: new_sheet_name.into(),
        }
    }

    /// Return the sheet name to rename.
    pub fn sheet_name(&self) -> &str {
        &self.sheet_name
    }

    /// Return the requested new sheet name.
    pub fn new_sheet_name(&self) -> &str {
        &self.new_sheet_name
    }

    pub(crate) fn normalized_sheet_name(&self) -> String {
        self.sheet_name.trim().to_owned()
    }

    pub(crate) fn normalized_new_sheet_name(&self) -> String {
        self.new_sheet_name.trim().to_owned()
    }
}

/// Request for removing a sheet from an XLSX workbook session.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxRemoveSheetRequest {
    sheet_name: String,
}

impl XlsxRemoveSheetRequest {
    /// Create a request that removes an existing sheet.
    pub fn new(sheet_name: impl Into<String>) -> Self {
        Self {
            sheet_name: sheet_name.into(),
        }
    }

    /// Return the sheet name to remove.
    pub fn sheet_name(&self) -> &str {
        &self.sheet_name
    }

    pub(crate) fn normalized_sheet_name(&self) -> String {
        self.sheet_name.trim().to_owned()
    }
}

/// Request for moving a sheet to a new workbook index.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxMoveSheetRequest {
    sheet_name: String,
    target_index: usize,
}

impl XlsxMoveSheetRequest {
    /// Create a request that moves a sheet to a zero-based workbook index.
    pub fn new(sheet_name: impl Into<String>, target_index: usize) -> Self {
        Self {
            sheet_name: sheet_name.into(),
            target_index,
        }
    }

    /// Return the sheet name to move.
    pub fn sheet_name(&self) -> &str {
        &self.sheet_name
    }

    /// Return the target zero-based workbook index.
    pub fn target_index(&self) -> usize {
        self.target_index
    }

    pub(crate) fn normalized_sheet_name(&self) -> String {
        self.sheet_name.trim().to_owned()
    }
}

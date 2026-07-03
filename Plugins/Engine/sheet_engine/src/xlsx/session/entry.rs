//! Runtime entry model for one imported XLSX sheet session.

use crate::{sheet_session, SheetGrid, SheetSession};
use waraq_core::DocumentId;

/// Runtime sheet session entry created from a workbook sheet grid.
#[derive(Debug)]
pub struct XlsxSheetSessionEntry {
    sheet_name: String,
    document_id: DocumentId,
    session: SheetSession,
}

impl XlsxSheetSessionEntry {
    /// Return the workbook sheet name represented by this session.
    pub fn sheet_name(&self) -> &str {
        &self.sheet_name
    }

    /// Return the stable core document id attached to this sheet session.
    pub fn document_id(&self) -> &DocumentId {
        &self.document_id
    }

    /// Return the editable sheet session.
    pub fn session(&self) -> &SheetSession {
        &self.session
    }

    /// Return a mutable editable sheet session.
    pub fn session_mut(&mut self) -> &mut SheetSession {
        &mut self.session
    }

    /// Consume the entry and return the editable sheet session.
    pub fn into_session(self) -> SheetSession {
        self.session
    }

    pub(super) fn new(sheet_name: String, document_id: DocumentId, grid: SheetGrid) -> Self {
        Self {
            sheet_name,
            document_id: document_id.clone(),
            session: sheet_session(document_id, grid),
        }
    }

    pub(crate) fn from_session(sheet_name: impl Into<String>, session: SheetSession) -> Self {
        Self {
            sheet_name: sheet_name.into().trim().to_owned(),
            document_id: session.document_id().clone(),
            session,
        }
    }

    pub(crate) fn rename(&mut self, sheet_name: impl Into<String>) {
        self.sheet_name = sheet_name.into().trim().to_owned();
        self.session.state_mut().name = self.sheet_name.clone();
    }
}

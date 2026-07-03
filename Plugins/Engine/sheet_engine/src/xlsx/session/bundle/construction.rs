//! Construction helpers for workbook sheet-session bundles.

use std::collections::{BTreeMap, BTreeSet};

use waraq_core::DocumentId;

use crate::{SheetGrid, XlsxGridWorkbook, XlsxWorkbookError};

use super::{XlsxSheetSessionBundle, XlsxSheetSessionEntry};

impl XlsxSheetSessionBundle {
    pub(crate) fn from_entries(
        workbook_id: impl Into<String>,
        entries: Vec<XlsxSheetSessionEntry>,
    ) -> Result<Self, XlsxWorkbookError> {
        let bundle = Self {
            workbook_id: workbook_id.into().trim().to_owned(),
            entries,
        };
        bundle.validate()?;
        Ok(bundle)
    }

    /// Create sheet sessions using default workbook-prefixed document ids.
    pub fn from_grid_workbook(workbook: XlsxGridWorkbook) -> Self {
        let workbook_id = workbook.workbook_id().to_owned();
        let entries = workbook
            .into_sheets()
            .into_iter()
            .map(|grid| {
                let sheet_name = grid.name.trim().to_owned();
                let document_id = default_sheet_document_id(&workbook_id, &sheet_name);
                XlsxSheetSessionEntry::new(sheet_name, document_id, grid)
            })
            .collect();

        Self {
            workbook_id,
            entries,
        }
    }

    /// Create sheet sessions with caller-provided document ids.
    pub fn from_grid_workbook_with_ids<I, S, D>(
        workbook: XlsxGridWorkbook,
        sheet_document_ids: I,
    ) -> Result<Self, XlsxWorkbookError>
    where
        I: IntoIterator<Item = (S, D)>,
        S: Into<String>,
        D: Into<DocumentId>,
    {
        let workbook_id = workbook.workbook_id().to_owned();
        let sheets = workbook.into_sheets();
        let document_ids = index_sheet_document_ids(sheet_document_ids)?;
        validate_requested_sheets(&sheets, document_ids.keys())?;

        let entries = sheets
            .into_iter()
            .map(|grid| {
                let sheet_name = grid.name.trim().to_owned();
                let document_id = document_ids.get(&sheet_name).cloned().ok_or_else(|| {
                    XlsxWorkbookError::MissingSheetDocumentId {
                        sheet_name: sheet_name.clone(),
                    }
                })?;
                Ok(XlsxSheetSessionEntry::new(sheet_name, document_id, grid))
            })
            .collect::<Result<Vec<_>, XlsxWorkbookError>>()?;

        Ok(Self {
            workbook_id,
            entries,
        })
    }
}

fn default_sheet_document_id(workbook_id: &str, sheet_name: &str) -> DocumentId {
    DocumentId::new(format!("{workbook_id}/{sheet_name}"))
}

fn index_sheet_document_ids<I, S, D>(
    sheet_document_ids: I,
) -> Result<BTreeMap<String, DocumentId>, XlsxWorkbookError>
where
    I: IntoIterator<Item = (S, D)>,
    S: Into<String>,
    D: Into<DocumentId>,
{
    let mut indexed = BTreeMap::new();
    for (sheet_name, document_id) in sheet_document_ids {
        let sheet_name = sheet_name.into().trim().to_owned();
        let document_id = document_id.into();
        if document_id.as_str().trim().is_empty() {
            return Err(XlsxWorkbookError::EmptySheetDocumentId { sheet_name });
        }

        if indexed.insert(sheet_name.clone(), document_id).is_some() {
            return Err(XlsxWorkbookError::DuplicateSheetDocumentId { sheet_name });
        }
    }
    Ok(indexed)
}

fn validate_requested_sheets<'a>(
    sheets: &[SheetGrid],
    requested_sheet_names: impl IntoIterator<Item = &'a String>,
) -> Result<(), XlsxWorkbookError> {
    let sheet_names = sheets
        .iter()
        .map(|sheet| sheet.name.trim().to_owned())
        .collect::<BTreeSet<_>>();

    for sheet_name in requested_sheet_names {
        if !sheet_names.contains(sheet_name) {
            return Err(XlsxWorkbookError::UnknownSheetDocumentId {
                sheet_name: sheet_name.clone(),
            });
        }
    }

    Ok(())
}

use super::*;
use crate::{
    Cell, CellFormat, CellPosition, CellValue, SheetGrid, XlsxGridWorkbook, XlsxImportOptions,
    XlsxWorkbookError,
};
use waraq_core::DocumentId;
use ky-of-xlsx::writer::{write_xlsx, CellValue as WriterCellValue, XlsxWriteRequest};

fn grid_with_cell(name: &str, col: u32, row: u32, value: &str) -> SheetGrid {
    let mut grid = SheetGrid::new(name);
    grid.set_cell(
        CellPosition::new(col, row),
        Cell {
            raw_content: value.to_owned(),
            evaluated_value: CellValue::String(value.to_owned()),
            format: CellFormat::default(),
        },
    );
    grid
}

fn workbook() -> XlsxGridWorkbook {
    XlsxGridWorkbook::new(
        "book",
        [
            grid_with_cell("Data", 0, 0, "Revenue"),
            grid_with_cell("Calc", 1, 0, "Total"),
        ],
    )
    .expect("workbook")
}

#[test]
fn creates_default_sheet_sessions_in_workbook_order() {
    let sessions = XlsxSheetSessionBundle::from_grid_workbook(workbook());

    assert_eq!(sessions.workbook_id(), "book");
    assert_eq!(sessions.sheet_count(), 2);
    assert_eq!(sessions.sheet_names(), vec!["Data", "Calc"]);
    assert_eq!(
        sessions
            .session_for_sheet(" Data ")
            .expect("data session")
            .document_id(),
        &DocumentId::new("book/Data"),
    );
    assert_eq!(
        sessions
            .session_for_sheet("Calc")
            .expect("calc session")
            .session()
            .state()
            .cell_count(),
        1,
    );
}

#[test]
fn creates_sessions_with_explicit_document_ids() {
    let sessions = XlsxSheetSessionBundle::from_grid_workbook_with_ids(
        workbook(),
        [("Data", "sheet-doc-1"), ("Calc", "sheet-doc-2")],
    )
    .expect("sessions");

    assert_eq!(
        sessions
            .session_for_sheet("Data")
            .expect("data session")
            .document_id(),
        &DocumentId::new("sheet-doc-1"),
    );
    assert_eq!(
        sessions
            .session_for_sheet("Calc")
            .expect("calc session")
            .session()
            .document_id(),
        &DocumentId::new("sheet-doc-2"),
    );
}

#[test]
fn rejects_incomplete_or_unknown_document_id_maps() {
    assert_eq!(
        XlsxSheetSessionBundle::from_grid_workbook_with_ids(
            workbook(),
            [("Data", " "), ("Calc", "sheet-doc-2")],
        )
        .expect_err("empty id"),
        XlsxWorkbookError::EmptySheetDocumentId {
            sheet_name: "Data".to_owned(),
        },
    );

    assert_eq!(
        XlsxSheetSessionBundle::from_grid_workbook_with_ids(workbook(), [("Data", "sheet-doc-1")],)
            .expect_err("missing id"),
        XlsxWorkbookError::MissingSheetDocumentId {
            sheet_name: "Calc".to_owned(),
        },
    );

    assert_eq!(
        XlsxSheetSessionBundle::from_grid_workbook_with_ids(
            workbook(),
            [
                ("Data", "sheet-doc-1"),
                ("Calc", "sheet-doc-2"),
                ("Other", "sheet-doc-3"),
            ],
        )
        .expect_err("unknown sheet"),
        XlsxWorkbookError::UnknownSheetDocumentId {
            sheet_name: "Other".to_owned(),
        },
    );

    assert_eq!(
        XlsxSheetSessionBundle::from_grid_workbook_with_ids(
            workbook(),
            [
                ("Data", "sheet-doc-1"),
                (" Data ", "sheet-doc-2"),
                ("Calc", "sheet-doc-3"),
            ],
        )
        .expect_err("duplicate sheet"),
        XlsxWorkbookError::DuplicateSheetDocumentId {
            sheet_name: "Data".to_owned(),
        },
    );
}

#[test]
fn imports_workbook_bytes_into_sheet_sessions() {
    let mut request = XlsxWriteRequest::new(["Data"]);
    request.add_cell("Data", "A1", WriterCellValue::String("Revenue".to_owned()));
    let bytes = write_xlsx(&request).expect("xlsx bytes");

    let sessions =
        import_sheet_sessions_from_workbook_bytes("book", &bytes, XlsxImportOptions::new())
            .expect("sessions");

    let data = sessions.session_for_sheet("Data").expect("data session");
    assert_eq!(data.document_id(), &DocumentId::new("book/Data"));
    assert_eq!(
        data.session()
            .state()
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Revenue",
    );
}

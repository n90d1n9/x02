use crate::{
    Cell, CellFormat, CellPosition, CellValue, SheetGrid, XlsxImportOptions, XlsxWorkbookError,
    XlsxWorkbookRequest,
};
use ky-of-xlsx::writer::{write_xlsx, CellValue as WriterCellValue, XlsxWriteRequest};

use super::{grid_to_write_request, import_grids_from_workbook_bytes, write_grids_to_workbook};

#[test]
fn imports_workbook_bytes_into_sheet_grids() {
    let mut request = XlsxWriteRequest::new(["Data"]);
    request.add_cell("Data", "A1", WriterCellValue::String("Revenue".to_owned()));
    request.add_cell("Data", "B1", WriterCellValue::Number(42.0));
    request.add_cell("Data", "C1", WriterCellValue::Bool(true));
    let bytes = write_xlsx(&request).expect("write workbook");

    let grids = import_grids_from_workbook_bytes(&bytes, XlsxImportOptions::new()).expect("import");

    assert_eq!(grids.len(), 1);
    assert_eq!(grids[0].name, "Data");
    assert_eq!(grids[0].cell_count(), 3);
    assert_eq!(
        grids[0]
            .get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .evaluated_value,
        CellValue::Number(42.0),
    );
}

#[test]
fn exports_sheet_grids_into_workbook_bytes() {
    let mut grid = SheetGrid::new("Data");
    grid.set_cell(
        CellPosition::new(0, 0),
        Cell {
            raw_content: "Revenue".to_owned(),
            evaluated_value: CellValue::String("Revenue".to_owned()),
            format: CellFormat::default(),
        },
    );
    grid.set_cell(
        CellPosition::new(1, 0),
        Cell {
            raw_content: "42".to_owned(),
            evaluated_value: CellValue::Number(42.0),
            format: CellFormat::default(),
        },
    );

    let workbook_request = XlsxWorkbookRequest::new("book", ["Data"]);
    let bytes = write_grids_to_workbook(&workbook_request, &[grid]).expect("export");
    let grids = import_grids_from_workbook_bytes(&bytes, XlsxImportOptions::new()).expect("import");

    assert_eq!(grids[0].cell_count(), 2);
    assert_eq!(
        grids[0]
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Revenue",
    );
    assert_eq!(
        grids[0]
            .get_cell(&CellPosition::new(1, 0))
            .expect("B1")
            .evaluated_value,
        CellValue::Number(42.0),
    );
}

#[test]
fn rejects_missing_grid_for_requested_sheet() {
    let workbook_request = XlsxWorkbookRequest::new("book", ["Data"]);
    let err = grid_to_write_request(&workbook_request, &[]).expect_err("missing grid");

    assert_eq!(
        err,
        XlsxWorkbookError::MissingGridForSheet {
            name: "Data".to_owned(),
        },
    );
}

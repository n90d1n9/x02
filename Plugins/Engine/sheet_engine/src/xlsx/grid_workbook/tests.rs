use crate::{
    Cell, CellFormat, CellPosition, CellValue, SheetGrid, XlsxImportOptions, XlsxWorkbookError,
};

use super::{import_grid_workbook_bytes, write_grid_workbook, XlsxGridWorkbook};

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

#[test]
fn validates_grid_workbook_identity_and_sheet_names() {
    assert_eq!(
        XlsxGridWorkbook::new(" ", [grid_with_cell("Data", 0, 0, "A")]).expect_err("empty id"),
        XlsxWorkbookError::EmptyWorkbookId,
    );
    assert_eq!(
        XlsxGridWorkbook::new("book", std::iter::empty()).expect_err("empty workbook"),
        XlsxWorkbookError::EmptyWorkbook,
    );
    assert_eq!(
        XlsxGridWorkbook::new(
            "book",
            [
                grid_with_cell("Data", 0, 0, "A"),
                grid_with_cell(" Data ", 1, 0, "B"),
            ],
        )
        .expect_err("duplicate sheet"),
        XlsxWorkbookError::DuplicateGridName {
            name: "Data".to_owned(),
        },
    );
}

#[test]
fn summarizes_owned_sheet_grids() {
    let workbook = XlsxGridWorkbook::new(
        "book",
        [
            grid_with_cell("Data", 0, 0, "A"),
            grid_with_cell("Calc", 2, 4, "B"),
        ],
    )
    .expect("workbook");

    let summary = workbook.summary().expect("summary");

    assert_eq!(workbook.sheet_count(), 2);
    assert_eq!(workbook.total_cell_count(), 2);
    assert_eq!(workbook.sheet_names(), vec!["Data", "Calc"]);
    assert_eq!(summary.sheet_count(), 2);
    assert_eq!(summary.sheets[1].row_count, 1);
    assert_eq!(summary.sheets[1].col_count, 3);
}

#[test]
fn roundtrips_grid_workbook_bytes() {
    let workbook =
        XlsxGridWorkbook::new("book", [grid_with_cell("Data", 0, 0, "Revenue")]).expect("workbook");

    let bytes = write_grid_workbook(&workbook).expect("write workbook");
    let imported = import_grid_workbook_bytes("book", &bytes, XlsxImportOptions::new())
        .expect("import workbook");

    assert_eq!(imported.workbook_id(), "book");
    assert_eq!(imported.sheet_names(), vec!["Data"]);
    assert_eq!(
        imported
            .sheet_by_name("Data")
            .expect("sheet")
            .get_cell(&CellPosition::new(0, 0))
            .expect("A1")
            .raw_content,
        "Revenue",
    );
}

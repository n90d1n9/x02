use super::*;
use crate::XlsxWorkbookError;

#[test]
fn validates_workbook_identity_and_sheet_names() {
    assert_eq!(
        XlsxWorkbookRequest::new(" ", ["Sheet1"]).validate(),
        Err(XlsxWorkbookError::EmptyWorkbookId),
    );
    assert_eq!(
        XlsxWorkbookRequest::new("book", std::iter::empty::<&str>()).validate(),
        Err(XlsxWorkbookError::EmptyWorkbook),
    );
    assert_eq!(
        XlsxWorkbookRequest::new("book", ["Sheet1", " Sheet1 "]).validate(),
        Err(XlsxWorkbookError::DuplicateSheetName {
            name: "Sheet1".to_owned(),
        }),
    );
}

#[test]
fn summarizes_sheet_counts() {
    let summary = XlsxWorkbookSummary {
        workbook_id: "workbook-1".to_owned(),
        sheets: vec![
            XlsxSheetSummary {
                index: 0,
                name: "Sheet1".to_owned(),
                row_count: 1,
                col_count: 2,
                cell_count: 2,
            },
            XlsxSheetSummary {
                index: 1,
                name: "Calc".to_owned(),
                row_count: 3,
                col_count: 1,
                cell_count: 3,
            },
        ],
    };

    assert_eq!(summary.sheet_count(), 2);
    assert_eq!(summary.total_cell_count(), 5);
    assert_eq!(summary.sheet_names(), vec!["Sheet1", "Calc"]);
}

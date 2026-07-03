use super::XlsxWorkbookError;

#[test]
fn display_messages_stay_stable_for_user_facing_errors() {
    assert_eq!(
        XlsxWorkbookError::EmptyWorkbookId.to_string(),
        "workbook id must not be empty",
    );
    assert_eq!(
        XlsxWorkbookError::UnknownWorkbookSheet {
            sheet_name: "Calc".to_owned(),
        }
        .to_string(),
        "workbook session has no sheet named `Calc`",
    );
    assert_eq!(
        XlsxWorkbookError::RangeEditCellCountMismatch {
            expected: 4,
            actual: 3,
            inverse_actual: 2,
        }
        .to_string(),
        "range edit expected 4 update(s), got 3 forward and 2 inverse update(s)",
    );
}

#[test]
fn lower_level_xlsx_errors_convert_to_read_failures() {
    let error = XlsxWorkbookError::from(ky-of-xlsx::Error::custom("missing workbook part"));

    assert_eq!(
        error,
        XlsxWorkbookError::ReadFailed("missing workbook part".to_owned()),
    );
    assert_eq!(
        error.to_string(),
        "failed to read XLSX workbook: missing workbook part",
    );
}

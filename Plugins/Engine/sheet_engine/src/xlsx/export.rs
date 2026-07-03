use crate::{XlsxWorkbookError, XlsxWorkbookRequest};

/// Create a low-level writer request from a validated workbook request.
pub fn new_write_request(
    request: &XlsxWorkbookRequest,
) -> Result<ky-of-xlsx::writer::XlsxWriteRequest, XlsxWorkbookError> {
    request.validate()?;
    Ok(ky-of-xlsx::writer::XlsxWriteRequest::new(
        request.normalized_sheet_names(),
    ))
}

/// Write an empty workbook shell with the requested sheet names.
pub fn write_empty_workbook(request: &XlsxWorkbookRequest) -> Result<Vec<u8>, XlsxWorkbookError> {
    let write_request = new_write_request(request)?;
    ky-of-xlsx::writer::write_xlsx(&write_request)
        .map_err(|message| XlsxWorkbookError::WriteFailed(message.to_owned()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{summarize_workbook_bytes, XlsxImportOptions};

    #[test]
    fn writes_empty_workbook_that_can_be_summarized() {
        let request = XlsxWorkbookRequest::new("workbook-1", [" Summary ", "Data"]);
        let bytes = write_empty_workbook(&request).expect("write workbook");
        let summary = summarize_workbook_bytes("workbook-1", &bytes, XlsxImportOptions::default())
            .expect("summarize workbook");

        assert_eq!(summary.workbook_id, "workbook-1");
        assert_eq!(summary.sheet_names(), vec!["Summary", "Data"]);
    }
}

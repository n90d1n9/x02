use crate::cell::CellAddress;
use crate::writer::{CellValue, XlsxWriteRequest};
use printpdf::{BuiltinFont, Mm, PdfDocument};
use std::io::{BufWriter, Cursor};

/// Write the given request data into a basic PDF document.
pub fn write_pdf(request: &XlsxWriteRequest) -> Result<Vec<u8>, &'static str> {
    if request.sheet_names.is_empty() {
        return Err("No sheets to export");
    }

    // Initialize document with the first sheet
    let first_sheet_name = &request.sheet_names[0];
    let (doc, page1, layer1) = PdfDocument::new(first_sheet_name, Mm(210.0), Mm(297.0), "Layer 1");

    // Add default font
    let font = doc
        .add_builtin_font(BuiltinFont::Helvetica)
        .map_err(|_| "Failed to add font")?;

    for (i, name) in request.sheet_names.iter().enumerate() {
        let (page, layer) = if i == 0 {
            (page1, layer1)
        } else {
            doc.add_page(Mm(210.0), Mm(297.0), "Layer 1")
        };
        let current_layer = doc.get_page(page).get_layer(layer);

        // Render sheet title
        current_layer.use_text(format!("Sheet: {}", name), 16.0, Mm(10.0), Mm(280.0), &font);

        if let Some(cells) = request.sheet_cells.get(name) {
            for (cell_ref, val) in cells {
                // Parse A1 notation to (row, col)
                if let Ok(addr) = CellAddress::from_a1(cell_ref) {
                    let text = cell_value_to_string(val);
                    // Extremely basic grid layout:
                    // Origin in PDF is bottom-left, so we subtract from page height
                    // col 0 = 10mm, col 1 = 40mm, etc.
                    let x = Mm(10.0 + (addr.col as f64) * 30.0);
                    // row 0 = 270mm, row 1 = 265mm, etc.
                    let y = Mm(270.0 - (addr.row as f64) * 5.0);

                    // Skip if off page (simple clip)
                    if y > Mm(10.0) && x < Mm(200.0) {
                        current_layer.use_text(text, 10.0, x, y, &font);
                    }
                }
            }
        }
    }

    let mut buf = BufWriter::new(Cursor::new(Vec::new()));
    doc.save(&mut buf).map_err(|_| "Failed to save PDF")?;
    Ok(buf
        .into_inner()
        .map_err(|_| "Failed to flush PDF buffer")?
        .into_inner())
}

fn cell_value_to_string(val: &CellValue) -> String {
    match val {
        CellValue::String(s) => s.clone(),
        CellValue::Number(n) => n.to_string(),
        CellValue::Bool(b) => {
            if *b {
                "TRUE".to_string()
            } else {
                "FALSE".to_string()
            }
        }
        CellValue::DateTime(dt) => format!("{:04}-{:02}-{:02}", dt.year, dt.month, dt.day),
        CellValue::Formula(f) => format!("={}", f),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_write_pdf() {
        let mut req = XlsxWriteRequest::new(["Sheet1"]);
        req.add_cell("Sheet1", "A1", CellValue::String("Hello PDF".to_string()));
        let result = write_pdf(&req);
        assert!(result.is_ok());
        let pdf_data = result.unwrap();
        assert!(pdf_data.starts_with(b"%PDF-"));
    }
}

//! Cell conversion from lower-level XLSX values into sheet-engine cells.

use crate::{Cell, CellFormat, CellValue};

/// Convert a lower-level XLSX cell into a sheet-engine cell.
pub fn xlsx_cell_to_sheet_cell(cell: &ky-of-xlsx::Cell) -> Cell {
    let evaluated_value = xlsx_value_to_sheet_value(&cell.value);
    let raw_content = xlsx_value_to_raw_content(&cell.value);

    Cell {
        raw_content,
        evaluated_value,
        format: CellFormat::default(),
    }
}

fn xlsx_value_to_sheet_value(value: &ky-of-xlsx::CellValue) -> CellValue {
    match value {
        ky-of-xlsx::CellValue::Empty => CellValue::Empty,
        ky-of-xlsx::CellValue::Bool(value) => CellValue::Boolean(*value),
        ky-of-xlsx::CellValue::Float(value) => CellValue::Number(*value),
        ky-of-xlsx::CellValue::Integer(value) => CellValue::Number(*value as f64),
        ky-of-xlsx::CellValue::Text(value) => CellValue::String(value.clone()),
        ky-of-xlsx::CellValue::Date(value) => CellValue::String(value.format("%Y-%m-%d").to_string()),
        ky-of-xlsx::CellValue::DateTime(value) => {
            CellValue::String(value.format("%Y-%m-%dT%H:%M:%S").to_string())
        }
        ky-of-xlsx::CellValue::Time(value) => CellValue::String(value.format("%H:%M:%S").to_string()),
        ky-of-xlsx::CellValue::Error(value) => CellValue::Error(value.clone()),
        ky-of-xlsx::CellValue::Formula { result, .. } => xlsx_value_to_sheet_value(result),
        _ => CellValue::String(value.display_value()),
    }
}

fn xlsx_value_to_raw_content(value: &ky-of-xlsx::CellValue) -> String {
    match value {
        ky-of-xlsx::CellValue::Formula { expression, .. } => expression.clone(),
        _ => value.display_value(),
    }
}

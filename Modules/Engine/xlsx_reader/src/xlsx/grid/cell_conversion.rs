//! Cell conversion from lower-level XLSX values into sheet-engine cells.

use crate::{Cell, CellFormat, CellValue};

/// Convert a lower-level XLSX cell into a sheet-engine cell.
pub fn xlsx_cell_to_sheet_cell(cell: &parser-xlsx::Cell) -> Cell {
    let evaluated_value = xlsx_value_to_sheet_value(&cell.value);
    let raw_content = xlsx_value_to_raw_content(&cell.value);

    Cell {
        raw_content,
        evaluated_value,
        format: CellFormat::default(),
    }
}

fn xlsx_value_to_sheet_value(value: &parser-xlsx::CellValue) -> CellValue {
    match value {
        parser-xlsx::CellValue::Empty => CellValue::Empty,
        parser-xlsx::CellValue::Bool(value) => CellValue::Boolean(*value),
        parser-xlsx::CellValue::Float(value) => CellValue::Number(*value),
        parser-xlsx::CellValue::Integer(value) => CellValue::Number(*value as f64),
        parser-xlsx::CellValue::Text(value) => CellValue::String(value.clone()),
        parser-xlsx::CellValue::Date(value) => CellValue::String(value.format("%Y-%m-%d").to_string()),
        parser-xlsx::CellValue::DateTime(value) => {
            CellValue::String(value.format("%Y-%m-%dT%H:%M:%S").to_string())
        }
        parser-xlsx::CellValue::Time(value) => CellValue::String(value.format("%H:%M:%S").to_string()),
        parser-xlsx::CellValue::Error(value) => CellValue::Error(value.clone()),
        parser-xlsx::CellValue::Formula { result, .. } => xlsx_value_to_sheet_value(result),
        _ => CellValue::String(value.display_value()),
    }
}

fn xlsx_value_to_raw_content(value: &parser-xlsx::CellValue) -> String {
    match value {
        parser-xlsx::CellValue::Formula { expression, .. } => expression.clone(),
        _ => value.display_value(),
    }
}

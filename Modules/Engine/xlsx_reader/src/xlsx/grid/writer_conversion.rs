//! Cell conversion from sheet-engine cells into lower-level XLSX writer values.

use crate::{Cell, CellValue};

pub(crate) fn sheet_cell_to_writer_value(cell: &Cell) -> Option<parser-xlsx::writer::CellValue> {
    if cell.raw_content.is_empty() && matches!(cell.evaluated_value, CellValue::Empty) {
        return None;
    }

    if let Some(formula) = cell.raw_content.strip_prefix('=') {
        return Some(parser-xlsx::writer::CellValue::Formula(formula.to_owned()));
    }

    match &cell.evaluated_value {
        CellValue::Empty if cell.raw_content.is_empty() => None,
        CellValue::Empty => Some(parser-xlsx::writer::CellValue::String(cell.raw_content.clone())),
        CellValue::Number(value) => Some(parser-xlsx::writer::CellValue::Number(*value)),
        CellValue::String(value) => Some(parser-xlsx::writer::CellValue::String(value.clone())),
        CellValue::Boolean(value) => Some(parser-xlsx::writer::CellValue::Bool(*value)),
        CellValue::Error(value) => Some(parser-xlsx::writer::CellValue::String(value.clone())),
    }
}

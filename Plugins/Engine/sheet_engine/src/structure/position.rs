//! Sparse grid cell-position shifting for structure edits.

use crate::{CellPosition, EvalError, SheetStructureEdit};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum StructureAxis {
    Rows,
    Columns,
}

pub(super) fn shifted_position(
    position: CellPosition,
    edit: SheetStructureEdit,
) -> Result<Option<CellPosition>, EvalError> {
    match edit {
        SheetStructureEdit::InsertRows { row, count } if position.row >= row => Ok(Some(
            CellPosition::new(position.col, checked_add_axis(position.row, count, "row")?),
        )),
        SheetStructureEdit::InsertColumns { col, count } if position.col >= col => {
            Ok(Some(CellPosition::new(
                checked_add_axis(position.col, count, "column")?,
                position.row,
            )))
        }
        SheetStructureEdit::DeleteRows { row, count } => {
            shift_deleted_position(position, row, count, StructureAxis::Rows)
        }
        SheetStructureEdit::DeleteColumns { col, count } => {
            shift_deleted_position(position, col, count, StructureAxis::Columns)
        }
        _ => Ok(Some(position)),
    }
}

fn shift_deleted_position(
    position: CellPosition,
    delete_start: u32,
    count: u32,
    axis: StructureAxis,
) -> Result<Option<CellPosition>, EvalError> {
    let delete_end = checked_add_axis(delete_start, count, "delete range")?;
    let index = match axis {
        StructureAxis::Rows => position.row,
        StructureAxis::Columns => position.col,
    };

    if index >= delete_start && index < delete_end {
        return Ok(None);
    }
    if index < delete_end {
        return Ok(Some(position));
    }

    Ok(Some(match axis {
        StructureAxis::Rows => CellPosition::new(position.col, position.row - count),
        StructureAxis::Columns => CellPosition::new(position.col - count, position.row),
    }))
}

fn checked_add_axis(index: u32, count: u32, axis_name: &str) -> Result<u32, EvalError> {
    index.checked_add(count).ok_or_else(|| {
        EvalError::StructureError(format!(
            "{axis_name} index {index} cannot be shifted by {count}"
        ))
    })
}

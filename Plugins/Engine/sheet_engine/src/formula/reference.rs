//! Parsed A1-style formula reference model and transformations.

use super::{
    axis::{shift_deleted_axis, shift_inserted_axis, translate_index},
    columns::column_label,
    FormulaReferenceOffset, FormulaReferenceStructureEdit,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(super) struct FormulaReference {
    pub(super) col: u32,
    pub(super) row: u32,
    pub(super) col_absolute: bool,
    pub(super) row_absolute: bool,
    pub(super) byte_len: usize,
}

impl FormulaReference {
    pub(super) fn translate(self, offset: FormulaReferenceOffset) -> String {
        let translated_col = if self.col_absolute {
            Some(self.col)
        } else {
            translate_index(self.col, offset.col_delta)
        };
        let translated_row = if self.row_absolute {
            Some(self.row)
        } else {
            translate_index(self.row, offset.row_delta)
        };

        match (translated_col, translated_row) {
            (Some(col), Some(row)) => Self { col, row, ..self }.to_a1(),
            _ => "#REF!".to_owned(),
        }
    }

    pub(super) fn shift_for_structure(self, edit: FormulaReferenceStructureEdit) -> String {
        let shifted = match edit {
            FormulaReferenceStructureEdit::InsertRows { row, count } => {
                shift_inserted_axis(self.row, row, count).map(|row| Self { row, ..self })
            }
            FormulaReferenceStructureEdit::DeleteRows { row, count } => {
                shift_deleted_axis(self.row, row, count).map(|row| Self { row, ..self })
            }
            FormulaReferenceStructureEdit::InsertColumns { col, count } => {
                shift_inserted_axis(self.col, col, count).map(|col| Self { col, ..self })
            }
            FormulaReferenceStructureEdit::DeleteColumns { col, count } => {
                shift_deleted_axis(self.col, col, count).map(|col| Self { col, ..self })
            }
        };

        shifted
            .map(FormulaReference::to_a1)
            .unwrap_or_else(|| "#REF!".to_owned())
    }

    fn to_a1(self) -> String {
        let mut reference = String::new();
        if self.col_absolute {
            reference.push('$');
        }
        reference.push_str(&column_label(self.col));
        if self.row_absolute {
            reference.push('$');
        }
        reference.push_str(&(self.row + 1).to_string());
        reference
    }
}

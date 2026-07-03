//! Parser for simple A1-style references embedded inside formulas.

use super::{columns::column_index, reference::FormulaReference};

pub(super) fn parse_formula_reference(input: &str) -> Option<FormulaReference> {
    let bytes = input.as_bytes();
    let mut index = 0usize;
    let col_absolute = consume_dollar(bytes, &mut index);
    let col_start = index;

    while index < bytes.len() && bytes[index].is_ascii_alphabetic() {
        index += 1;
    }

    if index == col_start {
        return None;
    }

    let col_label = &input[col_start..index];
    let row_absolute = consume_dollar(bytes, &mut index);
    let row_start = index;

    while index < bytes.len() && bytes[index].is_ascii_digit() {
        index += 1;
    }

    if index == row_start || is_identifier_continuation(bytes, index) {
        return None;
    }

    let row_label = &input[row_start..index];
    let row_number = row_label.parse::<u32>().ok()?;
    if row_number == 0 {
        return None;
    }

    Some(FormulaReference {
        col: column_index(col_label)?,
        row: row_number - 1,
        col_absolute,
        row_absolute,
        byte_len: index,
    })
}

fn consume_dollar(bytes: &[u8], index: &mut usize) -> bool {
    if bytes.get(*index) == Some(&b'$') {
        *index += 1;
        true
    } else {
        false
    }
}

fn is_identifier_continuation(bytes: &[u8], index: usize) -> bool {
    bytes
        .get(index)
        .is_some_and(|byte| byte.is_ascii_alphanumeric() || *byte == b'_' || *byte == b'(')
}

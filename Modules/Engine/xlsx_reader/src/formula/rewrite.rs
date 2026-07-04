//! Formula reference rewrite entry points.

use super::{
    parser::parse_formula_reference, reference::FormulaReference, FormulaReferenceOffset,
    FormulaReferenceStructureEdit,
};

/// Rewrite relative A1-style references inside a formula by a paste offset.
pub fn translate_formula_references(raw_content: &str, offset: FormulaReferenceOffset) -> String {
    if !raw_content.starts_with('=') || offset.is_zero() {
        return raw_content.to_owned();
    }

    rewrite_formula_references(raw_content, |reference| reference.translate(offset))
}

/// Rewrite A1-style references inside a formula after row or column structure edits.
pub fn shift_formula_references_for_structure(
    raw_content: &str,
    edit: FormulaReferenceStructureEdit,
) -> String {
    if !raw_content.starts_with('=') || edit.is_noop() {
        return raw_content.to_owned();
    }

    rewrite_formula_references(raw_content, |reference| reference.shift_for_structure(edit))
}

fn rewrite_formula_references(
    raw_content: &str,
    mut rewrite_reference: impl FnMut(FormulaReference) -> String,
) -> String {
    let mut rewritten = String::with_capacity(raw_content.len());
    let mut index = 0usize;

    while index < raw_content.len() {
        let rest = &raw_content[index..];
        if let Some(reference) = parse_formula_reference(rest) {
            rewritten.push_str(&rewrite_reference(reference));
            index += reference.byte_len;
            continue;
        }

        let ch = rest
            .chars()
            .next()
            .expect("index is always at a valid character boundary");
        rewritten.push(ch);
        index += ch.len_utf8();
    }

    rewritten
}

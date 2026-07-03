use super::*;

#[test]
fn translates_relative_references_by_offset() {
    let offset = FormulaReferenceOffset {
        col_delta: 2,
        row_delta: 3,
    };

    assert_eq!(
        translate_formula_references("=A1+B2*AA10", offset),
        "=C4+D5*AC13",
    );
}

#[test]
fn preserves_absolute_reference_axes() {
    let offset = FormulaReferenceOffset {
        col_delta: 2,
        row_delta: 3,
    };

    assert_eq!(
        translate_formula_references("=$A1+A$1+$A$1", offset),
        "=$A4+C$1+$A$1",
    );
}

#[test]
fn returns_ref_when_relative_reference_moves_before_origin() {
    let offset = FormulaReferenceOffset {
        col_delta: -2,
        row_delta: -1,
    };

    assert_eq!(translate_formula_references("=A1+C3", offset), "=#REF!+A2");
}

#[test]
fn ignores_non_formula_or_embedded_identifiers() {
    let offset = FormulaReferenceOffset {
        col_delta: 1,
        row_delta: 1,
    };

    assert_eq!(translate_formula_references("A1", offset), "A1");
    assert_eq!(
        translate_formula_references("=SUM(A1)+A1_name+A1", offset),
        "=SUM(B2)+A1_name+B2",
    );
    assert_eq!(
        translate_formula_references("=LOG10(A1)+A1", offset),
        "=LOG10(B2)+B2",
    );
}

#[test]
fn shifts_references_after_row_insert_and_delete() {
    assert_eq!(
        shift_formula_references_for_structure(
            "=A1+$A$3+A5",
            FormulaReferenceStructureEdit::InsertRows { row: 2, count: 2 },
        ),
        "=A1+$A$5+A7",
    );
    assert_eq!(
        shift_formula_references_for_structure(
            "=A1+A3+A5",
            FormulaReferenceStructureEdit::DeleteRows { row: 2, count: 2 },
        ),
        "=A1+#REF!+A3",
    );
}

#[test]
fn shifts_references_after_column_insert_and_delete() {
    assert_eq!(
        shift_formula_references_for_structure(
            "=A1+C1+$D$1",
            FormulaReferenceStructureEdit::InsertColumns { col: 2, count: 1 },
        ),
        "=A1+D1+$E$1",
    );
    assert_eq!(
        shift_formula_references_for_structure(
            "=A1+C1+E1",
            FormulaReferenceStructureEdit::DeleteColumns { col: 2, count: 2 },
        ),
        "=A1+#REF!+C1",
    );
}

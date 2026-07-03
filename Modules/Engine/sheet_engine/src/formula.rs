//! Formula reference rewriting facade for paste and sheet-structure edits.

mod axis;
mod columns;
mod offset;
mod parser;
mod reference;
mod rewrite;
mod structure_edit;

pub use offset::FormulaReferenceOffset;
pub use rewrite::{shift_formula_references_for_structure, translate_formula_references};
pub use structure_edit::FormulaReferenceStructureEdit;

#[cfg(test)]
mod tests;

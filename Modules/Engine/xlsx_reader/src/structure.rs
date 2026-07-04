//! Sheet structure edit facade for row and column mutations.

mod apply;
mod edit;
mod position;

pub use apply::apply_sheet_structure_edit;
pub use edit::SheetStructureEdit;

#[cfg(test)]
mod tests;

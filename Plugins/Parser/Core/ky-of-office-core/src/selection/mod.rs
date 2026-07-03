mod grid;
mod object;
mod page;
mod selection;
mod text;

pub use grid::{GridPosition, GridRange, GridSelection};
pub use object::ObjectSelection;
pub use page::PageSelection;
pub use selection::OfficeSelection;
pub use text::{SelectionDirection, TextSelection};

#[cfg(test)]
mod tests;

//! Sheet-grid workbook bundle facade for XLSX import/export workflows.

mod io;
mod model;
mod summary;

#[cfg(test)]
mod tests;

pub use io::{import_grid_workbook_bytes, write_grid_workbook};
pub use model::XlsxGridWorkbook;

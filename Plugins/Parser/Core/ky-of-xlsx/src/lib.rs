//! Reusable XLSX reader and writer primitives for Office products.

#[path = "core/cell.rs"]
pub mod cell;
#[path = "core/defined_name.rs"]
pub mod defined_name;
#[path = "core/error.rs"]
pub mod error;
#[path = "core/ffi.rs"]
pub mod ffi;
#[path = "core/format.rs"]
pub mod format;
#[path = "core/iter.rs"]
pub mod iter;
#[path = "core/parser.rs"]
pub mod parser;
#[path = "core/row.rs"]
pub mod row;
#[path = "core/sheet.rs"]
pub mod sheet;
#[path = "core/workbook.rs"]
pub mod workbook;
#[path = "core/writer.rs"]
pub mod writer;
#[path = "core/xml_util.rs"]
pub mod xml_util;

#[cfg(feature = "csv")]
#[path = "export/csv.rs"]
pub mod csv;

#[cfg(feature = "ods")]
#[path = "export/ods.rs"]
pub mod ods;

#[cfg(feature = "pdf")]
#[path = "export/pdf.rs"]
pub mod pdf;

pub use cell::{Cell, CellAddress, CellValue};
pub use error::{Error, Result};
pub use iter::StreamingReader;
pub use row::Row;
pub use sheet::{Sheet, SheetInfo, SheetMeta};
pub use workbook::{OpenOptions, Workbook, WorkbookReader};
pub use writer::{ImageData, XlsxDateTime, XlsxWriteRequest, write_xlsx};

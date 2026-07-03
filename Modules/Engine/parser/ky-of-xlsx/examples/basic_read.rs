//! Example: basic reading of every sheet in a workbook.

use ky-of-xlsx::{Workbook, WorkbookReader};

fn main() -> ky-of-xlsx::Result<()> {
    let path = std::env::args()
        .nth(1)
        .expect("Usage: basic_read <file.xlsx>");
    let wb = Workbook::open(&path)?;

    println!("Opened: {path}");
    println!("Sheets: {}", wb.sheet_count());

    for sheet in wb.sheets() {
        let meta = sheet.meta();
        println!(
            "\n── Sheet: {:?}  ({}×{}, {} cells) ──",
            sheet.name(),
            meta.row_count,
            meta.col_count,
            meta.cell_count,
        );

        for row in sheet.rows().take(20) {
            let line = row.values().join("\t");
            println!("  [{:>4}] {line}", row.index + 1);
        }

        if meta.row_count > 20 {
            println!("  … {} more rows", meta.row_count - 20);
        }
    }

    Ok(())
}

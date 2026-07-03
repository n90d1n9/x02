//! Example: advanced extraction — ranges, cell lookup, search, JSON export.

use ky-of-xlsx::{CellValue, OpenOptions, Workbook, WorkbookReader};

#[cfg(feature = "serde-support")]
use serde_json;

fn main() -> ky-of-xlsx::Result<()> {
    let path = std::env::args()
        .nth(1)
        .expect("Usage: advanced_extract <file.xlsx>");

    // Only load the first two sheets, limit to 1 000 rows each
    let opts = OpenOptions::new().max_rows(1_000).max_cols(100);

    let wb = Workbook::open_with(&path, &opts)?;

    let sheet = wb.sheet_by_index(0)?;
    println!("Sheet: {}", sheet.name());

    // ── Cell lookup by A1 address ─────────────────────────────────────────────
    if let Some(cell) = sheet.cell_at("A1")? {
        println!("A1 = {:?}", cell.value);
    }

    // ── Extract a rectangular range ───────────────────────────────────────────
    println!("\nRange A1:C5:");
    for row in sheet.range("A1", "C5")? {
        println!("  {}", row.values().join(" | "));
    }

    // ── Search ────────────────────────────────────────────────────────────────
    let query = "Total";
    let hits = sheet.search(query);
    println!("\nCells containing {query:?}:");
    for (addr, val) in &hits {
        println!("  {} => {val}", addr.to_a1());
    }

    // ── Flat cell dump ────────────────────────────────────────────────────────
    let flat = sheet.cells_flat();
    println!("\nTotal non-empty cells: {}", flat.len());

    // Count cell types
    let (floats, texts, bools, errors) = flat.iter().fold((0usize, 0, 0, 0), |mut acc, (_, v)| {
        match v {
            CellValue::Float(_) | CellValue::Integer(_) => acc.0 += 1,
            CellValue::Text(_) => acc.1 += 1,
            CellValue::Bool(_) => acc.2 += 1,
            CellValue::Error(_) => acc.3 += 1,
            _ => {}
        }
        acc
    });
    println!("  Numeric: {floats}, Text: {texts}, Bool: {bools}, Error: {errors}");

    // ── 2-D table export ──────────────────────────────────────────────────────
    let table = sheet.to_table();
    println!("\nFirst row of 2-D table: {:?}", table.first());

    // ── JSON export (if serde enabled) ───────────────────────────────────────
    #[cfg(feature = "serde-support")]
    {
        let json_rows: Vec<serde_json::Value> = table
            .iter()
            .map(|row| serde_json::Value::Array(row.iter().map(|s| s.as_str().into()).collect()))
            .collect();

        let json = serde_json::to_string_pretty(&json_rows).unwrap();
        println!(
            "\nJSON (first 500 chars):\n{}",
            &json[..json.len().min(500)]
        );
    }

    Ok(())
}

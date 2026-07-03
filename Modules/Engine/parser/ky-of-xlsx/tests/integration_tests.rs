//! Integration tests for workbook options, cell primitives, and optional fixtures.

use ky-of-xlsx::{OpenOptions, Workbook, WorkbookReader};

// ── Tests ─────────────────────────────────────────────────────────────────────

#[test]
fn open_options_default() {
    let opts = OpenOptions::default();
    assert_eq!(opts.max_rows, 0);
    assert_eq!(opts.max_cols, 0);
}

#[test]
fn open_options_builder() {
    let opts = OpenOptions::new()
        .max_rows(500)
        .max_cols(26)
        .skip_sheets(["Sheet2"]);
    assert_eq!(opts.max_rows, 500);
    assert_eq!(opts.max_cols, 26);
    assert!(opts.skip_sheets.contains(&"Sheet2".to_string()));
}

#[test]
fn cell_address_roundtrip() {
    use ky-of-xlsx::CellAddress;
    for (a1, row, col) in [
        ("A1", 0u32, 0u16),
        ("Z1", 0, 25),
        ("AA1", 0, 26),
        ("AZ1", 0, 51),
        ("BA1", 0, 52),
        ("D10", 9, 3),
    ] {
        let addr = CellAddress::from_a1(a1).unwrap();
        assert_eq!((addr.row, addr.col), (row, col), "parsing {a1}");
        assert_eq!(addr.to_a1(), a1, "formatting ({row},{col})");
    }
}

#[test]
fn cell_value_display() {
    use ky-of-xlsx::CellValue;
    assert_eq!(CellValue::Empty.display_value(), "");
    assert_eq!(CellValue::Bool(true).display_value(), "TRUE");
    assert_eq!(CellValue::Float(1.5).display_value(), "1.5");
    assert_eq!(CellValue::Integer(-7).display_value(), "-7");
    assert_eq!(CellValue::Text("Hi".into()).display_value(), "Hi");
    assert_eq!(CellValue::Error("#REF!".into()).display_value(), "#REF!");
}

#[test]
fn from_bytes_empty_returns_error() {
    let result = Workbook::from_bytes(b"not a zip", "xlsx", &OpenOptions::default());
    assert!(result.is_err(), "Expected error for invalid bytes");
}

/// Read a real fixture file if it exists.
#[test]
fn fixture_file_if_present() -> ky-of-xlsx::Result<()> {
    let fixture = std::path::Path::new("tests/fixtures/sample.xlsx");
    if !fixture.exists() {
        println!("Skipping fixture test — place a file at {fixture:?} to enable");
        return Ok(());
    }
    let wb = Workbook::open(fixture)?;
    assert!(wb.sheet_count() > 0);
    let sheet = wb.sheet_by_index(0)?;
    println!(
        "Fixture sheet {:?}: {}×{}",
        sheet.name(),
        sheet.meta().row_count,
        sheet.meta().col_count,
    );
    Ok(())
}

# ky-of-xlsx

A complete, ergonomic **XLS / XLSX / XLSB / ODS** reader and extractor library for Rust,
built on top of [`calamine`](https://crates.io/crates/calamine) with a clean,
well-typed API surface for Office family products.

## Features

| Feature | Default | Description |
|---|---|---|
| `serde-support` | No | Derive `Serialize`/`Deserialize` for public workbook types |

## Quick Start

```toml
[dependencies]
ky-of-xlsx = { path = "." }              # local
# ky-of-xlsx = "0.1"                     # crates.io (once published)
```

```rust
use ky-of-xlsx::{Workbook, WorkbookReader};

fn main() -> ky-of-xlsx::Result<()> {
    let wb = Workbook::open("report.xlsx")?;

    for sheet in wb.sheets() {
        println!("=== {} ===", sheet.name());
        for row in sheet.rows() {
            println!("{}", row.values().join("\t"));
        }
    }
    Ok(())
}
```

## API Overview

### Opening

```rust
// Auto-detect format from extension (.xlsx / .xls / .xlsb / .ods)
let wb = Workbook::open("file.xlsx")?;

// With options
let opts = OpenOptions::new()
    .max_rows(500)
    .only_sheets(["Sheet1", "Summary"]);
let wb = Workbook::open_with("file.xlsx", &opts)?;

// From bytes (e.g. HTTP response body)
let wb = Workbook::from_bytes(&bytes, "xlsx", &opts)?;

// From any Read + Seek
let wb = Workbook::from_reader(file, "xlsx", &opts)?;
```

### Sheet Access

```rust
// List all sheet names
wb.sheet_names(); // Vec<&str>

// By name
let sheet = wb.sheet_by_name("Sheet1")?;

// By index
let sheet = wb.sheet_by_index(0)?;

// Check existence
wb.has_sheet("Hidden"); // bool
```

### Cell & Row Access

```rust
// Iterate rows
for row in sheet.rows() {
    // row.index  — zero-based row number
    // row.len()  — number of non-empty cells
    // row.values() — Vec<String> of display values
    // row.get(col) — Option<&Cell>
}

// Cell by A1 address
let cell = sheet.cell_at("B3")?;  // Option<&Cell>

// Cell value (typed)
let val = sheet.value_at("C5")?;   // CellValue

// Rectangular range
let rows = sheet.range("A1", "D10")?;

// Flat dump of all non-empty cells
let flat: Vec<(CellAddress, CellValue)> = sheet.cells_flat();

// 2-D table (padded to max width)
let table: Vec<Vec<String>> = sheet.to_table();
```

### Search

```rust
// Exact match → first address
let addr: Option<CellAddress> = sheet.find_text("Total");

// Substring search
let hits: Vec<(CellAddress, String)> = sheet.search("Revenue");
```

### CellValue

```rust
match cell.value {
    CellValue::Empty       => {},
    CellValue::Text(s)     => println!("{s}"),
    CellValue::Float(f)    => println!("{f}"),
    CellValue::Integer(i)  => println!("{i}"),
    CellValue::Bool(b)     => println!("{b}"),
    CellValue::Date(d)     => println!("{}", d.format("%Y-%m-%d")),
    CellValue::DateTime(dt)=> println!("{dt}"),
    CellValue::Time(t)     => println!("{t}"),
    CellValue::Error(e)    => eprintln!("Formula error: {e}"),
    CellValue::Formula { expression, result } => println!("{expression} => {result}"),
}

// Coercion helpers
cell.value.as_f64()    // Option<f64>
cell.value.as_i64()    // Option<i64>
cell.value.as_str()    // Option<&str>
cell.value.is_empty()  // bool
cell.display_value()   // String (always succeeds)
```

### CellAddress

```rust
// Construct
let addr = CellAddress::new(0, 0);       // row=0, col=0 → A1
let addr = CellAddress::from_a1("BC42")?;

// Convert
addr.to_a1()   // "BC42"
format!("{addr}")
```

### Streaming (large files)

```rust
use ky-of-xlsx::iter::StreamingReader;

let reader = StreamingReader::open("huge.xlsx")?;
for row in reader.rows() {
    // process without buffering the whole sheet
}
```

### JSON export (with `serde-support`)

```rust
use serde_json;

let table = sheet.to_table();
let json = serde_json::to_string_pretty(&table)?;
println!("{json}");
```

## C FFI

The historical `xlsx_reader.h` header and `src/ffi.rs` file are kept as a
compatibility starting point. The current Cargo manifest does not expose an
`ffi` feature yet.

```c
XlsxWorkbook *wb = xlsx_open("report.xlsx");
int n             = xlsx_sheet_count(wb);
const char *name  = xlsx_sheet_name(wb, 0);
char *val         = xlsx_cell_value(sheet, 0, 0);
xlsx_free_string(val);
xlsx_close(wb);
```

## Running Examples

```bash
cargo run --example basic_read       -- path/to/file.xlsx
cargo run --example advanced_extract -- path/to/file.xlsx
cargo run --example streaming        -- path/to/file.xlsx
```

## Tests

```bash
cargo test
# With a real fixture:
mkdir -p tests/fixtures
cp my_file.xlsx tests/fixtures/sample.xlsx
cargo test
```

## Benchmarks

```bash
cp my_large_file.xlsx benches/fixture.xlsx
cargo bench
```

## Supported Formats

| Extension | Format | Notes |
|---|---|---|
| `.xlsx` | Office Open XML | Full support |
| `.xls` | BIFF5–BIFF8 | Full support via calamine |
| `.xlsb` | Binary OOXML | Full support |
| `.ods` | OpenDocument | Full support |

## License

MIT

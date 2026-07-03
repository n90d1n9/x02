//! Example: streaming large files row-by-row without loading everything.

use ky-of-xlsx::iter::StreamingReader;

fn main() -> ky-of-xlsx::Result<()> {
    let path = std::env::args()
        .nth(1)
        .expect("Usage: streaming <file.xlsx>");
    let reader = StreamingReader::open(&path)?;

    println!("Sheets: {:?}", reader.sheet_names());
    println!("Active: {}", reader.current_sheet());

    let mut row_count = 0usize;
    let mut cell_count = 0usize;

    for row in reader.rows() {
        row_count += 1;
        cell_count += row.len();

        if row_count <= 5 {
            println!("Row {:>4}: {}", row.index + 1, row.values().join("\t"));
        }
    }

    println!("\nTotal rows : {row_count}");
    println!("Total cells: {cell_count}");

    Ok(())
}

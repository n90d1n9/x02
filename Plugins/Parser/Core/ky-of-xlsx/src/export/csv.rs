use crate::writer::{CellValue, XlsxWriteRequest};
use csv::WriterBuilder;
use std::collections::HashMap;

/// Export each worksheet to a CSV string (UTF-8).
/// Returns a map of sheet name → CSV bytes.
pub fn write_csv(request: &XlsxWriteRequest) -> Result<HashMap<String, Vec<u8>>, &'static str> {
    let mut result = HashMap::new();
    for name in &request.sheet_names {
        let mut wtr = WriterBuilder::new()
            .has_headers(false)
            .from_writer(Vec::new());
        // Build a map of rows to cell col/value
        let mut rows: HashMap<usize, Vec<(usize, String)>> = HashMap::new();
        if let Some(cells) = request.sheet_cells.get(name) {
            for (cell_ref, val) in cells {
                // parse A1 reference
                let (row, col) = match parse_cell_ref(cell_ref) {
                    Some((r, c_str)) => {
                        // column letters to index
                        let col_index = column_label_to_index(&c_str);
                        (r, col_index)
                    }
                    None => continue,
                };
                rows.entry(row)
                    .or_default()
                    .push((col, cell_value_to_string(val)));
            }
        }
        // Determine max column per row for proper ordering
        let mut sorted_rows: Vec<usize> = rows.keys().cloned().collect();
        sorted_rows.sort_unstable();
        for row in sorted_rows {
            let mut cols = rows.remove(&row).unwrap();
            cols.sort_by_key(|(c, _)| *c);
            let line: Vec<String> = cols.into_iter().map(|(_, v)| v).collect();
            wtr.write_record(&line).map_err(|_| "csv write error")?;
        }
        wtr.flush().map_err(|_| "csv flush error")?;
        result.insert(
            name.clone(),
            wtr.into_inner().map_err(|_| "csv into_inner error")?,
        );
    }
    Ok(result)
}

fn parse_cell_ref(cell_ref: &str) -> Option<(usize, String)> {
    let mut col = String::new();
    let mut row = String::new();
    for c in cell_ref.chars() {
        if c.is_ascii_alphabetic() {
            col.push(c);
        } else if c.is_ascii_digit() {
            row.push(c);
        } else {
            return None;
        }
    }
    if col.is_empty() || row.is_empty() {
        return None;
    }
    let row_num: usize = row.parse().ok()?; // 1-based
    Some((row_num, col))
}

fn column_label_to_index(label: &str) -> usize {
    let mut idx = 0usize;
    for ch in label.chars() {
        idx = idx * 26 + ((ch as u8 - b'A') as usize + 1);
    }
    idx - 1 // zero-based
}

fn cell_value_to_string(val: &CellValue) -> String {
    match val {
        CellValue::String(s) => s.clone(),
        CellValue::Number(n) => n.to_string(),
        CellValue::Bool(b) => {
            if *b {
                "TRUE".to_string()
            } else {
                "FALSE".to_string()
            }
        }
        CellValue::DateTime(dt) => format!("{:04}-{:02}-{:02}", dt.year, dt.month, dt.day),
        CellValue::Formula(f) => format!("={}", f),
    }
}

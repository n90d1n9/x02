/// A simple A1-style spreadsheet cell address.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct CellAddress {
    pub row: u32,
    pub col: u16,
}

impl CellAddress {
    /// Create a new cell address from row and column indexes.
    pub fn new(row: u32, col: u16) -> Self {
        Self { row, col }
    }

    /// Parse an A1-style address like "A1" or "$B$2".
    pub fn from_a1(input: &str) -> Result<Self, &'static str> {
        let mut col = 0u32;
        let mut row = 0u32;
        let mut seen_digit = false;

        for ch in input.chars() {
            match ch {
                '$' => continue,
                'A'..='Z' => {
                    if seen_digit {
                        return Err("Invalid A1 address");
                    }
                    col = col.saturating_mul(26).saturating_add((ch as u32) - ('A' as u32) + 1);
                }
                'a'..='z' => {
                    if seen_digit {
                        return Err("Invalid A1 address");
                    }
                    col = col.saturating_mul(26).saturating_add((ch as u32) - ('a' as u32) + 1);
                }
                '0'..='9' => {
                    seen_digit = true;
                    row = row.saturating_mul(10).saturating_add((ch as u32) - ('0' as u32));
                }
                _ => return Err("Invalid A1 address"),
            }
        }

        if col == 0 || row == 0 || col > u16::MAX as u32 {
            return Err("Invalid A1 address");
        }

        Ok(Self {
            row,
            col: col as u16,
        })
    }

    /// Format the address back to A1 notation.
    pub fn to_a1(&self) -> String {
        let mut col = self.col as u32;
        let mut letters = String::new();

        while col > 0 {
            let rem = ((col - 1) % 26) as u8;
            letters.push((b'A' + rem) as char);
            col = (col - 1) / 26;
        }

        letters.chars().rev().collect::<String>() + &self.row.to_string()
    }
}

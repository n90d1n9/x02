//! Cell value types and address utilities.

use crate::error::{Error, Result};
use crate::format::Style;
use chrono::{NaiveDate, NaiveDateTime, NaiveTime};
use std::fmt;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

// ── CellAddress ──────────────────────────────────────────────────────────────

/// A zero-based (row, col) cell coordinate.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct CellAddress {
    /// Zero-based row index.
    pub row: u32,
    /// Zero-based column index.
    pub col: u16,
}

impl CellAddress {
    /// Create a new address from zero-based indices.
    #[inline]
    pub fn new(row: u32, col: u16) -> Self {
        Self { row, col }
    }

    /// Parse an A1-style address string (e.g. `"A1"`, `"BC42"`).
    ///
    /// # Errors
    /// Returns [`Error::InvalidAddress`] if the string is not valid A1 notation.
    pub fn from_a1(s: &str) -> Result<Self> {
        let s = s.trim().to_ascii_uppercase();
        let split = s
            .find(|c: char| c.is_ascii_digit())
            .ok_or_else(|| Error::InvalidAddress(s.clone()))?;

        let col_str = &s[..split];
        let row_str = &s[split..];

        if col_str.is_empty() || row_str.is_empty() {
            return Err(Error::InvalidAddress(s));
        }

        let col = col_str
            .chars()
            .try_fold(0u32, |acc, c| {
                if c.is_ascii_alphabetic() {
                    Some(acc * 26 + (c as u32 - 'A' as u32 + 1))
                } else {
                    None
                }
            })
            .ok_or_else(|| Error::InvalidAddress(s.clone()))?
            .checked_sub(1)
            .ok_or_else(|| Error::InvalidAddress(s.clone()))? as u16;

        let row: u32 = row_str
            .parse::<u32>()
            .map_err(|_| Error::InvalidAddress(s.clone()))?
            .checked_sub(1)
            .ok_or_else(|| Error::InvalidAddress(s.clone()))?;

        Ok(Self { row, col })
    }

    /// Convert to A1 notation (e.g. `(0, 0)` → `"A1"`).
    pub fn to_a1(self) -> String {
        let mut col = self.col as u32 + 1;
        let mut letters = Vec::new();
        while col > 0 {
            col -= 1;
            letters.push((b'A' + (col % 26) as u8) as char);
            col /= 26;
        }
        letters.reverse();
        let col_str: String = letters.into_iter().collect();
        format!("{}{}", col_str, self.row + 1)
    }
}

impl fmt::Display for CellAddress {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_a1())
    }
}

// ── CellValue ────────────────────────────────────────────────────────────────

/// The typed value stored in a single spreadsheet cell.
#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
#[non_exhaustive]
pub enum CellValue {
    /// No value (empty cell).
    Empty,
    /// A boolean (`TRUE`/`FALSE`).
    Bool(bool),
    /// A 64-bit floating-point number.
    Float(f64),
    /// An integer number (BIFF stores some as 64-bit integers).
    Integer(i64),
    /// A UTF-8 text string.
    Text(String),
    /// A date (no time component).
    Date(NaiveDate),
    /// A date + time.
    DateTime(NaiveDateTime),
    /// A time-of-day (no date).
    Time(NaiveTime),
    /// An Excel formula error string (e.g. `"#REF!"`, `"#DIV/0!"`).
    Error(String),
    /// A formula whose result is represented as a nested `CellValue`.
    Formula {
        /// The formula text, e.g. `"=SUM(A1:A10)"`.
        expression: String,
        /// Cached result of evaluating the formula.
        result: Box<CellValue>,
    },
}

impl CellValue {
    /// Return `true` if the cell is empty.
    #[inline]
    pub fn is_empty(&self) -> bool {
        matches!(self, CellValue::Empty)
    }

    /// Return a human-readable representation (suitable for CSV output).
    pub fn display_value(&self) -> String {
        match self {
            CellValue::Empty => String::new(),
            CellValue::Bool(b) => if *b { "TRUE" } else { "FALSE" }.to_owned(),
            CellValue::Float(f) => format!("{f}"),
            CellValue::Integer(i) => format!("{i}"),
            CellValue::Text(s) => s.clone(),
            CellValue::Date(d) => d.format("%Y-%m-%d").to_string(),
            CellValue::DateTime(dt) => dt.format("%Y-%m-%dT%H:%M:%S").to_string(),
            CellValue::Time(t) => t.format("%H:%M:%S").to_string(),
            CellValue::Error(e) => e.clone(),
            CellValue::Formula { result, .. } => result.display_value(),
        }
    }

    /// Try to coerce the value into an `f64`.
    pub fn as_f64(&self) -> Option<f64> {
        match self {
            CellValue::Float(f) => Some(*f),
            CellValue::Integer(i) => Some(*i as f64),
            CellValue::Bool(b) => Some(if *b { 1.0 } else { 0.0 }),
            CellValue::Formula { result, .. } => result.as_f64(),
            _ => None,
        }
    }

    /// Try to coerce the value into an `i64`.
    pub fn as_i64(&self) -> Option<i64> {
        match self {
            CellValue::Integer(i) => Some(*i),
            CellValue::Float(f) if f.fract() == 0.0 => Some(*f as i64),
            CellValue::Bool(b) => Some(if *b { 1 } else { 0 }),
            CellValue::Formula { result, .. } => result.as_i64(),
            _ => None,
        }
    }

    /// Try to get the value as a `&str`.
    pub fn as_str(&self) -> Option<&str> {
        match self {
            CellValue::Text(s) => Some(s.as_str()),
            CellValue::Formula { result, .. } => result.as_str(),
            _ => None,
        }
    }

    /// Return the inner formula result if this is a `Formula` variant.
    pub fn formula_result(&self) -> Option<&CellValue> {
        if let CellValue::Formula { result, .. } = self {
            Some(result)
        } else {
            None
        }
    }
}

impl fmt::Display for CellValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.display_value())
    }
}

// ── Conversions from calamine::DataType ─────────────────────────────────────

impl From<&calamine::DataType> for CellValue {
    fn from(dt: &calamine::DataType) -> Self {
        use calamine::DataType;
        match dt {
            DataType::Empty => CellValue::Empty,
            DataType::String(s) => CellValue::Text(s.clone()),
            DataType::Float(f) => CellValue::Float(*f),
            DataType::Int(i) => CellValue::Integer(*i),
            DataType::Bool(b) => CellValue::Bool(*b),
            DataType::Error(e) => CellValue::Error(format!("{e:?}")),
            DataType::DateTime(f) => {
                // calamine stores dates as OADate float
                if let Some(dt) = calamine::DataType::as_datetime(dt) {
                    CellValue::DateTime(dt)
                } else {
                    CellValue::Float(*f)
                }
            }
            DataType::DateTimeIso(s) => CellValue::Text(s.clone()),
            DataType::DurationIso(s) => CellValue::Text(s.clone()),
            DataType::Duration(f) => CellValue::Float(*f),
        }
    }
}

// ── Cell ─────────────────────────────────────────────────────────────────────

/// A single spreadsheet cell: its address, value, and optional style.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Cell {
    /// Position of the cell in the sheet (zero-based).
    pub address: CellAddress,
    /// The typed value of the cell.
    pub value: CellValue,
    /// Optional formatting/style information.
    pub style: Option<Style>,
}

impl Cell {
    /// Construct a new `Cell`.
    pub fn new(address: CellAddress, value: CellValue, style: Option<Style>) -> Self {
        Self {
            address,
            value,
            style,
        }
    }

    /// Convenience: return the display value.
    #[inline]
    pub fn display_value(&self) -> String {
        self.value.display_value()
    }

    /// Return `true` if the cell is empty.
    #[inline]
    pub fn is_empty(&self) -> bool {
        self.value.is_empty()
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a1_round_trip() {
        let cases = [
            ("A1", 0, 0),
            ("B2", 1, 1),
            ("Z1", 0, 25),
            ("AA1", 0, 26),
            ("BC42", 41, 54),
        ];
        for (s, row, col) in cases {
            let addr = CellAddress::from_a1(s).unwrap();
            assert_eq!(addr.row, row, "row mismatch for {s}");
            assert_eq!(addr.col, col, "col mismatch for {s}");
            assert_eq!(addr.to_a1(), s.to_ascii_uppercase());
        }
    }

    #[test]
    fn invalid_address() {
        assert!(CellAddress::from_a1("").is_err());
        assert!(CellAddress::from_a1("123").is_err());
        assert!(CellAddress::from_a1("A0").is_err()); // row 0 is invalid
    }

    #[test]
    fn cell_value_coercions() {
        assert_eq!(CellValue::Float(3.14).as_f64(), Some(3.14));
        assert_eq!(CellValue::Integer(7).as_i64(), Some(7));
        assert_eq!(CellValue::Bool(true).as_f64(), Some(1.0));
        assert_eq!(CellValue::Text("hi".into()).as_str(), Some("hi"));
        assert!(CellValue::Empty.is_empty());
    }
}

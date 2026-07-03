//! Number formatting and cell style information.

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

/// A resolved number-format pattern (e.g. `"#,##0.00"`, `"yyyy-mm-dd"`).
#[derive(Debug, Clone, Default, PartialEq, Eq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct NumberFormat {
    /// The numeric ID assigned by Excel (built-in IDs 0–163).
    pub id: u16,
    /// The format code string.
    pub code: String,
}

impl NumberFormat {
    /// Create a new `NumberFormat`.
    pub fn new(id: u16, code: impl Into<String>) -> Self {
        Self {
            id,
            code: code.into(),
        }
    }

    /// Return `true` if this format represents a date or date-time.
    pub fn is_date_time(&self) -> bool {
        let c = self.code.to_ascii_lowercase();
        // Excel built-in date format IDs
        matches!(self.id, 14..=17 | 22 | 164..=180)
            || c.contains('y')
            || c.contains('d')
            || (c.contains('h') && c.contains('m'))
    }

    /// Return `true` if this format represents a time-only value.
    pub fn is_time(&self) -> bool {
        matches!(self.id, 18..=21 | 45..=47)
    }
}

/// Font metadata extracted from the styles worksheet.
#[derive(Debug, Clone, Default)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Font {
    /// Font family name (e.g. `"Arial"`).
    pub name: Option<String>,
    /// Font size in points.
    pub size: Option<f32>,
    /// Bold.
    pub bold: bool,
    /// Italic.
    pub italic: bool,
    /// Underlined.
    pub underline: bool,
    /// HTML hex colour (e.g. `"FF0000"`).
    pub color: Option<String>,
}

/// Fill (background) metadata.
#[derive(Debug, Clone, Default)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Fill {
    /// Background HTML hex colour.
    pub fg_color: Option<String>,
    /// Pattern type (e.g. `"solid"`).
    pub pattern: Option<String>,
}

/// Horizontal alignment.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub enum HAlign {
    /// No explicit alignment.
    #[default]
    General,
    Left,
    Center,
    Right,
    Fill,
    Justify,
    CenterContinuous,
    Distributed,
}

/// Cell style: a bundle of formatting attributes.
#[derive(Debug, Clone, Default)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct Style {
    /// Number format.
    pub number_format: Option<NumberFormat>,
    /// Font.
    pub font: Option<Font>,
    /// Fill / background.
    pub fill: Option<Fill>,
    /// Horizontal text alignment.
    pub h_align: HAlign,
    /// Whether the cell text is wrapped.
    pub wrap_text: bool,
}

// ── Built-in format table ────────────────────────────────────────────────────

/// Look up the standard Excel format code for built-in IDs 0–49.
pub fn builtin_format_code(id: u16) -> Option<&'static str> {
    let codes: &[(u16, &str)] = &[
        (0, "General"),
        (1, "0"),
        (2, "0.00"),
        (3, "#,##0"),
        (4, "#,##0.00"),
        (9, "0%"),
        (10, "0.00%"),
        (11, "0.00E+00"),
        (12, "# ?/?"),
        (13, "# ??/??"),
        (14, "mm-dd-yy"),
        (15, "d-mmm-yy"),
        (16, "d-mmm"),
        (17, "mmm-yy"),
        (18, "h:mm AM/PM"),
        (19, "h:mm:ss AM/PM"),
        (20, "h:mm"),
        (21, "h:mm:ss"),
        (22, "m/d/yy h:mm"),
        (37, "#,##0 ;(#,##0)"),
        (38, "#,##0 ;[Red](#,##0)"),
        (39, "#,##0.00;(#,##0.00)"),
        (40, "#,##0.00;[Red](#,##0.00)"),
        (45, "mm:ss"),
        (46, "[h]:mm:ss"),
        (47, "mmss.0"),
        (48, "##0.0E+0"),
        (49, "@"),
    ];
    codes.iter().find(|(i, _)| *i == id).map(|(_, c)| *c)
}

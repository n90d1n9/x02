//! Table type definitions supporting various spreadsheet and document table formats.

use serde::{Deserialize, Serialize};

/// Represents the specific type or style of a table.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum TableType {
    /// Standard grid table
    Grid,
    /// List style without borders
    List,
    /// Pivot table (spreadsheet specific)
    Pivot,
    /// Query table (connected to external data)
    Query,
    /// XML mapped table
    Xml,
    /// Custom user-defined style
    Custom(String),
}

impl Default for TableType {
    fn default() -> Self {
        TableType::Grid
    }
}

/// Defines the position of the header row.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum HeaderRowPosition {
    Top,
    Bottom,
    Both,
    None,
}

/// Defines the style of table borders.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TableBorderStyle {
    pub top: Option<BorderDef>,
    pub bottom: Option<BorderDef>,
    pub left: Option<BorderDef>,
    pub right: Option<BorderDef>,
    pub horizontal: Option<BorderDef>,
    pub vertical: Option<BorderDef>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BorderDef {
    pub style: BorderStyle,
    pub color: Option<String>, // Hex color or theme reference
    pub width: Option<f32>,    // In points
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum BorderStyle {
    None,
    Solid,
    Dashed,
    Dotted,
    Double,
    Thick,
    Thin,
    Medium,
    DashDot,
    DashDotDot,
    SlantDashDot,
    Hair,
    MediumDashed,
    MediumDashDot,
    MediumDashDotDot,
}

impl Default for BorderStyle {
    fn default() -> Self {
        BorderStyle::None
    }
}

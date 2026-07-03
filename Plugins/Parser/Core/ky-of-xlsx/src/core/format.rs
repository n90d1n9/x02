//! Minimal XLSX cell formatting support.

/// Placeholder style type used for cell formatting and worksheet display metadata.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde-support", derive(serde::Serialize, serde::Deserialize))]
pub struct Style;

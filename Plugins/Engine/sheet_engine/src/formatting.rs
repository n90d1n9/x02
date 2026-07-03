//! Conditional formatting module for spreadsheet cells.
//!
//! This module provides Excel-like conditional formatting rules that automatically
//! apply styles to cells based on their values or formulas.

use serde::{Deserialize, Serialize};
use crate::cell::CellFormat;
use crate::grid::CellPosition;

/// A conditional formatting rule that applies styles based on conditions.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConditionalFormatRule {
    /// Unique identifier for this rule.
    pub id: String,
    /// The range of cells this rule applies to.
    pub range: CellRange,
    /// The condition that triggers the formatting.
    pub condition: FormatCondition,
    /// The format to apply when condition is met.
    pub format: CellFormat,
    /// Stop processing further rules if this one matches.
    pub stop_if_true: bool,
    /// Priority order (lower number = higher priority).
    pub priority: u32,
}

/// A range of cells defined by start and end positions.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct CellRange {
    pub start_col: u32,
    pub start_row: u32,
    pub end_col: u32,
    pub end_row: u32,
}

impl CellRange {
    pub fn new(start_col: u32, start_row: u32, end_col: u32, end_row: u32) -> Self {
        Self {
            start_col,
            start_row,
            end_col,
            end_row,
        }
    }

    pub fn contains(&self, pos: &CellPosition) -> bool {
        pos.col >= self.start_col
            && pos.col <= self.end_col
            && pos.row >= self.start_row
            && pos.row <= self.end_row
    }

    pub fn iter(&self) -> CellRangeIterator {
        CellRangeIterator {
            range: *self,
            current_col: self.start_col,
            current_row: self.start_row,
        }
    }
}

/// Iterator over all cells in a range.
pub struct CellRangeIterator {
    range: CellRange,
    current_col: u32,
    current_row: u32,
}

impl Iterator for CellRangeIterator {
    type Item = CellPosition;

    fn next(&mut self) -> Option<Self::Item> {
        if self.current_row > self.range.end_row {
            return None;
        }

        let pos = CellPosition::new(self.current_col, self.current_row);

        self.current_col += 1;
        if self.current_col > self.range.end_col {
            self.current_col = self.range.start_col;
            self.current_row += 1;
        }

        Some(pos)
    }
}

/// Conditions that can trigger conditional formatting.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FormatCondition {
    /// Cell value equals a specific value.
    CellIs { operator: ComparisonOperator, value: f64 },
    /// Formula evaluates to true.
    Formula { formula: String },
    /// Value is between two bounds.
    Between { min: f64, max: f64 },
    /// Value is in top N percent.
    TopPercent { percent: f64 },
    /// Value is in bottom N percent.
    BottomPercent { percent: f64 },
    /// Duplicate values in range.
    DuplicateValues,
    /// Unique values in range.
    UniqueValues,
    /// Contains specific text.
    TextContains { text: String },
    /// Starts with specific text.
    TextStartsWith { text: String },
    /// Ends with specific text.
    TextEndsWith { text: String },
    /// Date-based conditions.
    DateIs { date_type: DateCondition },
    /// Color scale (2 or 3 colors).
    ColorScale { stops: Vec<ColorScaleStop> },
    /// Data bar visualization.
    DataBar { 
        min_value: Option<f64>, 
        max_value: Option<f64>,
        bar_color: String,
        show_value: bool,
    },
    /// Icon set visualization.
    IconSet { 
        icon_set_type: IconSetType,
        reverse_order: bool,
        show_value: bool,
    },
}

/// Comparison operators for cell value conditions.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ComparisonOperator {
    Equal,
    NotEqual,
    GreaterThan,
    GreaterThanOrEqual,
    LessThan,
    LessThanOrEqual,
}

/// Date-based condition types.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DateCondition {
    Today,
    Yesterday,
    Tomorrow,
    Last7Days,
    LastMonth,
    NextMonth,
    ThisWeek,
    LastWeek,
    NextWeek,
}

/// A stop in a color scale gradient.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ColorScaleStop {
    /// Position in the scale (0.0 to 1.0).
    pub position: f64,
    /// Color at this position.
    pub color: String,
    /// Optional value for this stop.
    pub value: Option<f64>,
}

/// Types of icon sets for conditional formatting.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum IconSetType {
    ThreeArrows,
    ThreeArrowsGrayed,
    ThreeFlags,
    ThreeLights,
    ThreeSigns,
    ThreeSymbols,
    ThreeTrafficLights,
    FourArrows,
    FourArrowsGrayed,
    FourRedToBlack,
    FourRating,
    FourTrafficLights,
    FiveArrows,
    FiveArrowsGrayed,
    FiveQuarters,
    FiveRating,
}

/// Manager for conditional formatting rules.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ConditionalFormatManager {
    rules: Vec<ConditionalFormatRule>,
}

impl ConditionalFormatManager {
    pub fn new() -> Self {
        Self { rules: Vec::new() }
    }

    /// Add a new conditional formatting rule.
    pub fn add_rule(&mut self, rule: ConditionalFormatRule) {
        self.rules.push(rule);
        self.rules.sort_by_key(|r| r.priority);
    }

    /// Remove a rule by ID.
    pub fn remove_rule(&mut self, id: &str) -> Option<ConditionalFormatRule> {
        if let Some(idx) = self.rules.iter().position(|r| r.id == id) {
            Some(self.rules.remove(idx))
        } else {
            None
        }
    }

    /// Get all rules that apply to a specific cell.
    pub fn get_rules_for_cell(&self, pos: &CellPosition) -> Vec<&ConditionalFormatRule> {
        self.rules
            .iter()
            .filter(|rule| rule.range.contains(pos))
            .collect()
    }

    /// Get all rules.
    pub fn get_all_rules(&self) -> &[ConditionalFormatRule] {
        &self.rules
    }

    /// Clear all rules.
    pub fn clear(&mut self) {
        self.rules.clear();
    }

    /// Get rule count.
    pub fn rule_count(&self) -> usize {
        self.rules.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cell_range_contains() {
        let range = CellRange::new(0, 0, 5, 5);
        assert!(range.contains(&CellPosition::new(0, 0)));
        assert!(range.contains(&CellPosition::new(5, 5)));
        assert!(range.contains(&CellPosition::new(2, 3)));
        assert!(!range.contains(&CellPosition::new(6, 3)));
        assert!(!range.contains(&CellPosition::new(3, 6)));
    }

    #[test]
    fn test_cell_range_iterator() {
        let range = CellRange::new(0, 0, 1, 1);
        let positions: Vec<_> = range.iter().collect();
        assert_eq!(positions.len(), 4);
        assert_eq!(positions[0], CellPosition::new(0, 0));
        assert_eq!(positions[1], CellPosition::new(1, 0));
        assert_eq!(positions[2], CellPosition::new(0, 1));
        assert_eq!(positions[3], CellPosition::new(1, 1));
    }

    #[test]
    fn test_conditional_format_manager() {
        let mut manager = ConditionalFormatManager::new();
        
        let rule = ConditionalFormatRule {
            id: "rule1".to_string(),
            range: CellRange::new(0, 0, 5, 5),
            condition: FormatCondition::CellIs {
                operator: ComparisonOperator::GreaterThan,
                value: 100.0,
            },
            format: CellFormat {
                bold: true,
                italic: false,
                background_color: Some("#FF0000".to_string()),
                text_color: Some("#FFFFFF".to_string()),
                number_format: None,
            },
            stop_if_true: false,
            priority: 1,
        };

        manager.add_rule(rule.clone());
        assert_eq!(manager.rule_count(), 1);

        let rules = manager.get_rules_for_cell(&CellPosition::new(2, 2));
        assert_eq!(rules.len(), 1);

        let removed = manager.remove_rule("rule1");
        assert!(removed.is_some());
        assert_eq!(manager.rule_count(), 0);
    }
}

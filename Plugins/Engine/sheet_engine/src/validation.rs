//! Data validation module for spreadsheet cells.
//!
//! This module provides Excel-like data validation rules that restrict what can be entered
//! into cells, including dropdown lists, number ranges, date ranges, and custom formulas.

use serde::{Deserialize, Serialize};
use crate::grid::CellPosition;

/// A data validation rule that restricts cell input.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataValidationRule {
    /// Unique identifier for this rule.
    pub id: String,
    /// The range of cells this rule applies to.
    pub range: CellRange,
    /// The type of validation.
    pub validation_type: ValidationType,
    /// How to handle invalid data.
    pub error_style: ErrorStyle,
    /// Error message shown when validation fails.
    pub error_message: Option<String>,
    /// Input message shown when cell is selected.
    pub input_message: Option<InputMessage>,
    /// Whether to show input message.
    pub show_input_message: bool,
    /// Whether to show error alert.
    pub show_error_alert: bool,
}

/// Range of cells for validation (reuses formatting range).
pub use crate::formatting::CellRange;

/// Types of data validation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ValidationType {
    /// Any value is allowed.
    Any,
    /// Whole number within range.
    WholeNumber { 
        operator: ComparisonOperator, 
        min: Option<i64>, 
        max: Option<i64>,
        formula_min: Option<String>,
        formula_max: Option<String>,
    },
    /// Decimal number within range.
    Decimal { 
        operator: ComparisonOperator, 
        min: Option<f64>, 
        max: Option<f64>,
        formula_min: Option<String>,
        formula_max: Option<String>,
    },
    /// Date within range.
    Date { 
        operator: ComparisonOperator, 
        min: Option<String>, 
        max: Option<String>,
        formula_min: Option<String>,
        formula_max: Option<String>,
    },
    /// Time within range.
    Time { 
        operator: ComparisonOperator, 
        min: Option<String>, 
        max: Option<String>,
        formula_min: Option<String>,
        formula_max: Option<String>,
    },
    /// Text length within range.
    TextLength { 
        operator: ComparisonOperator, 
        min: Option<u32>, 
        max: Option<u32>,
        formula_min: Option<String>,
        formula_max: Option<String>,
    },
    /// Value in a list (dropdown).
    List { 
        /// Explicit list of values.
        values: Option<Vec<String>>,
        /// Formula or range reference for list source.
        source_formula: Option<String>,
        /// Whether to show dropdown arrow.
        show_dropdown: bool,
        /// Whether to allow blank cells.
        allow_blank: bool,
    },
    /// Custom formula validation.
    Custom { 
        formula: String,
    },
}

/// Comparison operators for validation.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ComparisonOperator {
    Between,
    NotBetween,
    Equal,
    NotEqual,
    GreaterThan,
    LessThan,
    GreaterThanOrEqual,
    LessThanOrEqual,
}

/// Error alert styles.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum ErrorStyle {
    /// Stop: User cannot enter invalid data.
    Stop,
    /// Warning: User is warned but can override.
    Warning,
    /// Information: User is informed but can proceed.
    Information,
}

/// Input message shown when cell is selected.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InputMessage {
    /// Message title.
    pub title: Option<String>,
    /// Message content.
    pub message: String,
    /// Position relative to cell.
    pub position: InputMessagePosition,
}

/// Position of input message.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum InputMessagePosition {
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight,
}

/// Manager for data validation rules.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DataValidationManager {
    rules: Vec<DataValidationRule>,
}

impl DataValidationManager {
    pub fn new() -> Self {
        Self { rules: Vec::new() }
    }

    /// Add a new data validation rule.
    pub fn add_rule(&mut self, rule: DataValidationRule) {
        self.rules.push(rule);
    }

    /// Remove a rule by ID.
    pub fn remove_rule(&mut self, id: &str) -> Option<DataValidationRule> {
        if let Some(idx) = self.rules.iter().position(|r| r.id == id) {
            Some(self.rules.remove(idx))
        } else {
            None
        }
    }

    /// Get all rules that apply to a specific cell.
    pub fn get_rules_for_cell(&self, pos: &CellPosition) -> Vec<&DataValidationRule> {
        self.rules
            .iter()
            .filter(|rule| rule.range.contains(pos))
            .collect()
    }

    /// Validate a value against rules for a cell.
    pub fn validate_value(&self, pos: &CellPosition, value: &str) -> ValidationResult {
        let rules = self.get_rules_for_cell(pos);
        
        for rule in rules {
            match self.validate_against_rule(value, rule) {
                ValidationResult::Invalid { message } => {
                    return ValidationResult::Invalid { 
                        message: message.or_else(|| rule.error_message.clone())
                    };
                }
                ValidationResult::Valid => continue,
            }
        }
        
        ValidationResult::Valid
    }

    fn validate_against_rule(&self, value: &str, rule: &DataValidationRule) -> ValidationResult {
        // Simplified validation - full implementation would parse formulas and evaluate
        match &rule.validation_type {
            ValidationType::Any => ValidationResult::Valid,
            ValidationType::List { values, source_formula, .. } => {
                if let Some(vals) = values {
                    if vals.contains(&value.to_string()) {
                        ValidationResult::Valid
                    } else {
                        ValidationResult::Invalid { message: Some("Value not in list".to_string()) }
                    }
                } else if source_formula.is_some() {
                    // Would need to evaluate formula to get list
                    ValidationResult::Valid // Assume valid for now
                } else {
                    ValidationResult::Valid
                }
            }
            ValidationType::WholeNumber { operator, min, max, .. } => {
                if let Ok(num) = value.parse::<i64>() {
                    self.check_number_operator(num as f64, *operator, *min.map(|v| v as f64), *max.map(|v| v as f64))
                } else {
                    ValidationResult::Invalid { message: Some("Must be a whole number".to_string()) }
                }
            }
            ValidationType::Decimal { operator, min, max, .. } => {
                if let Ok(num) = value.parse::<f64>() {
                    self.check_number_operator(num, *operator, *min, *max)
                } else {
                    ValidationResult::Invalid { message: Some("Must be a number".to_string()) }
                }
            }
            // Other types would be implemented similarly
            _ => ValidationResult::Valid,
        }
    }

    fn check_number_operator(
        &self,
        value: f64,
        operator: ComparisonOperator,
        min: Option<f64>,
        max: Option<f64>,
    ) -> ValidationResult {
        let valid = match operator {
            ComparisonOperator::Between => {
                min.map_or(true, |m| value >= m) && max.map_or(true, |m| value <= m)
            }
            ComparisonOperator::NotBetween => {
                min.map_or(false, |m| value < m) || max.map_or(false, |m| value > m)
            }
            ComparisonOperator::Equal => min.map_or(true, |m| value == m),
            ComparisonOperator::NotEqual => min.map_or(true, |m| value != m),
            ComparisonOperator::GreaterThan => min.map_or(true, |m| value > m),
            ComparisonOperator::LessThan => min.map_or(true, |m| value < m),
            ComparisonOperator::GreaterThanOrEqual => min.map_or(true, |m| value >= m),
            ComparisonOperator::LessThanOrEqual => min.map_or(true, |m| value <= m),
        };

        if valid {
            ValidationResult::Valid
        } else {
            ValidationResult::Invalid { message: Some("Value does not meet validation criteria".to_string()) }
        }
    }

    /// Get all rules.
    pub fn get_all_rules(&self) -> &[DataValidationRule] {
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

/// Result of validating a cell value.
#[derive(Debug, Clone, PartialEq)]
pub enum ValidationResult {
    Valid,
    Invalid { message: Option<String> },
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_list_validation() {
        let mut manager = DataValidationManager::new();
        
        let rule = DataValidationRule {
            id: "list1".to_string(),
            range: CellRange::new(0, 0, 5, 5),
            validation_type: ValidationType::List {
                values: Some(vec!["Yes".to_string(), "No".to_string(), "Maybe".to_string()]),
                source_formula: None,
                show_dropdown: true,
                allow_blank: false,
            },
            error_style: ErrorStyle::Stop,
            error_message: Some("Please select Yes, No, or Maybe".to_string()),
            input_message: None,
            show_input_message: false,
            show_error_alert: true,
        };

        manager.add_rule(rule);

        assert_eq!(manager.validate_value(&CellPosition::new(0, 0), "Yes"), ValidationResult::Valid);
        assert_eq!(manager.validate_value(&CellPosition::new(0, 0), "No"), ValidationResult::Valid);
        
        let result = manager.validate_value(&CellPosition::new(0, 0), "Invalid");
        assert!(matches!(result, ValidationResult::Invalid { .. }));
    }

    #[test]
    fn test_number_range_validation() {
        let mut manager = DataValidationManager::new();
        
        let rule = DataValidationRule {
            id: "range1".to_string(),
            range: CellRange::new(0, 0, 5, 5),
            validation_type: ValidationType::WholeNumber {
                operator: ComparisonOperator::Between,
                min: Some(1),
                max: Some(100),
                formula_min: None,
                formula_max: None,
            },
            error_style: ErrorStyle::Warning,
            error_message: Some("Enter a number between 1 and 100".to_string()),
            input_message: None,
            show_input_message: false,
            show_error_alert: true,
        };

        manager.add_rule(rule);

        assert_eq!(manager.validate_value(&CellPosition::new(0, 0), "50"), ValidationResult::Valid);
        assert_eq!(manager.validate_value(&CellPosition::new(0, 0), "1"), ValidationResult::Valid);
        assert_eq!(manager.validate_value(&CellPosition::new(0, 0), "100"), ValidationResult::Valid);
        
        let result = manager.validate_value(&CellPosition::new(0, 0), "101");
        assert!(matches!(result, ValidationResult::Invalid { .. }));
        
        let result = manager.validate_value(&CellPosition::new(0, 0), "abc");
        assert!(matches!(result, ValidationResult::Invalid { .. }));
    }
}

use crate::ast::{parse_formula, BinaryOperator, Expr};
use crate::cell::CellValue;
use crate::grid::{CellPosition, SheetGrid};
use std::collections::{HashMap, HashSet};
use thiserror::Error;

/// Error types that can occur during formula evaluation.
#[derive(Debug, Error)]
pub enum EvalError {
    /// A circular reference was detected in the formula dependency graph.
    #[error("Circular reference detected at cell")]
    CircularReference,
    
    /// The formula could not be parsed due to syntax errors.
    #[error("Parse error: {0}")]
    ParseError(String),
    
    /// A cell reference points to an invalid location.
    #[error("Invalid reference: {0}")]
    InvalidReference(String),
    
    /// An error occurred while applying a structure edit.
    #[error("Structure edit error: {0}")]
    StructureError(String),
    
    /// Division by zero was attempted in a formula.
    #[error("Divide by zero")]
    DivideByZero,
}

/// A simplified formula evaluator for the spreadsheet DAG.
/// 
/// The evaluator uses depth-first traversal with cycle detection to evaluate
/// all formulas in the grid, caching intermediate results to avoid redundant computation.
pub struct FormulaEvaluator;

impl FormulaEvaluator {
    pub fn new() -> Self {
        Self
    }

    /// Evaluates the entire grid, updating the `evaluated_value` of each cell.
    /// 
    /// This method performs a complete evaluation pass over all cells in the grid,
    /// resolving formula dependencies and detecting circular references.
    /// 
    /// # Errors
    /// 
    /// Returns `EvalError::CircularReference` if any circular dependency is detected.
    pub fn evaluate_grid(&self, grid: &mut SheetGrid) -> Result<(), EvalError> {
        let positions: Vec<CellPosition> = grid.iter().map(|(pos, _)| *pos).collect();
        let mut evaluated_values = HashMap::new();

        for pos in positions {
            let mut visiting = HashSet::new();
            let value = Self::eval_cell(pos, grid, &mut evaluated_values, &mut visiting)?;
            evaluated_values.insert(pos, value);
        }

        for (pos, val) in &evaluated_values {
            if let Some(cell) = grid.get_cell_mut(&pos) {
                cell.evaluated_value = val.clone();
            }
        }

        Ok(())
    }

    fn eval_cell(
        pos: CellPosition,
        grid: &SheetGrid,
        cache: &mut HashMap<CellPosition, CellValue>,
        visiting: &mut HashSet<CellPosition>,
    ) -> Result<CellValue, EvalError> {
        if let Some(value) = cache.get(&pos) {
            return Ok(value.clone());
        }
        if !visiting.insert(pos) {
            return Err(EvalError::CircularReference);
        }

        let value = match grid.get_cell(&pos) {
            Some(cell) if cell.is_formula() => {
                let expr = parse_formula(&cell.raw_content).map_err(EvalError::ParseError)?;
                Self::eval_expr(&expr, grid, cache, visiting)?
            }
            Some(cell) => Self::eval_literal(&cell.raw_content),
            None => CellValue::Empty,
        };

        visiting.remove(&pos);
        cache.insert(pos, value.clone());
        Ok(value)
    }

    fn eval_literal(raw: &str) -> CellValue {
        if raw.is_empty() {
            return CellValue::Empty;
        }
        if let Ok(n) = raw.parse::<f64>() {
            return CellValue::Number(n);
        }
        match raw.to_ascii_lowercase().as_str() {
            "true" => CellValue::Boolean(true),
            "false" => CellValue::Boolean(false),
            _ => CellValue::String(raw.to_owned()),
        }
    }

    fn eval_expr(
        expr: &Expr,
        grid: &SheetGrid,
        cache: &mut HashMap<CellPosition, CellValue>,
        visiting: &mut HashSet<CellPosition>,
    ) -> Result<CellValue, EvalError> {
        match expr {
            Expr::Number(n) => Ok(CellValue::Number(*n)),
            Expr::String(s) => Ok(CellValue::String(s.clone())),
            Expr::Error(error) => Ok(CellValue::Error(error.clone())),
            Expr::CellRef(col, row) => {
                Self::eval_cell(CellPosition::new(*col, *row), grid, cache, visiting)
            }
            Expr::BinaryOp(left, op, right) => {
                let l_val = Self::eval_expr(left, grid, cache, visiting)?;
                let r_val = Self::eval_expr(right, grid, cache, visiting)?;

                Ok(match (l_val, r_val) {
                    (CellValue::Error(error), _) | (_, CellValue::Error(error)) => {
                        CellValue::Error(error)
                    }
                    (CellValue::Number(l), CellValue::Number(r)) => match op {
                        BinaryOperator::Add => CellValue::Number(l + r),
                        BinaryOperator::Subtract => CellValue::Number(l - r),
                        BinaryOperator::Multiply => CellValue::Number(l * r),
                        BinaryOperator::Divide => {
                            if r == 0.0 {
                                CellValue::Error("#DIV/0!".to_string())
                            } else {
                                CellValue::Number(l / r)
                            }
                        }
                    },
                    _ => CellValue::Error("#VALUE!".to_string()),
                })
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::cell::{Cell, CellValue};

    fn cell(content: &str) -> Cell {
        Cell::new(content)
    }

    #[test]
    fn evaluate_literals_and_formula_chain() {
        let mut grid = SheetGrid::new("Sheet 1");
        grid.set_cell(CellPosition::new(0, 0), cell("10"));
        grid.set_cell(CellPosition::new(1, 0), cell("=A1*2"));
        grid.set_cell(CellPosition::new(2, 0), cell("=B1+5"));

        FormulaEvaluator::new().evaluate_grid(&mut grid).unwrap();

        assert_eq!(
            grid.get_cell(&CellPosition::new(0, 0))
                .unwrap()
                .evaluated_value,
            CellValue::Number(10.0)
        );
        assert_eq!(
            grid.get_cell(&CellPosition::new(1, 0))
                .unwrap()
                .evaluated_value,
            CellValue::Number(20.0)
        );
        assert_eq!(
            grid.get_cell(&CellPosition::new(2, 0))
                .unwrap()
                .evaluated_value,
            CellValue::Number(25.0)
        );
    }

    #[test]
    fn evaluate_divide_by_zero_as_cell_error() {
        let mut grid = SheetGrid::new("Sheet 1");
        grid.set_cell(CellPosition::new(0, 0), cell("=10/0"));

        FormulaEvaluator::new().evaluate_grid(&mut grid).unwrap();

        assert_eq!(
            grid.get_cell(&CellPosition::new(0, 0))
                .unwrap()
                .evaluated_value,
            CellValue::Error("#DIV/0!".to_string())
        );
    }

    #[test]
    fn detect_circular_reference() {
        let mut grid = SheetGrid::new("Sheet 1");
        grid.set_cell(CellPosition::new(0, 0), cell("=B1"));
        grid.set_cell(CellPosition::new(1, 0), cell("=A1"));

        assert!(matches!(
            FormulaEvaluator::new().evaluate_grid(&mut grid),
            Err(EvalError::CircularReference)
        ));
    }
}

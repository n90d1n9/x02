#[derive(Debug, Clone, PartialEq)]
pub enum Expr {
    Number(f64),
    String(String),
    Error(String),
    CellRef(u32, u32), // col, row (zero-based)
    BinaryOp(Box<Expr>, BinaryOperator, Box<Expr>),
}

/// Binary operators supported in spreadsheet formulas.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BinaryOperator {
    Add,
    Subtract,
    Multiply,
    Divide,
}

/// Parse a formula string into an expression AST.
/// 
/// The input may optionally start with '=' which will be stripped.
/// Supports cell references (A1, $B$2, etc.), numbers, and basic arithmetic.
/// 
/// # Examples
/// 
/// ```
/// use sheet_engine::ast::{parse_formula, Expr};
/// 
/// let expr = parse_formula("=A1+B2").unwrap();
/// assert!(matches!(expr, Expr::BinaryOp(_, _, _)));
/// ```
pub fn parse_formula(input: &str) -> Result<Expr, String> {
    let s = input
        .trim()
        .strip_prefix('=')
        .unwrap_or(input.trim())
        .trim();

    parse_expr(s)
}

fn parse_expr(input: &str) -> Result<Expr, String> {
    let s = input.trim();
    if s.is_empty() {
        return Err("Could not parse empty formula".to_string());
    }
    if s.eq_ignore_ascii_case("#REF!") {
        return Ok(Expr::Error("#REF!".to_owned()));
    }

    // Parse addition/subtraction (lowest precedence)
    if let Some((idx, op)) = find_binary_operator(s, &['+', '-']) {
        let left = parse_expr(&s[..idx])?;
        let right = parse_expr(&s[idx + op.len_utf8()..])?;
        return Ok(Expr::BinaryOp(
            Box::new(left),
            match op {
                '+' => BinaryOperator::Add,
                '-' => BinaryOperator::Subtract,
                _ => unreachable!(),
            },
            Box::new(right),
        ));
    }

    // Parse multiplication/division (higher precedence)
    if let Some((idx, op)) = find_binary_operator(s, &['*', '/']) {
        let left = parse_expr(&s[..idx])?;
        let right = parse_expr(&s[idx + op.len_utf8()..])?;
        return Ok(Expr::BinaryOp(
            Box::new(left),
            match op {
                '*' => BinaryOperator::Multiply,
                '/' => BinaryOperator::Divide,
                _ => unreachable!(),
            },
            Box::new(right),
        ));
    }

    // Try to parse as cell reference
    if let Some(expr) = parse_cell_ref(s)? {
        return Ok(expr);
    }

    // Try to parse as number
    if let Ok(n) = s.parse::<f64>() {
        return Ok(Expr::Number(n));
    }

    Err(format!("Could not parse: {}", s))
}

/// Find the rightmost binary operator at the current precedence level.
/// This ensures left-to-right associativity for operators of the same precedence.
fn find_binary_operator(s: &str, operators: &[char]) -> Option<(usize, char)> {
    s.char_indices()
        .rev()
        .find(|(idx, ch)| *idx > 0 && operators.contains(ch))
}

fn parse_cell_ref(s: &str) -> Result<Option<Expr>, String> {
    let s = s.trim();
    let after_col_absolute = s.strip_prefix('$').unwrap_or(s);
    let col_absolute_byte_len = s.len() - after_col_absolute.len();
    let col_byte_len = after_col_absolute
        .char_indices()
        .take_while(|(_, ch)| ch.is_ascii_alphabetic())
        .map(|(idx, ch)| idx + ch.len_utf8())
        .last()
        .unwrap_or(0);

    if col_byte_len == 0 || col_absolute_byte_len + col_byte_len == s.len() {
        return Ok(None);
    }

    let col_part = &after_col_absolute[..col_byte_len];
    let row_part = &after_col_absolute[col_byte_len..];
    let row_part = row_part.strip_prefix('$').unwrap_or(row_part);
    if row_part.is_empty() || !row_part.chars().all(|ch| ch.is_ascii_digit()) {
        return Ok(None);
    }

    let col = col_part
        .to_ascii_uppercase()
        .chars()
        .fold(0, |acc, ch| acc * 26 + (ch as u32 - 'A' as u32 + 1))
        - 1;
    let row = row_part
        .parse::<u32>()
        .map_err(|_| "Invalid row".to_string())?;

    if row == 0 {
        return Err("Invalid row".to_string());
    }

    Ok(Some(Expr::CellRef(col, row - 1)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_cell_reference() {
        assert_eq!(parse_formula("=AA10").unwrap(), Expr::CellRef(26, 9));
    }

    #[test]
    fn parse_absolute_cell_reference_markers() {
        assert_eq!(parse_formula("=$A$1").unwrap(), Expr::CellRef(0, 0));
        assert_eq!(parse_formula("=A$1").unwrap(), Expr::CellRef(0, 0));
        assert_eq!(parse_formula("=$A1").unwrap(), Expr::CellRef(0, 0));
    }

    #[test]
    fn parse_ref_error_literal() {
        assert_eq!(
            parse_formula("=#REF!").unwrap(),
            Expr::Error("#REF!".to_owned()),
        );
    }

    #[test]
    fn parse_operator_precedence() {
        let expr = parse_formula("=A1+B1*2").unwrap();
        assert_eq!(
            expr,
            Expr::BinaryOp(
                Box::new(Expr::CellRef(0, 0)),
                BinaryOperator::Add,
                Box::new(Expr::BinaryOp(
                    Box::new(Expr::CellRef(1, 0)),
                    BinaryOperator::Multiply,
                    Box::new(Expr::Number(2.0)),
                )),
            )
        );
    }

    #[test]
    fn parse_division_and_subtraction() {
        let expr = parse_formula("=A1/2-3").unwrap();
        assert_eq!(
            expr,
            Expr::BinaryOp(
                Box::new(Expr::BinaryOp(
                    Box::new(Expr::CellRef(0, 0)),
                    BinaryOperator::Divide,
                    Box::new(Expr::Number(2.0)),
                )),
                BinaryOperator::Subtract,
                Box::new(Expr::Number(3.0)),
            )
        );
    }
}

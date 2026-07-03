import '../model/sheet_formula_health.dart';
import '../model/sheet_formula_issue_sort.dart';

class SheetFormulaIssueSorter {
  const SheetFormulaIssueSorter._();

  static List<SheetFormulaIssue> sort(
    Iterable<SheetFormulaIssue> issues, {
    SheetFormulaIssueSortMode mode = SheetFormulaIssueSortMode.cell,
  }) {
    final sorted = [...issues];
    sorted.sort(
      (left, right) => switch (mode) {
        SheetFormulaIssueSortMode.cell => _compareByCell(left, right),
        SheetFormulaIssueSortMode.code => _compareByCode(left, right),
      },
    );
    return List.unmodifiable(sorted);
  }

  static int _compareByCell(SheetFormulaIssue left, SheetFormulaIssue right) {
    final row = left.address.row.compareTo(right.address.row);
    if (row != 0) return row;
    final column = left.address.col.compareTo(right.address.col);
    if (column != 0) return column;
    return left.code.compareTo(right.code);
  }

  static int _compareByCode(SheetFormulaIssue left, SheetFormulaIssue right) {
    final code = left.code.compareTo(right.code);
    if (code != 0) return code;
    return _compareByCell(left, right);
  }
}

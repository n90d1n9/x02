import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_health.dart';

class SheetFormulaIssueTraceBuilder {
  const SheetFormulaIssueTraceBuilder._();

  static List<CellSelection> build(SheetFormulaIssue issue) {
    if (issue.relatedSelections.isNotEmpty) {
      return _uniqueSelections(issue.relatedSelections);
    }

    return [CellSelection.single(issue.address)];
  }

  static List<CellSelection> buildAll(Iterable<SheetFormulaIssue> issues) {
    return _uniqueSelections([for (final issue in issues) ...build(issue)]);
  }

  static List<CellSelection> _uniqueSelections(Iterable<CellSelection> items) {
    final seen = <String>{};
    return [
      for (final selection in items)
        if (seen.add(selection.label)) selection,
    ];
  }
}

import '../model/sheet_formula_health.dart';

class SheetFormulaIssueFocus {
  const SheetFormulaIssueFocus._();

  static int clampIndex(int index, int issueCount) {
    if (issueCount <= 0) return 0;
    return index.clamp(0, issueCount - 1).toInt();
  }

  static int nextIndex(int index, int issueCount) {
    if (issueCount <= 0) return 0;
    return (clampIndex(index, issueCount) + 1) % issueCount;
  }

  static int previousIndex(int index, int issueCount) {
    if (issueCount <= 0) return 0;
    return (clampIndex(index, issueCount) - 1 + issueCount) % issueCount;
  }

  static SheetFormulaIssue? issueAt(List<SheetFormulaIssue> issues, int index) {
    if (issues.isEmpty) return null;
    return issues[clampIndex(index, issues.length)];
  }
}

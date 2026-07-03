import 'cell/cell_address.dart';
import 'cell/cell_selection.dart';

class SheetFormulaHealth {
  const SheetFormulaHealth({required this.formulaCount, required this.issues});

  final int formulaCount;
  final List<SheetFormulaIssue> issues;

  int get issueCount => issues.length;
  int get healthyCount {
    final impactedAddresses = {for (final issue in issues) issue.address};
    return formulaCount - impactedAddresses.length;
  }

  bool get hasIssues => issues.isNotEmpty;

  Map<String, int> get issueCountsByCode {
    final counts = <String, int>{};
    for (final issue in issues) {
      counts.update(issue.code, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

class SheetFormulaIssue {
  const SheetFormulaIssue({
    required this.address,
    required this.formula,
    required this.result,
    required this.code,
    required this.title,
    required this.message,
    required this.suggestion,
    this.relatedSelections = const [],
  });

  final CellAddress address;
  final String formula;
  final String result;
  final String code;
  final String title;
  final String message;
  final String suggestion;
  final List<CellSelection> relatedSelections;

  String get label => address.label;
}

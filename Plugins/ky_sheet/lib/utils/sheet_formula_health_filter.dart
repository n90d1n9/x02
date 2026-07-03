import '../model/sheet_formula_health.dart';

class SheetFormulaHealthFilter {
  const SheetFormulaHealthFilter._();

  static List<SheetFormulaIssue> apply(
    Iterable<SheetFormulaIssue> issues, {
    String? issueCode,
    String query = '',
  }) {
    final code = issueCode?.trim();
    final normalizedQuery = query.trim().toLowerCase();

    return List.unmodifiable(
      issues.where((issue) {
        final matchesCode = code == null || code.isEmpty || issue.code == code;
        final matchesQuery =
            normalizedQuery.isEmpty || _matchesQuery(issue, normalizedQuery);
        return matchesCode && matchesQuery;
      }),
    );
  }

  static bool _matchesQuery(SheetFormulaIssue issue, String query) {
    return [
      issue.label,
      issue.code,
      issue.title,
      issue.message,
      issue.suggestion,
      issue.formula,
      issue.result,
      for (final selection in issue.relatedSelections) selection.label,
    ].any((value) => value.toLowerCase().contains(query));
  }
}

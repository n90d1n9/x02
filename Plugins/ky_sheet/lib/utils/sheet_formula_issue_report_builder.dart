import '../model/sheet_formula_health.dart';
import 'sheet_formula_issue_guidance.dart';

class SheetFormulaIssueReportBuilder {
  const SheetFormulaIssueReportBuilder._();

  static String buildTsv(Iterable<SheetFormulaIssue> issues) {
    final buffer = StringBuffer(
      'Cell\tCode\tTitle\tFormula\tSuggestion\tNext Check\tAdditional Checks',
    );

    for (final issue in issues) {
      final guidance = SheetFormulaIssueGuidanceBuilder.build(issue);
      buffer
        ..writeln()
        ..writeAll(
          [
            issue.label,
            issue.code,
            issue.title,
            issue.formula,
            issue.suggestion,
            guidance.checks.isEmpty ? '' : guidance.checks.first,
            guidance.checks.skip(1).join(' | '),
          ].map(_cellText),
          '\t',
        );
    }

    return buffer.toString();
  }

  static String _cellText(String value) {
    return value.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();
  }
}

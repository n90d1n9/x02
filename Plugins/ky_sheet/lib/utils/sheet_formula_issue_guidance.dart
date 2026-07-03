import '../model/sheet_formula_health.dart';

class SheetFormulaIssueGuidance {
  const SheetFormulaIssueGuidance({required this.title, required this.checks});

  final String title;
  final List<String> checks;
}

class SheetFormulaIssueGuidanceBuilder {
  const SheetFormulaIssueGuidanceBuilder._();

  static SheetFormulaIssueGuidance build(SheetFormulaIssue issue) {
    final references = _referenceLabels(issue);

    return switch (issue.code.trim().toUpperCase()) {
      '#DIV/0' => SheetFormulaIssueGuidance(
        title: 'Check the denominator',
        checks: [
          'Trace denominator references: ${_referenceSummary(references)}.',
          'Look for zero, blank, or text values where the divisor is expected.',
          'Use IF to guard the division once the source data is understood.',
        ],
      ),
      '#CYCLE' => SheetFormulaIssueGuidance(
        title: 'Break the dependency loop',
        checks: [
          'Trace the related cells and find which formula points back to ${issue.label}.',
          'Move one dependency into an input cell or replace one circular reference.',
          'Recalculate after each change to confirm the loop is gone.',
        ],
      ),
      '#NAME' => const SheetFormulaIssueGuidance(
        title: 'Review names and functions',
        checks: [
          'Check function spelling and argument separators.',
          'Confirm named ranges used by the formula still exist.',
          'Rename or recreate missing names before editing dependent formulas.',
        ],
      ),
      '#REF' => SheetFormulaIssueGuidance(
        title: 'Repair the reference',
        checks: [
          'Inspect referenced ranges: ${_referenceSummary(references)}.',
          'Restore deleted rows, columns, or named ranges used by this formula.',
          'Replace broken references with the current source range.',
        ],
      ),
      '#VALUE' => SheetFormulaIssueGuidance(
        title: 'Normalize the inputs',
        checks: [
          'Inspect referenced values: ${_referenceSummary(references)}.',
          'Convert numbers stored as text before recalculating.',
          'Check that functions receive the expected scalar or range shape.',
        ],
      ),
      '#N/A' => SheetFormulaIssueGuidance(
        title: 'Check lookup coverage',
        checks: [
          'Compare lookup keys against source ranges: ${_referenceSummary(references)}.',
          'Trim extra spaces and align value types before recalculating.',
          'Confirm the lookup table includes the requested key.',
        ],
      ),
      '#NUM' => SheetFormulaIssueGuidance(
        title: 'Check numeric bounds',
        checks: [
          'Inspect numeric inputs: ${_referenceSummary(references)}.',
          'Look for oversized values, invalid roots, or unstable divisions.',
          'Round or constrain source values before recalculating.',
        ],
      ),
      _ => SheetFormulaIssueGuidance(
        title: 'Review the formula',
        checks: [
          'Inspect references: ${_referenceSummary(references)}.',
          'Check spelling, parentheses, separators, and unsupported function names.',
          'Trace related cells to isolate the first failing input.',
        ],
      ),
    };
  }

  static List<String> _referenceLabels(SheetFormulaIssue issue) {
    return [
      for (final selection in issue.relatedSelections)
        if (selection.label != issue.label) selection.label,
    ];
  }

  static String _referenceSummary(List<String> references) {
    if (references.isEmpty) return 'referenced cells';
    return references.join(', ');
  }
}

class SheetFormulaIssueCodeInfo {
  const SheetFormulaIssueCodeInfo({
    required this.code,
    required this.shortLabel,
    required this.label,
    required this.description,
  });

  final String code;
  final String shortLabel;
  final String label;
  final String description;

  String get compactLabel => '$shortLabel ($code)';
}

class SheetFormulaIssueCodeCatalog {
  const SheetFormulaIssueCodeCatalog._();

  static const _known = {
    '#CYCLE': SheetFormulaIssueCodeInfo(
      code: '#CYCLE',
      shortLabel: 'Circular',
      label: 'Circular reference',
      description: 'A formula depends on itself through one or more cells.',
    ),
    '#DIV/0': SheetFormulaIssueCodeInfo(
      code: '#DIV/0',
      shortLabel: 'Division',
      label: 'Division by zero',
      description: 'A formula divides by zero, blank, or invalid data.',
    ),
    '#VALUE': SheetFormulaIssueCodeInfo(
      code: '#VALUE',
      shortLabel: 'Value',
      label: 'Invalid value',
      description: 'A formula received a value in an unsupported shape.',
    ),
    '#REF': SheetFormulaIssueCodeInfo(
      code: '#REF',
      shortLabel: 'Reference',
      label: 'Invalid reference',
      description: 'A cell, range, or sheet reference cannot be resolved.',
    ),
    '#NUM': SheetFormulaIssueCodeInfo(
      code: '#NUM',
      shortLabel: 'Number',
      label: 'Invalid number',
      description: 'A numeric result is not finite or cannot be represented.',
    ),
    '#N/A': SheetFormulaIssueCodeInfo(
      code: '#N/A',
      shortLabel: 'Lookup',
      label: 'Not available',
      description: 'A lookup or match did not find a result.',
    ),
    '#ERROR': SheetFormulaIssueCodeInfo(
      code: '#ERROR',
      shortLabel: 'Parse',
      label: 'Formula error',
      description: 'The formula could not be parsed or evaluated.',
    ),
    '#NAME': SheetFormulaIssueCodeInfo(
      code: '#NAME',
      shortLabel: 'Name',
      label: 'Unknown name',
      description: 'A named range or formula token could not be resolved.',
    ),
  };

  static SheetFormulaIssueCodeInfo describe(String code) {
    final normalized = code.trim().isEmpty
        ? '#ERROR'
        : code.trim().toUpperCase();
    return _known[normalized] ??
        SheetFormulaIssueCodeInfo(
          code: normalized,
          shortLabel: 'Error',
          label: 'Formula error',
          description: 'The formula returned an unknown error code.',
        );
  }
}

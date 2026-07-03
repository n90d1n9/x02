import '../model/cell/cell_data.dart';

class SheetFormulaErrorStatus {
  const SheetFormulaErrorStatus({
    required this.hasError,
    required this.code,
    required this.title,
    required this.message,
    required this.suggestion,
  });

  final bool hasError;
  final String code;
  final String title;
  final String message;
  final String suggestion;

  static const none = SheetFormulaErrorStatus(
    hasError: false,
    code: '',
    title: '',
    message: '',
    suggestion: '',
  );

  String get tooltip {
    if (!hasError) return '';
    return '$title ($code). $message';
  }

  factory SheetFormulaErrorStatus.fromCell(CellData cellData) {
    final formula = cellData.formula;
    if (formula == null || formula.isEmpty || !cellData.value.startsWith('#')) {
      return SheetFormulaErrorStatus.none;
    }

    return SheetFormulaErrorStatus.fromCode(cellData.value);
  }

  factory SheetFormulaErrorStatus.fromCode(String code) {
    switch (code.trim().toUpperCase()) {
      case '#DIV/0':
        return const SheetFormulaErrorStatus(
          hasError: true,
          code: '#DIV/0',
          title: 'Division by zero',
          message: 'A formula is dividing by zero or a blank value.',
          suggestion: 'Check denominators and referenced blank cells.',
        );
      case '#VALUE':
        return const SheetFormulaErrorStatus(
          hasError: true,
          code: '#VALUE',
          title: 'Invalid value',
          message: 'A formula received a value in an unsupported shape.',
          suggestion: 'Check number, text, and range inputs.',
        );
      case '#REF':
        return const SheetFormulaErrorStatus(
          hasError: true,
          code: '#REF',
          title: 'Invalid reference',
          message: 'A referenced cell or range could not be parsed.',
          suggestion: 'Review referenced cells, ranges, and sheet links.',
        );
      case '#NUM':
        return const SheetFormulaErrorStatus(
          hasError: true,
          code: '#NUM',
          title: 'Invalid number',
          message: 'A numeric result is not finite or cannot be represented.',
          suggestion: 'Check large values, square roots, and divisions.',
        );
      case '#N/A':
        return const SheetFormulaErrorStatus(
          hasError: true,
          code: '#N/A',
          title: 'Not available',
          message: 'A lookup or match did not find a result.',
          suggestion: 'Check lookup values and source ranges.',
        );
      case '#ERROR':
        return const SheetFormulaErrorStatus(
          hasError: true,
          code: '#ERROR',
          title: 'Formula error',
          message: 'The formula could not be parsed or evaluated.',
          suggestion: 'Check formula spelling, separators, and parentheses.',
        );
      default:
        return SheetFormulaErrorStatus(
          hasError: true,
          code: code.trim().isEmpty ? '#ERROR' : code.trim().toUpperCase(),
          title: 'Formula error',
          message: 'The formula returned an unknown error code.',
          suggestion: 'Review the formula and referenced cells.',
        );
    }
  }
}

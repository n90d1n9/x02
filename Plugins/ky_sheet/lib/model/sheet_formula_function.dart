class SheetFormulaFunction {
  const SheetFormulaFunction({
    required this.name,
    required this.signature,
    required this.description,
    required this.category,
    this.aliases = const [],
    this.insertText,
  });

  final String name;
  final String signature;
  final String description;
  final String category;
  final List<String> aliases;
  final String? insertText;

  String get formulaText => '=${insertText ?? '$name()'}';

  String get suggestionText => '$name(';

  bool matches(String query) {
    final normalized = query.trim().toUpperCase();
    if (normalized.isEmpty) return true;
    return name.contains(normalized) ||
        signature.toUpperCase().contains(normalized) ||
        description.toUpperCase().contains(normalized) ||
        category.toUpperCase().contains(normalized) ||
        aliases.any((alias) => alias.toUpperCase().contains(normalized));
  }

  int rankFor(String query) {
    final normalized = query.trim().toUpperCase();
    if (normalized.isEmpty) return 0;
    if (name.startsWith(normalized)) return 0;
    if (aliases.any((alias) => alias.toUpperCase().startsWith(normalized))) {
      return 1;
    }
    if (signature.toUpperCase().contains(normalized)) return 2;
    if (description.toUpperCase().contains(normalized)) return 3;
    return 4;
  }
}

class SheetFormulaCatalog {
  const SheetFormulaCatalog._();

  static const functions = <SheetFormulaFunction>[
    SheetFormulaFunction(
      name: 'SUM',
      signature: 'SUM(number1, [number2])',
      description: 'Adds numeric values from cells or ranges.',
      category: 'Math',
    ),
    SheetFormulaFunction(
      name: 'AVERAGE',
      signature: 'AVERAGE(number1, [number2])',
      description: 'Returns the average of numeric values.',
      category: 'Math',
      aliases: ['AVG'],
    ),
    SheetFormulaFunction(
      name: 'COUNT',
      signature: 'COUNT(value1, [value2])',
      description: 'Counts numeric values.',
      category: 'Stat',
    ),
    SheetFormulaFunction(
      name: 'COUNTA',
      signature: 'COUNTA(value1, [value2])',
      description: 'Counts non-empty values.',
      category: 'Stat',
    ),
    SheetFormulaFunction(
      name: 'MIN',
      signature: 'MIN(number1, [number2])',
      description: 'Returns the smallest numeric value.',
      category: 'Stat',
    ),
    SheetFormulaFunction(
      name: 'MAX',
      signature: 'MAX(number1, [number2])',
      description: 'Returns the largest numeric value.',
      category: 'Stat',
    ),
    SheetFormulaFunction(
      name: 'IF',
      signature: 'IF(condition, value_if_true, value_if_false)',
      description:
          'Returns one value when a condition passes, another when it fails.',
      category: 'Logic',
    ),
    SheetFormulaFunction(
      name: 'SUMIF',
      signature: 'SUMIF(range, criteria, [sum_range])',
      description: 'Adds values that match a condition.',
      category: 'Math',
    ),
    SheetFormulaFunction(
      name: 'COUNTIF',
      signature: 'COUNTIF(range, criteria)',
      description: 'Counts values that match a condition.',
      category: 'Stat',
    ),
    SheetFormulaFunction(
      name: 'VLOOKUP',
      signature: 'VLOOKUP(search_key, range, index, [sorted])',
      description: 'Finds a row by key and returns a value from that row.',
      category: 'Lookup',
    ),
    SheetFormulaFunction(
      name: 'CONCAT',
      signature: 'CONCAT(value1, [value2])',
      description: 'Joins values together as text.',
      category: 'Text',
      aliases: ['CONCATENATE'],
    ),
    SheetFormulaFunction(
      name: 'LEN',
      signature: 'LEN(text)',
      description: 'Returns the number of characters in text.',
      category: 'Text',
    ),
    SheetFormulaFunction(
      name: 'UPPER',
      signature: 'UPPER(text)',
      description: 'Converts text to uppercase.',
      category: 'Text',
    ),
    SheetFormulaFunction(
      name: 'LOWER',
      signature: 'LOWER(text)',
      description: 'Converts text to lowercase.',
      category: 'Text',
    ),
    SheetFormulaFunction(
      name: 'ROUND',
      signature: 'ROUND(number, [places])',
      description: 'Rounds a number to a fixed number of places.',
      category: 'Math',
    ),
    SheetFormulaFunction(
      name: 'ABS',
      signature: 'ABS(number)',
      description: 'Returns the absolute value of a number.',
      category: 'Math',
    ),
  ];

  static SheetFormulaFunction? find(String name) {
    final normalized = name.trim().toUpperCase();
    for (final function in functions) {
      if (function.name == normalized ||
          function.aliases.any((alias) => alias.toUpperCase() == normalized)) {
        return function;
      }
    }
    return null;
  }

  static List<SheetFormulaFunction> search(String query, {int limit = 8}) {
    if (query.trim().isEmpty) {
      return functions.take(limit).toList(growable: false);
    }

    final matches = [
      for (final function in functions)
        if (function.matches(query)) function,
    ];

    matches.sort((left, right) {
      final rankComparison = left
          .rankFor(query)
          .compareTo(right.rankFor(query));
      if (rankComparison != 0) return rankComparison;
      return left.name.compareTo(right.name);
    });

    return matches.take(limit).toList(growable: false);
  }
}

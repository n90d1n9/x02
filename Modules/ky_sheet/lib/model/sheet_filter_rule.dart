import 'dart:convert';

enum SheetFilterOperator {
  contains,
  equals,
  notEquals,
  startsWith,
  endsWith,
  oneOf,
  empty,
  notEmpty,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
}

extension SheetFilterOperatorLabel on SheetFilterOperator {
  String get label {
    return switch (this) {
      SheetFilterOperator.contains => 'Contains',
      SheetFilterOperator.equals => 'Equals',
      SheetFilterOperator.notEquals => 'Does not equal',
      SheetFilterOperator.startsWith => 'Starts with',
      SheetFilterOperator.endsWith => 'Ends with',
      SheetFilterOperator.oneOf => 'Values',
      SheetFilterOperator.empty => 'Is empty',
      SheetFilterOperator.notEmpty => 'Is not empty',
      SheetFilterOperator.greaterThan => 'Greater than',
      SheetFilterOperator.greaterThanOrEqual => 'Greater than or equal',
      SheetFilterOperator.lessThan => 'Less than',
      SheetFilterOperator.lessThanOrEqual => 'Less than or equal',
    };
  }

  bool get requiresValue {
    return switch (this) {
      SheetFilterOperator.empty || SheetFilterOperator.notEmpty => false,
      _ => true,
    };
  }
}

class SheetFilterRule {
  const SheetFilterRule({
    this.operator = SheetFilterOperator.contains,
    this.value = '',
  });

  factory SheetFilterRule.contains(String value) {
    return SheetFilterRule(value: value);
  }

  factory SheetFilterRule.oneOf(Iterable<String> values) {
    final distinctValues = <String>[];
    final seenValues = <String>{};

    for (final rawValue in values) {
      final value = rawValue.trim();
      final key = value.toLowerCase();
      if (seenValues.add(key)) distinctValues.add(value);
    }

    return SheetFilterRule(
      operator: SheetFilterOperator.oneOf,
      value: jsonEncode(distinctValues),
    );
  }

  factory SheetFilterRule.fromJson(Map<String, dynamic> json) {
    final operatorName = json['operator']?.toString();
    return SheetFilterRule(
      operator: SheetFilterOperator.values.firstWhere(
        (operator) => operator.name == operatorName,
        orElse: () => SheetFilterOperator.contains,
      ),
      value: json['value']?.toString() ?? '',
    );
  }

  final SheetFilterOperator operator;
  final String value;

  List<String> get valueList {
    if (operator != SheetFilterOperator.oneOf) return const [];

    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return [
          for (final item in decoded)
            if (item != null) item.toString(),
        ];
      }
    } on FormatException {
      return value
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  bool get isActive {
    if (operator == SheetFilterOperator.oneOf) return value.trim().isNotEmpty;
    if (!operator.requiresValue) return true;
    return value.trim().isNotEmpty;
  }

  String get description {
    if (operator == SheetFilterOperator.oneOf) {
      return '${operator.label} (${valueList.length})';
    }
    if (!operator.requiresValue) return operator.label;
    return '${operator.label} "${value.trim()}"';
  }

  SheetFilterRule copyWith({SheetFilterOperator? operator, String? value}) {
    return SheetFilterRule(
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {'operator': operator.name, 'value': value};
  }
}

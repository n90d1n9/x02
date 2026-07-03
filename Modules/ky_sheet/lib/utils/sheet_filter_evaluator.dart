import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_filter_rule.dart';

class SheetFilterEvaluator {
  const SheetFilterEvaluator._();

  static bool hasActiveFilters(Map<int, String> filters) {
    return filters.values.any((value) => value.trim().isNotEmpty);
  }

  static bool hasActiveRules(Map<int, SheetFilterRule> rules) {
    return rules.values.any((rule) => rule.isActive);
  }

  static bool hasActiveRuleForColumn({
    required int column,
    required Map<int, String> filters,
    required Map<int, SheetFilterRule> filterRules,
  }) {
    return (filterRules[column]?.isActive ?? false) ||
        (filters[column]?.trim().isNotEmpty ?? false);
  }

  static Map<int, SheetFilterRule> effectiveRules({
    required Map<int, String> filters,
    required Map<int, SheetFilterRule> filterRules,
  }) {
    final activeRules = <int, SheetFilterRule>{
      for (final entry in filterRules.entries)
        if (entry.value.isActive) entry.key: entry.value,
    };

    for (final entry in filters.entries) {
      if (activeRules.containsKey(entry.key)) continue;
      final value = entry.value.trim();
      if (value.isNotEmpty) {
        activeRules[entry.key] = SheetFilterRule.contains(value);
      }
    }

    return activeRules;
  }

  static List<int> visibleRows({
    required List<int> rows,
    required Map<int, String> filters,
    Map<int, SheetFilterRule> filterRules = const {},
    required Map<CellAddress, CellData> cells,
  }) {
    final activeRules = effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );
    if (activeRules.isEmpty) return rows;

    return [
      for (final row in rows)
        if (_rowMatches(row, activeRules, cells)) row,
    ];
  }

  static bool _rowMatches(
    int row,
    Map<int, SheetFilterRule> filterRules,
    Map<CellAddress, CellData> cells,
  ) {
    for (final entry in filterRules.entries) {
      final value = cells[CellAddress(row, entry.key)]?.value ?? '';
      if (!_valueMatches(value, entry.value)) return false;
    }
    return true;
  }

  static bool _valueMatches(String rawValue, SheetFilterRule rule) {
    final value = rawValue.trim();
    final operand = rule.value.trim();
    final lowerValue = value.toLowerCase();
    final lowerOperand = operand.toLowerCase();

    return switch (rule.operator) {
      SheetFilterOperator.contains => lowerValue.contains(lowerOperand),
      SheetFilterOperator.equals => lowerValue == lowerOperand,
      SheetFilterOperator.notEquals => lowerValue != lowerOperand,
      SheetFilterOperator.startsWith => lowerValue.startsWith(lowerOperand),
      SheetFilterOperator.endsWith => lowerValue.endsWith(lowerOperand),
      SheetFilterOperator.oneOf => _matchesAnyValue(value, rule.valueList),
      SheetFilterOperator.empty => value.isEmpty,
      SheetFilterOperator.notEmpty => value.isNotEmpty,
      SheetFilterOperator.greaterThan => _compare(value, operand) > 0,
      SheetFilterOperator.greaterThanOrEqual => _compare(value, operand) >= 0,
      SheetFilterOperator.lessThan => _compare(value, operand) < 0,
      SheetFilterOperator.lessThanOrEqual => _compare(value, operand) <= 0,
    };
  }

  static bool _matchesAnyValue(String value, List<String> options) {
    final normalizedValue = value.trim().toLowerCase();
    return options.any(
      (option) => option.trim().toLowerCase() == normalizedValue,
    );
  }

  static int _compare(String value, String operand) {
    final numericValue = double.tryParse(value);
    final numericOperand = double.tryParse(operand);
    if (numericValue != null && numericOperand != null) {
      return numericValue.compareTo(numericOperand);
    }

    final dateValue = DateTime.tryParse(value);
    final dateOperand = DateTime.tryParse(operand);
    if (dateValue != null && dateOperand != null) {
      return dateValue.compareTo(dateOperand);
    }

    return value.toLowerCase().compareTo(operand.toLowerCase());
  }
}

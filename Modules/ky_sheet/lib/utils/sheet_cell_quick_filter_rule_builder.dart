import '../model/sheet_filter_rule.dart';

/// Quick filter behavior that can be applied from a selected cell value.
enum SheetCellQuickFilterMode {
  /// Keep rows where the column matches the selected cell value.
  keepOnly,

  /// Hide rows where the column matches the selected cell value.
  exclude,
}

/// Builds spreadsheet filter rules from a single cell value.
class SheetCellQuickFilterRuleBuilder {
  const SheetCellQuickFilterRuleBuilder._();

  /// Creates an equals/not-equals style filter, using blank-aware rules.
  static SheetFilterRule build({
    required String value,
    required SheetCellQuickFilterMode mode,
  }) {
    final normalizedValue = value.trim();
    final isBlank = normalizedValue.isEmpty;

    return switch (mode) {
      SheetCellQuickFilterMode.keepOnly =>
        isBlank
            ? const SheetFilterRule(operator: SheetFilterOperator.empty)
            : SheetFilterRule(
                operator: SheetFilterOperator.equals,
                value: normalizedValue,
              ),
      SheetCellQuickFilterMode.exclude =>
        isBlank
            ? const SheetFilterRule(operator: SheetFilterOperator.notEmpty)
            : SheetFilterRule(
                operator: SheetFilterOperator.notEquals,
                value: normalizedValue,
              ),
    };
  }
}

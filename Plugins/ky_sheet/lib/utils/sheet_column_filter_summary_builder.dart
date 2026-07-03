import '../model/sheet_filter_rule.dart';
import 'sheet_filter_evaluator.dart';

/// Presentation-ready summary for a single spreadsheet column filter.
class SheetColumnFilterSummary {
  const SheetColumnFilterSummary({required this.column, required this.rule});

  /// Zero-based spreadsheet column index.
  final int column;

  /// Effective active rule for the column, including legacy text filters.
  final SheetFilterRule? rule;

  /// Whether the column currently has an active filter.
  bool get hasFilter => rule?.isActive ?? false;

  /// Compact filter description for menus, badges, and status surfaces.
  String get detailLabel => hasFilter ? rule!.description : 'No active filter';
}

/// Builds filter summaries from the current legacy and rich filter maps.
class SheetColumnFilterSummaryBuilder {
  const SheetColumnFilterSummaryBuilder._();

  /// Returns the effective filter summary for [column].
  static SheetColumnFilterSummary forColumn({
    required int column,
    required Map<int, String> filters,
    required Map<int, SheetFilterRule> filterRules,
  }) {
    final effectiveRules = SheetFilterEvaluator.effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );

    return SheetColumnFilterSummary(
      column: column,
      rule: effectiveRules[column],
    );
  }
}

import '../model/sheet_filter_rule.dart';
import '../model/sheet_table.dart';
import 'sheet_filter_evaluator.dart';

/// Presentation-ready summary of active filters inside a structured table.
class SheetTableFilterSummary {
  const SheetTableFilterSummary({
    required this.table,
    required this.activeRules,
  });

  /// Structured table being summarized.
  final SheetTable table;

  /// Effective active filters keyed by spreadsheet column index.
  final Map<int, SheetFilterRule> activeRules;

  /// Columns inside the table that currently have active filters.
  Iterable<int> get activeColumns => activeRules.keys;

  /// Number of table columns with active filters.
  int get activeFilterCount => activeRules.length;

  /// Whether this table currently has one or more active filters.
  bool get hasFilters => activeRules.isNotEmpty;

  /// Compact label used by menus and table badges.
  String get detailLabel {
    final suffix = activeFilterCount == 1
        ? 'filtered column'
        : 'filtered columns';
    return hasFilters
        ? '$activeFilterCount $suffix'
        : 'No table filters active';
  }
}

/// Builds active-filter summaries scoped to structured table columns.
class SheetTableFilterSummaryBuilder {
  const SheetTableFilterSummaryBuilder._();

  /// Returns active filters whose columns intersect [table].
  static SheetTableFilterSummary forTable({
    required SheetTable table,
    required Map<int, String> filters,
    required Map<int, SheetFilterRule> filterRules,
  }) {
    final activeRules = SheetFilterEvaluator.effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );

    return SheetTableFilterSummary(
      table: table,
      activeRules: {
        for (final entry in activeRules.entries)
          if (entry.key >= table.minCol && entry.key <= table.maxCol)
            entry.key: entry.value,
      },
    );
  }
}

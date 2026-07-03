import 'sheet_column_filter_summary_builder.dart';
import 'sheet_table_calculated_column_summary_builder.dart';
import 'sheet_table_filter_impact_label_builder.dart';
import 'sheet_table_filter_summary_builder.dart';
import 'sheet_table_filter_visibility_summary_builder.dart';

/// Builds actionable tooltip copy for structured table header action buttons.
class SheetTableHeaderActionTooltipBuilder {
  const SheetTableHeaderActionTooltipBuilder._();

  /// Returns a compact status tooltip for sort, filter, and formula context.
  static String build({
    required bool isSorted,
    required bool sortAscending,
    required SheetColumnFilterSummary columnFilterSummary,
    required SheetTableFilterSummary tableFilterSummary,
    required SheetTableFilterVisibilitySummary tableFilterVisibilitySummary,
    required SheetTableCalculatedColumnSummary formulaSummary,
  }) {
    final states = [
      if (isSorted) 'sorted',
      if (columnFilterSummary.hasFilter) 'filtered',
      if (formulaSummary.hasFormulas) formulaSummary.title.toLowerCase(),
    ];
    if (states.isEmpty) return 'Table header actions';

    final details = [
      if (isSorted) 'Sort: ${sortAscending ? 'A to Z' : 'Z to A'}',
      if (columnFilterSummary.hasFilter)
        'Filter: ${columnFilterSummary.detailLabel}',
      if (tableFilterSummary.hasFilters)
        SheetTableFilterImpactLabelBuilder.build(
          filterSummary: tableFilterSummary,
          visibilitySummary: tableFilterVisibilitySummary,
        ),
      if (formulaSummary.hasFormulas) formulaSummary.detailLabel,
    ];

    return 'Table column ${states.join(', ')} · ${details.join(' · ')}';
  }
}

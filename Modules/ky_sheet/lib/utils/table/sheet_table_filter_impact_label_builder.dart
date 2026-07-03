import 'sheet_table_filter_summary_builder.dart';
import 'sheet_table_filter_visibility_summary_builder.dart';

/// Builds compact labels that describe how table filters affect visible rows.
class SheetTableFilterImpactLabelBuilder {
  const SheetTableFilterImpactLabelBuilder._();

  /// Returns a user-facing label for table filter count and row visibility.
  static String build({
    required SheetTableFilterSummary filterSummary,
    required SheetTableFilterVisibilitySummary visibilitySummary,
  }) {
    if (!filterSummary.hasFilters) return filterSummary.detailLabel;

    return '${filterSummary.detailLabel} · ${visibilitySummary.detailLabel}';
  }
}

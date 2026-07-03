import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sheet_table.dart';
import '../state/spreadsheet_provider.dart';
import '../utils/sheet_table_filter_impact_label_builder.dart';
import '../utils/sheet_table_filter_summary_builder.dart';
import '../utils/sheet_table_filter_visibility_summary_builder.dart';

/// Compact identity badge for the active structured table inside the grid.
class SheetTableCornerBadge extends ConsumerWidget {
  const SheetTableCornerBadge({
    super.key,
    required this.table,
    required this.color,
    required this.maxWidth,
  });

  /// Stable key for locating the active table identity badge in tests.
  static const badgeKey = ValueKey<String>('ky-sheet-active-table-badge');

  /// Stable key for locating the active table filter count indicator.
  static const filterBadgeKey = ValueKey<String>(
    'ky-sheet-active-table-filter-badge',
  );

  /// Table represented by the badge.
  final SheetTable table;

  /// Badge background color, typically from the table style palette.
  final Color color;

  /// Available width inside the hosting cell.
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(spreadsheetProvider);
    final filterSummary = SheetTableFilterSummaryBuilder.forTable(
      table: table,
      filters: ref.watch(filterProvider),
      filterRules: ref.watch(sheetFilterRulesProvider),
    );
    final filterVisibilitySummary =
        SheetTableFilterVisibilitySummaryBuilder.forTable(
          filterSummary: filterSummary,
          cells: cells,
        );
    final filterTooltip = SheetTableFilterImpactLabelBuilder.build(
      filterSummary: filterSummary,
      visibilitySummary: filterVisibilitySummary,
    );
    final showName = maxWidth >= 54;
    final tooltipParts = [
      table.name,
      table.selection.label,
      if (filterSummary.hasFilters) filterTooltip,
    ];

    return Tooltip(
      message: tooltipParts.join(' · '),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              key: badgeKey,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x240F172A),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  showName ? 7 : 5,
                  3,
                  filterSummary.hasFilters ? 14 : (showName ? 7 : 5),
                  3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.table_chart_outlined,
                      size: 13,
                      color: Colors.white,
                    ),
                    if (showName) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          table.name,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (filterSummary.hasFilters)
              Positioned(
                top: -4,
                right: -4,
                child: _TableFilterCountBadge(
                  count: filterSummary.activeFilterCount,
                  tooltip: filterTooltip,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tiny count chip that marks active filters on the table identity badge.
class _TableFilterCountBadge extends StatelessWidget {
  const _TableFilterCountBadge({required this.count, required this.tooltip});

  /// Number of active filters inside the table.
  final int count;

  /// Tooltip text describing the filtered table state.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';

    return Tooltip(
      message: tooltip,
      child: Container(
        key: SheetTableCornerBadge.filterBadgeKey,
        constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x330F172A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220F172A),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

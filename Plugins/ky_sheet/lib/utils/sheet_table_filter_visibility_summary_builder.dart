import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_table.dart';
import 'sheet_filter_evaluator.dart';
import 'sheet_table_filter_summary_builder.dart';

/// Presentation-ready visibility summary for filtered structured table rows.
class SheetTableFilterVisibilitySummary {
  const SheetTableFilterVisibilitySummary({
    required this.table,
    required this.totalBodyRows,
    required this.visibleBodyRows,
  });

  /// Structured table being summarized.
  final SheetTable table;

  /// Number of body rows considered by table filters.
  final int totalBodyRows;

  /// Number of body rows still visible after table filters are applied.
  final int visibleBodyRows;

  /// Number of body rows hidden by table filters.
  int get hiddenBodyRows => totalBodyRows - visibleBodyRows;

  /// Whether the table currently has at least one body row.
  bool get hasBodyRows => totalBodyRows > 0;

  /// Compact label used in ribbon and table status surfaces.
  String get detailLabel {
    if (!hasBodyRows) return 'No data rows';

    final suffix = totalBodyRows == 1 ? 'row' : 'rows';
    return '$visibleBodyRows of $totalBodyRows $suffix shown';
  }
}

/// Builds row-visibility summaries for structured table filter states.
class SheetTableFilterVisibilitySummaryBuilder {
  const SheetTableFilterVisibilitySummaryBuilder._();

  /// Returns visible body row counts after applying table-scoped filters.
  static SheetTableFilterVisibilitySummary forTable({
    required SheetTableFilterSummary filterSummary,
    required Map<CellAddress, CellData> cells,
  }) {
    final table = filterSummary.table;
    final bodyRows = _bodyRows(table);
    final visibleRows = SheetFilterEvaluator.visibleRows(
      rows: bodyRows,
      filters: const {},
      filterRules: filterSummary.activeRules,
      cells: cells,
    );

    return SheetTableFilterVisibilitySummary(
      table: table,
      totalBodyRows: bodyRows.length,
      visibleBodyRows: visibleRows.length,
    );
  }

  static List<int> _bodyRows(SheetTable table) {
    final firstBodyRow = table.showHeaderRow ? table.minRow + 1 : table.minRow;
    final lastBodyRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    if (firstBodyRow > lastBodyRow) return const [];

    return [for (var row = firstBodyRow; row <= lastBodyRow; row += 1) row];
  }
}

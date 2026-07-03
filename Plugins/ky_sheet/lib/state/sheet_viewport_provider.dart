import 'package:flutter_riverpod/legacy.dart';

final sheetViewportStatsProvider = StateProvider<SheetViewportStats>(
  (ref) => const SheetViewportStats(),
);

class SheetViewportStats {
  const SheetViewportStats({
    this.visibleRows = 0,
    this.visibleColumns = 0,
    this.renderedRows = 0,
    this.renderedColumns = 0,
    this.firstRenderedRow,
    this.lastRenderedRow,
    this.firstRenderedColumn,
    this.lastRenderedColumn,
  });

  final int visibleRows;
  final int visibleColumns;
  final int renderedRows;
  final int renderedColumns;
  final int? firstRenderedRow;
  final int? lastRenderedRow;
  final int? firstRenderedColumn;
  final int? lastRenderedColumn;

  int get visibleCells => visibleRows * visibleColumns;
  int get renderedCells => renderedRows * renderedColumns;
  int get skippedCells => (visibleCells - renderedCells).clamp(0, visibleCells);

  double get renderRatio {
    if (visibleCells == 0) return 0;
    return renderedCells / visibleCells;
  }

  String get rowWindowLabel => _windowLabel(firstRenderedRow, lastRenderedRow);

  String get columnWindowLabel =>
      _windowLabel(firstRenderedColumn, lastRenderedColumn, zeroBased: true);

  static String _windowLabel(int? first, int? last, {bool zeroBased = false}) {
    if (first == null || last == null) return '-';
    final start = zeroBased ? first + 1 : first + 1;
    final end = zeroBased ? last + 1 : last + 1;
    return '$start-$end';
  }

  @override
  bool operator ==(Object other) {
    return other is SheetViewportStats &&
        visibleRows == other.visibleRows &&
        visibleColumns == other.visibleColumns &&
        renderedRows == other.renderedRows &&
        renderedColumns == other.renderedColumns &&
        firstRenderedRow == other.firstRenderedRow &&
        lastRenderedRow == other.lastRenderedRow &&
        firstRenderedColumn == other.firstRenderedColumn &&
        lastRenderedColumn == other.lastRenderedColumn;
  }

  @override
  int get hashCode => Object.hash(
    visibleRows,
    visibleColumns,
    renderedRows,
    renderedColumns,
    firstRenderedRow,
    lastRenderedRow,
    firstRenderedColumn,
    lastRenderedColumn,
  );
}

import '../model/column_config.dart';
import '../model/row_config.dart';
import '../theme/ky_sheet_theme.dart';

class SheetViewportMetrics {
  const SheetViewportMetrics._();

  static List<int> visibleRows(int totalRows, Map<int, RowConfig> rowConfig) {
    return [
      for (var row = 0; row < totalRows; row++)
        if (!(rowConfig[row]?.hidden ?? false)) row,
    ];
  }

  static List<int> visibleColumns(
    int totalColumns,
    Map<int, ColumnConfig> columnConfig,
  ) {
    return [
      for (var col = 0; col < totalColumns; col++)
        if (!(columnConfig[col]?.hidden ?? false)) col,
    ];
  }

  static double rowHeight(int row, Map<int, RowConfig> rowConfig, double zoom) {
    final height = rowConfig[row]?.height ?? KySheetMetrics.defaultRowHeight;
    return height
            .clamp(KySheetMetrics.minRowHeight, KySheetMetrics.maxRowHeight)
            .toDouble() *
        zoom;
  }

  static double columnWidth(
    int col,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    final width = columnConfig[col]?.width ?? KySheetMetrics.defaultColumnWidth;
    return width
            .clamp(KySheetMetrics.minColumnWidth, KySheetMetrics.maxColumnWidth)
            .toDouble() *
        zoom;
  }

  static double rowOffset(
    int target,
    Map<int, RowConfig> rowConfig,
    double zoom,
  ) {
    var offset = 0.0;
    for (var row = 0; row < target; row++) {
      if (!(rowConfig[row]?.hidden ?? false)) {
        offset += rowHeight(row, rowConfig, zoom);
      }
    }
    return offset;
  }

  static double columnOffset(
    int target,
    Map<int, ColumnConfig> columnConfig,
    double zoom,
  ) {
    var offset = 0.0;
    for (var col = 0; col < target; col++) {
      if (!(columnConfig[col]?.hidden ?? false)) {
        offset += columnWidth(col, columnConfig, zoom);
      }
    }
    return offset;
  }

  static SheetViewportSlice viewportSlice({
    required List<int> indexes,
    required double scrollOffset,
    required double viewportExtent,
    required double Function(int index) extentFor,
    int leadingBuffer = 2,
    int trailingBuffer = 4,
  }) {
    if (indexes.isEmpty) return const SheetViewportSlice.empty();

    final spans = <_ViewportSpan>[];
    var cursor = 0.0;
    for (var position = 0; position < indexes.length; position++) {
      final index = indexes[position];
      final extent = extentFor(index);
      spans.add(
        _ViewportSpan(
          position: position,
          index: index,
          start: cursor,
          extent: extent,
        ),
      );
      cursor += extent;
    }

    final totalExtent = cursor;
    final safeViewportExtent = viewportExtent.isFinite
        ? viewportExtent.clamp(0, double.infinity).toDouble()
        : totalExtent;
    final safeScrollOffset = scrollOffset.clamp(0, totalExtent).toDouble();
    final visibleEnd = safeScrollOffset + safeViewportExtent;

    var firstVisible = spans.indexWhere((span) => span.end > safeScrollOffset);
    if (firstVisible == -1) firstVisible = spans.length - 1;

    var lastVisible = firstVisible;
    for (var position = firstVisible; position < spans.length; position++) {
      if (spans[position].start >= visibleEnd) break;
      lastVisible = position;
    }

    final startPosition = (firstVisible - leadingBuffer)
        .clamp(0, spans.length - 1)
        .toInt();
    final endPosition = (lastVisible + trailingBuffer)
        .clamp(startPosition, spans.length - 1)
        .toInt();
    final renderedSpans = spans.sublist(startPosition, endPosition + 1);

    return SheetViewportSlice(
      indexes: [for (final span in renderedSpans) span.index],
      leadingExtent: spans[startPosition].start,
      renderedExtent: renderedSpans.last.end - renderedSpans.first.start,
      contentExtent: totalExtent,
      firstIndex: renderedSpans.first.index,
      lastIndex: renderedSpans.last.index,
      sourceCount: indexes.length,
    );
  }
}

class SheetViewportSlice {
  const SheetViewportSlice({
    required this.indexes,
    required this.leadingExtent,
    required this.renderedExtent,
    required this.contentExtent,
    required this.firstIndex,
    required this.lastIndex,
    required this.sourceCount,
  });

  const SheetViewportSlice.empty()
    : indexes = const [],
      leadingExtent = 0,
      renderedExtent = 0,
      contentExtent = 0,
      firstIndex = null,
      lastIndex = null,
      sourceCount = 0;

  final List<int> indexes;
  final double leadingExtent;
  final double renderedExtent;
  final double contentExtent;
  final int? firstIndex;
  final int? lastIndex;
  final int sourceCount;

  double get trailingExtent => (contentExtent - leadingExtent - renderedExtent)
      .clamp(0, double.infinity);

  int get renderedCount => indexes.length;
}

class _ViewportSpan {
  const _ViewportSpan({
    required this.position,
    required this.index,
    required this.start,
    required this.extent,
  });

  final int position;
  final int index;
  final double start;
  final double extent;

  double get end => start + extent;
}

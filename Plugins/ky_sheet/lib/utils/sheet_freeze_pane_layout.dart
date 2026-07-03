import '../model/cell/cell_address.dart';

class SheetFreezePaneLayout {
  const SheetFreezePaneLayout({
    required this.frozenRows,
    required this.scrollingRows,
    required this.frozenColumns,
    required this.scrollingColumns,
  });

  factory SheetFreezePaneLayout.from({
    required CellAddress? freezePane,
    required List<int> visibleRows,
    required List<int> visibleColumns,
  }) {
    if (freezePane == null) {
      return SheetFreezePaneLayout(
        frozenRows: const [],
        scrollingRows: visibleRows,
        frozenColumns: const [],
        scrollingColumns: visibleColumns,
      );
    }

    return SheetFreezePaneLayout(
      frozenRows: [
        for (final row in visibleRows)
          if (row < freezePane.row) row,
      ],
      scrollingRows: [
        for (final row in visibleRows)
          if (row >= freezePane.row) row,
      ],
      frozenColumns: [
        for (final column in visibleColumns)
          if (column < freezePane.col) column,
      ],
      scrollingColumns: [
        for (final column in visibleColumns)
          if (column >= freezePane.col) column,
      ],
    );
  }

  final List<int> frozenRows;
  final List<int> scrollingRows;
  final List<int> frozenColumns;
  final List<int> scrollingColumns;

  bool get hasFrozenRows => frozenRows.isNotEmpty;
  bool get hasFrozenColumns => frozenColumns.isNotEmpty;
  bool get hasFrozenPanes => hasFrozenRows || hasFrozenColumns;
}

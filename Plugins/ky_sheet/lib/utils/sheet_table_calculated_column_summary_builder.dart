import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';

/// Formula consistency state for a structured table body column.
enum SheetTableCalculatedColumnState {
  /// No body formulas were found in this table column.
  none,

  /// Some, but not all, body cells in this column contain formulas.
  partial,

  /// Every body cell in this column contains a formula.
  calculated,
}

/// User-facing formula status for a structured table body column.
class SheetTableCalculatedColumnSummary {
  const SheetTableCalculatedColumnSummary({
    required this.state,
    required this.bodyCellCount,
    required this.formulaCellCount,
    required this.bodySelection,
  });

  /// Whether formulas are absent, partial, or complete across the body column.
  final SheetTableCalculatedColumnState state;

  /// Number of body cells scanned in the table column.
  final int bodyCellCount;

  /// Number of body cells that currently contain formulas.
  final int formulaCellCount;

  /// Contiguous body-column range represented by this summary.
  final CellSelection? bodySelection;

  /// Whether this column has at least one formula in the table body.
  bool get hasFormulas => formulaCellCount > 0;

  /// Whether every body row in the column contains a formula.
  bool get isCalculated => state == SheetTableCalculatedColumnState.calculated;

  /// Header menu title for the formula status.
  String get title {
    return switch (state) {
      SheetTableCalculatedColumnState.none => 'Standard Column',
      SheetTableCalculatedColumnState.partial => 'Mixed Formula Column',
      SheetTableCalculatedColumnState.calculated => 'Calculated Column',
    };
  }

  /// Compact status detail for menus and tooltips.
  String get detailLabel {
    if (bodyCellCount == 0) return 'No table body rows';
    if (!hasFormulas) return 'No body formulas';
    if (isCalculated) {
      return '$formulaCellCount formula ${_rowWord(formulaCellCount)}';
    }
    return '$formulaCellCount of $bodyCellCount body rows use formulas';
  }

  /// Tooltip text for table header formula awareness.
  String get tooltip {
    if (!hasFormulas) return 'Table header actions';
    return '$title: $detailLabel';
  }

  static String _rowWord(int count) => count == 1 ? 'row' : 'rows';
}

/// Builds calculated-column summaries for structured table headers.
class SheetTableCalculatedColumnSummaryBuilder {
  const SheetTableCalculatedColumnSummaryBuilder._();

  /// Scans a table body column and describes its formula coverage.
  static SheetTableCalculatedColumnSummary build({
    required SheetTable table,
    required int column,
    required Map<CellAddress, CellData> cells,
  }) {
    final firstBodyRow = table.showHeaderRow ? table.minRow + 1 : table.minRow;
    final lastBodyRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    if (column < table.minCol ||
        column > table.maxCol ||
        firstBodyRow > lastBodyRow) {
      return const SheetTableCalculatedColumnSummary(
        state: SheetTableCalculatedColumnState.none,
        bodyCellCount: 0,
        formulaCellCount: 0,
        bodySelection: null,
      );
    }

    var formulaCellCount = 0;
    for (var row = firstBodyRow; row <= lastBodyRow; row += 1) {
      final formula = cells[CellAddress(row, column)]?.formula?.trim();
      if (formula != null && formula.isNotEmpty) {
        formulaCellCount += 1;
      }
    }

    final bodyCellCount = lastBodyRow - firstBodyRow + 1;
    return SheetTableCalculatedColumnSummary(
      state: _stateFor(
        formulaCellCount: formulaCellCount,
        bodyCellCount: bodyCellCount,
      ),
      bodyCellCount: bodyCellCount,
      formulaCellCount: formulaCellCount,
      bodySelection: _bodySelection(
        firstBodyRow: firstBodyRow,
        lastBodyRow: lastBodyRow,
        column: column,
      ),
    );
  }

  static CellSelection _bodySelection({
    required int firstBodyRow,
    required int lastBodyRow,
    required int column,
  }) {
    final start = CellAddress(firstBodyRow, column);
    if (firstBodyRow == lastBodyRow) return CellSelection.single(start);
    return CellSelection(start, CellAddress(lastBodyRow, column));
  }

  static SheetTableCalculatedColumnState _stateFor({
    required int formulaCellCount,
    required int bodyCellCount,
  }) {
    if (formulaCellCount == 0) return SheetTableCalculatedColumnState.none;
    if (formulaCellCount == bodyCellCount) {
      return SheetTableCalculatedColumnState.calculated;
    }
    return SheetTableCalculatedColumnState.partial;
  }
}

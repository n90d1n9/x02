import 'dart:math' as math;

import 'cell/cell_address.dart';
import 'cell/cell_data.dart';
import 'cell/cell_selection.dart';
import 'cell/cell_style.dart';

class SheetFormatSnapshot {
  const SheetFormatSnapshot({
    required this.sourceLabel,
    required this.rowSpan,
    required this.columnSpan,
    required this.styles,
  });

  factory SheetFormatSnapshot.fromSelection({
    required CellSelection selection,
    required Map<CellAddress, CellData> cells,
  }) {
    final styles = <CellAddress, CellStyle>{};

    for (final address in selection.getCells()) {
      styles[CellAddress(
            address.row - selection.minRow,
            address.col - selection.minCol,
          )] =
          cells[address]?.style ?? const CellStyle();
    }

    return SheetFormatSnapshot(
      sourceLabel: selection.label,
      rowSpan: math.max(1, selection.maxRow - selection.minRow + 1),
      columnSpan: math.max(1, selection.maxCol - selection.minCol + 1),
      styles: Map.unmodifiable(styles),
    );
  }

  final String sourceLabel;
  final int rowSpan;
  final int columnSpan;
  final Map<CellAddress, CellStyle> styles;

  CellStyle styleFor(CellAddress address, CellSelection targetSelection) {
    final rowOffset = (address.row - targetSelection.minRow) % rowSpan;
    final columnOffset = (address.col - targetSelection.minCol) % columnSpan;
    return styles[CellAddress(rowOffset, columnOffset)] ?? const CellStyle();
  }
}

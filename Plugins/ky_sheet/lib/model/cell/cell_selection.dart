import 'dart:math' as math;

import 'cell_address.dart';

class CellSelection {
  final CellAddress start;
  final CellAddress? end;

  CellSelection(this.start, [this.end]);

  // Add this factory constructor
  factory CellSelection.single(CellAddress address) {
    return CellSelection(address);
  }

  bool isRange() => end != null;

  int get minRow => math.min(start.row, end?.row ?? start.row);
  int get maxRow => math.max(start.row, end?.row ?? start.row);
  int get minCol => math.min(start.col, end?.col ?? start.col);
  int get maxCol => math.max(start.col, end?.col ?? start.col);

  int get cellCount => (maxRow - minRow + 1) * (maxCol - minCol + 1);

  String get label {
    if (!isRange()) return start.label;
    return '${CellAddress(minRow, minCol).label}:${CellAddress(maxRow, maxCol).label}';
  }

  bool contains(CellAddress address) {
    return address.row >= minRow &&
        address.row <= maxRow &&
        address.col >= minCol &&
        address.col <= maxCol;
  }

  bool spansRow(int row) => row >= minRow && row <= maxRow;

  bool spansColumn(int col) => col >= minCol && col <= maxCol;

  List<CellAddress> getCells() {
    if (end == null) return [start];
    final cells = <CellAddress>[];
    for (int r = minRow; r <= maxRow; r++) {
      for (int c = minCol; c <= maxCol; c++) {
        cells.add(CellAddress(r, c));
      }
    }
    return cells;
  }
}

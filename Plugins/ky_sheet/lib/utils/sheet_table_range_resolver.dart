import 'dart:math' as math;

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';

/// Resolves ergonomic range adjustments for structured tables.
class SheetTableRangeResolver {
  const SheetTableRangeResolver._();

  /// Expands a table from its top-left anchor to occupied cells down/right.
  static CellSelection expandDownRight({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
  }) {
    var maxRow = table.maxRow;
    var maxCol = table.maxCol;

    for (final entry in cells.entries) {
      if (!_isOccupied(entry.value)) continue;
      final address = entry.key;
      if (address.row < table.minRow || address.col < table.minCol) continue;

      maxRow = math.max(maxRow, address.row);
      maxCol = math.max(maxCol, address.col);
    }

    return CellSelection(
      CellAddress(table.minRow, table.minCol),
      CellAddress(maxRow, maxCol),
    );
  }

  /// Returns the table range after appending one row below the table.
  static CellSelection appendRowBelow({required SheetTable table}) {
    return CellSelection(
      CellAddress(table.minRow, table.minCol),
      CellAddress(table.maxRow + 1, table.maxCol),
    );
  }

  /// Returns the table range after appending one column to the right.
  static CellSelection appendColumnRight({required SheetTable table}) {
    return CellSelection(
      CellAddress(table.minRow, table.minCol),
      CellAddress(table.maxRow, table.maxCol + 1),
    );
  }

  /// Returns the newly appended row selection for immediate user feedback.
  static CellSelection appendedRow({required SheetTable table}) {
    return CellSelection(
      CellAddress(table.maxRow + 1, table.minCol),
      CellAddress(table.maxRow + 1, table.maxCol),
    );
  }

  /// Returns the newly appended column selection for immediate user feedback.
  static CellSelection appendedColumn({required SheetTable table}) {
    return CellSelection(
      CellAddress(table.minRow, table.maxCol + 1),
      CellAddress(table.maxRow, table.maxCol + 1),
    );
  }

  static bool _isOccupied(CellData cell) {
    return cell.value.trim().isNotEmpty || cell.formula != null;
  }
}

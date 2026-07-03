import '../model/cell/cell_address.dart';
import '../model/sheet_table.dart';
import '../model/sheet_table_outline.dart';

/// Resolves which cell edges form the active structured-table frame.
class SheetTableOutlineResolver {
  const SheetTableOutlineResolver._();

  /// Returns outline edges for boundary cells in the active table.
  static SheetTableCellOutline? resolve({
    required CellAddress address,
    required SheetTable? activeTable,
  }) {
    if (activeTable == null || !activeTable.contains(address)) {
      return null;
    }

    final outline = SheetTableCellOutline(
      top: address.row == activeTable.minRow,
      right: address.col == activeTable.maxCol,
      bottom: address.row == activeTable.maxRow,
      left: address.col == activeTable.minCol,
    );

    return outline.hasVisibleEdge ? outline : null;
  }
}

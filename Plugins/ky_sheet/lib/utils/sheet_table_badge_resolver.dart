import '../model/cell/cell_address.dart';
import '../model/sheet_table.dart';

/// Decides where active structured-table identity affordances are shown.
class SheetTableBadgeResolver {
  const SheetTableBadgeResolver._();

  /// Returns true for the top-left cell of the active structured table.
  static bool shouldShow({
    required CellAddress address,
    required SheetTable? activeTable,
  }) {
    return activeTable != null &&
        address.row == activeTable.minRow &&
        address.col == activeTable.minCol;
  }
}

import '../model/cell/cell_address.dart';
import '../model/sheet_table.dart';

/// Decides where active structured-table corner actions are available.
class SheetTableCornerActionResolver {
  const SheetTableCornerActionResolver._();

  /// Returns true for the bottom-right cell of the active structured table.
  static bool shouldShow({
    required CellAddress address,
    required SheetTable? activeTable,
  }) {
    return activeTable != null &&
        address.row == activeTable.maxRow &&
        address.col == activeTable.maxCol;
  }
}

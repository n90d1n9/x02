import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_table.dart';

/// Validates structured table header names before committing header edits.
class SheetTableHeaderNameValidator {
  const SheetTableHeaderNameValidator._();

  /// Returns the visible header name for [column], falling back to its label.
  static String currentName({
    required SheetTable table,
    required int column,
    required Map<CellAddress, CellData> cells,
  }) {
    final headerValue = cells[CellAddress(table.minRow, column)]?.value.trim();
    if (headerValue != null && headerValue.isNotEmpty) return headerValue;
    return CellAddress.colToLabel(column);
  }

  /// Returns an error message when [value] cannot be used as a header name.
  static String? validate({
    required SheetTable table,
    required int column,
    required Map<CellAddress, CellData> cells,
    required String value,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Header name is required';

    for (
      var currentColumn = table.minCol;
      currentColumn <= table.maxCol;
      currentColumn += 1
    ) {
      if (currentColumn == column) continue;

      final existingValue = cells[CellAddress(table.minRow, currentColumn)]
          ?.value
          .trim();
      if (existingValue == null || existingValue.isEmpty) continue;

      if (existingValue.toLowerCase() == trimmed.toLowerCase()) {
        return '"$trimmed" already exists in this table';
      }
    }

    return null;
  }
}

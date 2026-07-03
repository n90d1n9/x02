import '../model/cell/cell_address.dart';
import '../model/cell/cell_selection.dart';

class SheetRangeParser {
  const SheetRangeParser._();

  static CellSelection? parseSelection(
    String input, {
    int? maxRows,
    int? maxColumns,
  }) {
    final normalized = input.trim();
    if (normalized.isEmpty) return null;

    final parts = normalized.split(':');
    if (parts.length > 2 || parts.any((part) => part.trim().isEmpty)) {
      return null;
    }

    final start = parseAddress(
      parts.first,
      maxRows: maxRows,
      maxColumns: maxColumns,
    );
    if (start == null) return null;

    if (parts.length == 1) {
      return CellSelection(start);
    }

    final end = parseAddress(
      parts.last,
      maxRows: maxRows,
      maxColumns: maxColumns,
    );
    if (end == null) return null;

    return CellSelection(start, end);
  }

  static CellAddress? parseAddress(
    String input, {
    int? maxRows,
    int? maxColumns,
  }) {
    final match = RegExp(
      r'^\$?([A-Za-z]+)\$?([1-9][0-9]*)$',
    ).firstMatch(input.trim());
    if (match == null) return null;

    final column = _columnIndex(match.group(1)!);
    final row = int.tryParse(match.group(2)!) == null
        ? null
        : int.parse(match.group(2)!) - 1;

    if (row == null || column < 0 || row < 0) return null;
    if (maxRows != null && row >= maxRows) return null;
    if (maxColumns != null && column >= maxColumns) return null;

    return CellAddress(row, column);
  }

  static int _columnIndex(String label) {
    var value = 0;
    for (final codeUnit in label.toUpperCase().codeUnits) {
      if (codeUnit < 65 || codeUnit > 90) return -1;
      value = (value * 26) + (codeUnit - 64);
    }
    return value - 1;
  }
}

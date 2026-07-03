import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';

/// Builds stable checklist values for spreadsheet column filter dialogs.
class SheetColumnFilterValueBuilder {
  const SheetColumnFilterValueBuilder._();

  /// Returns sorted, distinct, non-empty display values from [column].
  static List<String> build({
    required int column,
    required Map<CellAddress, CellData> cells,
    Iterable<int>? rows,
  }) {
    final allowedRows = rows?.toSet();
    final values = <String>{};

    for (final entry in cells.entries) {
      if (entry.key.col != column) continue;
      if (allowedRows != null && !allowedRows.contains(entry.key.row)) {
        continue;
      }

      final value = entry.value.value.trim();
      if (value.isNotEmpty) values.add(value);
    }

    final sortedValues = values.toList();
    sortedValues.sort((a, b) {
      final lowerComparison = a.toLowerCase().compareTo(b.toLowerCase());
      return lowerComparison == 0 ? a.compareTo(b) : lowerComparison;
    });
    return sortedValues;
  }
}

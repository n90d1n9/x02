import 'package:flutter_riverpod/legacy.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';

/// Active-sheet structured table metadata.
final sheetTablesProvider =
    StateNotifierProvider<SheetTableNotifier, List<SheetTable>>(
      (ref) => SheetTableNotifier(),
    );

/// Manages structured table ranges for the active worksheet.
class SheetTableNotifier extends StateNotifier<List<SheetTable>> {
  SheetTableNotifier() : super(const []);

  var _nextTableNumber = 1;

  /// Creates a table from a selected range and returns the new metadata.
  SheetTable createFromSelection(
    CellSelection selection, {
    SheetTableStyleId? styleId,
  }) {
    final tableNumber = _nextTableNumber++;
    final table = SheetTable.fromSelection(
      id: 'table-$tableNumber-${DateTime.now().microsecondsSinceEpoch}',
      name: _uniqueName('Table$tableNumber'),
      selection: selection,
      styleId:
          styleId ??
          SheetTableStyleId.values[(tableNumber - 1) %
              SheetTableStyleId.values.length],
    );

    state = [...state, table];
    return table;
  }

  /// Replaces all active-sheet tables, usually while loading a sheet.
  void replaceAll(List<SheetTable> tables) {
    state = List<SheetTable>.from(tables);
    _nextTableNumber = _nextNumberAfter(tables);
  }

  /// Renames a table while preserving unique names in the active sheet.
  void rename(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    state = [
      for (final table in state)
        if (table.id == id)
          table.copyWith(name: _uniqueName(trimmed, excludingId: id))
        else
          table,
    ];
  }

  /// Applies a visual style family to a table.
  void setStyle(String id, SheetTableStyleId styleId) {
    state = [
      for (final table in state)
        if (table.id == id) table.copyWith(styleId: styleId) else table,
    ];
  }

  /// Updates the cell range covered by a table.
  void setSelection(String id, CellSelection selection) {
    final normalized = CellSelection(
      CellAddress(selection.minRow, selection.minCol),
      CellAddress(selection.maxRow, selection.maxCol),
    );
    state = [
      for (final table in state)
        if (table.id == id) table.copyWith(selection: normalized) else table,
    ];
  }

  /// Toggles whether a table displays its first row as a header.
  void setHeaderRowVisible(String id, bool visible) {
    state = [
      for (final table in state)
        if (table.id == id) table.copyWith(showHeaderRow: visible) else table,
    ];
  }

  /// Toggles subtle alternating row styling for a table body.
  void setBandedRowsVisible(String id, bool visible) {
    state = [
      for (final table in state)
        if (table.id == id) table.copyWith(showBandedRows: visible) else table,
    ];
  }

  /// Toggles whether a table treats its last row as a totals row.
  void setTotalsRowVisible(String id, bool visible) {
    state = [
      for (final table in state)
        if (table.id == id) table.copyWith(showTotalsRow: visible) else table,
    ];
  }

  /// Removes a table while leaving the underlying cell values untouched.
  void remove(String id) {
    state = [
      for (final table in state)
        if (table.id != id) table,
    ];
  }

  /// Clears all active-sheet table metadata.
  void clear() {
    state = const [];
    _nextTableNumber = 1;
  }

  String _uniqueName(String baseName, {String? excludingId}) {
    final names = {
      for (final table in state)
        if (table.id != excludingId) table.name.toLowerCase(),
    };
    if (!names.contains(baseName.toLowerCase())) return baseName;

    var suffix = 2;
    while (names.contains('$baseName $suffix'.toLowerCase())) {
      suffix += 1;
    }
    return '$baseName $suffix';
  }

  int _nextNumberAfter(List<SheetTable> tables) {
    var highest = 0;
    for (final table in tables) {
      final match = RegExp(r'^Table(\d+)').firstMatch(table.name);
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number > highest) highest = number;
    }
    return highest + 1;
  }
}

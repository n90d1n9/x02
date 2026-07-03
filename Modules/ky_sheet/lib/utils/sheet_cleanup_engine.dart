import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_cleanup.dart';

class SheetCleanupEngine {
  const SheetCleanupEngine._();

  static SheetCleanupPlan buildPlan({
    required SheetCleanupOperation operation,
    required CellSelection selection,
    required Map<CellAddress, CellData> cells,
  }) {
    if (operation == SheetCleanupOperation.clearDuplicateRows) {
      return _duplicateRowsPlan(selection: selection, cells: cells);
    }

    return _textPlan(operation: operation, selection: selection, cells: cells);
  }

  static SheetCleanupPlan _textPlan({
    required SheetCleanupOperation operation,
    required CellSelection selection,
    required Map<CellAddress, CellData> cells,
  }) {
    final replacements = <CellAddress, CellData?>{};
    var scannedCellCount = 0;

    for (final address in selection.getCells()) {
      scannedCellCount++;
      final cell = cells[address];
      if (cell == null || cell.formula != null) continue;

      final nextValue = _transformText(operation, cell.value);
      if (nextValue == cell.value) continue;

      replacements[address] = cell.copyWith(value: nextValue);
    }

    return SheetCleanupPlan(
      operation: operation,
      selection: selection,
      replacements: replacements,
      scannedCellCount: scannedCellCount,
      changedCellCount: replacements.length,
      affectedRowCount: _affectedRows(replacements.keys),
    );
  }

  static SheetCleanupPlan _duplicateRowsPlan({
    required CellSelection selection,
    required Map<CellAddress, CellData> cells,
  }) {
    final replacements = <CellAddress, CellData?>{};
    final seen = <String>{};
    var duplicateRows = 0;

    for (var row = selection.minRow; row <= selection.maxRow; row++) {
      final signature = _rowSignature(row, selection, cells);
      if (signature.isEmpty) continue;

      if (seen.add(signature)) continue;

      duplicateRows++;
      for (var col = selection.minCol; col <= selection.maxCol; col++) {
        final address = CellAddress(row, col);
        if (cells.containsKey(address)) {
          replacements[address] = null;
        }
      }
    }

    return SheetCleanupPlan(
      operation: SheetCleanupOperation.clearDuplicateRows,
      selection: selection,
      replacements: replacements,
      scannedCellCount: selection.cellCount,
      changedCellCount: replacements.length,
      affectedRowCount: duplicateRows,
    );
  }

  static String _transformText(SheetCleanupOperation operation, String value) {
    return switch (operation) {
      SheetCleanupOperation.trimWhitespace => value.trim(),
      SheetCleanupOperation.normalizeWhitespace => value.trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      ),
      SheetCleanupOperation.uppercase => value.toUpperCase(),
      SheetCleanupOperation.lowercase => value.toLowerCase(),
      SheetCleanupOperation.titleCase => _titleCase(value),
      SheetCleanupOperation.clearDuplicateRows => value,
    };
  }

  static String _titleCase(String value) {
    final lower = value.toLowerCase();
    return lower.replaceAllMapped(RegExp(r'[a-z0-9]+'), (match) {
      final word = match.group(0)!;
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    });
  }

  static String _rowSignature(
    int row,
    CellSelection selection,
    Map<CellAddress, CellData> cells,
  ) {
    final values = <String>[];
    var hasValue = false;

    for (var col = selection.minCol; col <= selection.maxCol; col++) {
      final value = cells[CellAddress(row, col)]?.value.trim() ?? '';
      if (value.isNotEmpty) hasValue = true;
      values.add(value);
    }

    return hasValue ? values.join('\u{001F}') : '';
  }

  static int _affectedRows(Iterable<CellAddress> addresses) {
    return addresses.map((address) => address.row).toSet().length;
  }
}

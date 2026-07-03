import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_function.dart';

class SheetFunctionInsertBuilder {
  const SheetFunctionInsertBuilder._();

  static const _adjacentRangeFunctions = {
    'SUM',
    'AVERAGE',
    'COUNT',
    'COUNTA',
    'MIN',
    'MAX',
  };

  static String buildFormula({
    required String functionName,
    required CellAddress target,
    required Map<CellAddress, CellData> cells,
  }) {
    final function = SheetFormulaCatalog.find(functionName);
    final normalizedName = function?.name ?? functionName.trim().toUpperCase();

    if (_adjacentRangeFunctions.contains(normalizedName)) {
      final inferredRange = _inferAdjacentRange(target: target, cells: cells);
      if (inferredRange != null) {
        return '=$normalizedName(${inferredRange.label})';
      }
    }

    return function?.formulaText ?? '=$normalizedName()';
  }

  static CellSelection? _inferAdjacentRange({
    required CellAddress target,
    required Map<CellAddress, CellData> cells,
  }) {
    return _scanUp(target: target, cells: cells) ??
        _scanLeft(target: target, cells: cells);
  }

  static CellSelection? _scanUp({
    required CellAddress target,
    required Map<CellAddress, CellData> cells,
  }) {
    if (target.row == 0) return null;

    final addresses = <CellAddress>[];
    for (var row = target.row - 1; row >= 0; row--) {
      final address = CellAddress(row, target.col);
      if (!_hasContent(cells[address])) break;
      addresses.add(address);
    }

    if (addresses.isEmpty) return null;
    return CellSelection(addresses.last, addresses.first);
  }

  static CellSelection? _scanLeft({
    required CellAddress target,
    required Map<CellAddress, CellData> cells,
  }) {
    if (target.col == 0) return null;

    final addresses = <CellAddress>[];
    for (var col = target.col - 1; col >= 0; col--) {
      final address = CellAddress(target.row, col);
      if (!_hasContent(cells[address])) break;
      addresses.add(address);
    }

    if (addresses.isEmpty) return null;
    return CellSelection(addresses.last, addresses.first);
  }

  static bool _hasContent(CellData? cell) {
    return cell != null &&
        (cell.value.trim().isNotEmpty ||
            (cell.formula?.trim().isNotEmpty ?? false));
  }
}

import '../model/cell/cell_address.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../model/sheet_table_total.dart';

/// Builds formulas and ranges for structured table totals-row cells.
class SheetTableTotalFormulaBuilder {
  const SheetTableTotalFormulaBuilder._();

  /// Returns the data-body range for a table column, excluding header/totals.
  static CellSelection? bodyRangeForColumn({
    required SheetTable table,
    required int column,
  }) {
    if (column < table.minCol || column > table.maxCol) return null;

    final firstBodyRow = table.showHeaderRow ? table.minRow + 1 : table.minRow;
    final lastBodyRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    if (firstBodyRow > lastBodyRow) return null;

    return CellSelection(
      CellAddress(firstBodyRow, column),
      CellAddress(lastBodyRow, column),
    );
  }

  /// Returns an aggregate formula for the table column, when data exists.
  static String? buildFormula({
    required SheetTable table,
    required int column,
    required SheetTableTotalFunction function,
  }) {
    final bodyRange = bodyRangeForColumn(table: table, column: column);
    if (bodyRange == null) return null;

    return '=${function.formulaName}(${bodyRange.label})';
  }
}

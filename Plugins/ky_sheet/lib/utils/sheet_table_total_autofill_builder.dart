import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../model/sheet_table_total.dart';
import 'sheet_table_total_formula_builder.dart';
import 'sheet_table_total_label_builder.dart';
import 'sheet_table_total_suggestion_builder.dart';

/// Builds one-shot updates for filling an entire structured table totals row.
class SheetTableTotalAutofillBuilder {
  const SheetTableTotalAutofillBuilder._();

  /// Returns a safe append plan for creating a fresh totals row below a table.
  static SheetTableTotalAppendPlan buildAppendPlan({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
    SheetTableTotalLabelPreset labelPreset = SheetTableTotalLabelPreset.total,
  }) {
    final appendedSelection = CellSelection(
      CellAddress(table.minRow, table.minCol),
      CellAddress(table.maxRow + 1, table.maxCol),
    );
    final totalsRowSelection = CellSelection(
      CellAddress(table.maxRow + 1, table.minCol),
      CellAddress(table.maxRow + 1, table.maxCol),
    );
    final blockedCells = [
      for (final address in totalsRowSelection.getCells())
        if (_isOccupied(cells[address])) address,
    ];
    if (blockedCells.isNotEmpty) {
      return SheetTableTotalAppendPlan(
        tableSelection: appendedSelection,
        totalsRowSelection: totalsRowSelection,
        cells: const {},
        blockedCells: blockedCells,
      );
    }

    final tableWithTotalsRow = table.copyWith(
      selection: appendedSelection,
      showTotalsRow: true,
    );

    return SheetTableTotalAppendPlan(
      tableSelection: appendedSelection,
      totalsRowSelection: totalsRowSelection,
      cells: buildCells(
        table: tableWithTotalsRow,
        cells: cells,
        labelPreset: labelPreset,
      ),
      blockedCells: const [],
    );
  }

  /// Returns cell updates for a totals-row label and suggested column formulas.
  static Map<CellAddress, CellData> buildCells({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
    SheetTableTotalLabelPreset labelPreset = SheetTableTotalLabelPreset.total,
  }) {
    if (!table.hasTotalsRow) return const {};

    final updates = <CellAddress, CellData>{};
    for (var column = table.minCol; column <= table.maxCol; column++) {
      final address = CellAddress(table.maxRow, column);
      final current = cells[address] ?? CellData();

      if (column == table.minCol) {
        final label = SheetTableTotalLabelBuilder.buildLabel(
          table: table,
          column: column,
          preset: labelPreset,
        );
        if (label != null) {
          updates[address] = current.copyWith(value: label, clearFormula: true);
        }
        continue;
      }

      final suggestion = SheetTableTotalSuggestionBuilder.suggest(
        table: table,
        column: column,
        cells: cells,
      );
      if (suggestion == null) continue;

      final formula = SheetTableTotalFormulaBuilder.buildFormula(
        table: table,
        column: column,
        function: suggestion.function,
      );
      if (formula == null) continue;

      updates[address] = current.copyWith(value: '', formula: formula);
    }

    return updates;
  }

  static bool _isOccupied(CellData? cell) {
    if (cell == null) return false;
    return cell.value.trim().isNotEmpty || cell.formula != null;
  }
}

/// Safe plan for appending and filling a structured table totals row.
class SheetTableTotalAppendPlan {
  const SheetTableTotalAppendPlan({
    required this.tableSelection,
    required this.totalsRowSelection,
    required this.cells,
    required this.blockedCells,
  });

  /// Updated table range that includes the appended totals row.
  final CellSelection tableSelection;

  /// Selection covering only the appended totals row.
  final CellSelection totalsRowSelection;

  /// Cell updates to apply when the target row is clear.
  final Map<CellAddress, CellData> cells;

  /// Occupied cells that would be overwritten by an appended totals row.
  final List<CellAddress> blockedCells;

  /// Whether this plan can be applied without overwriting existing data.
  bool get canApply => blockedCells.isEmpty && cells.isNotEmpty;

  /// Short menu label explaining why the append action is unavailable.
  String get blockedLabel {
    if (blockedCells.isEmpty) return '';
    return blockedCells.length == 1
        ? '${blockedCells.single.label} has data'
        : '${blockedCells.length} cells below have data';
  }
}

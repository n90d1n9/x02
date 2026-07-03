import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../model/sheet_table_total.dart';
import 'sheet_table_cell_template_builder.dart';
import 'sheet_table_total_formula_builder.dart';

/// Builds safe column-append plans for structured tables.
class SheetTableColumnAppendBuilder {
  const SheetTableColumnAppendBuilder._();

  /// Returns the table range and selected column for appending a column.
  ///
  /// When [smartFill] is false, only structural cells like generated headers
  /// are written; formulas, totals, and formatting templates are skipped.
  static SheetTableColumnAppendPlan build({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
    bool smartFill = true,
  }) {
    final columnSelection = CellSelection(
      CellAddress(table.minRow, table.maxCol + 1),
      CellAddress(table.maxRow, table.maxCol + 1),
    );
    final blockedCells = [
      for (final address in columnSelection.getCells())
        if (_isOccupied(cells[address])) address,
    ];
    final replacements = blockedCells.isEmpty
        ? _buildReplacements(table: table, cells: cells, smartFill: smartFill)
        : <CellAddress, CellData?>{};

    return SheetTableColumnAppendPlan(
      tableSelection: CellSelection(
        CellAddress(table.minRow, table.minCol),
        CellAddress(table.maxRow, table.maxCol + 1),
      ),
      columnSelection: columnSelection,
      blockedCells: blockedCells,
      replacements: replacements,
    );
  }

  static Map<CellAddress, CellData?> _buildReplacements({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
    required bool smartFill,
  }) {
    final replacements = <CellAddress, CellData?>{};

    if (table.showHeaderRow) {
      final headerAddress = CellAddress(table.minRow, table.maxCol + 1);
      replacements[headerAddress] = CellData(
        value: _nextHeaderLabel(table: table, cells: cells),
      );
    }

    if (smartFill) {
      final totalsCell = _buildTotalsCell(table: table, cells: cells);
      if (totalsCell != null) {
        replacements[totalsCell.key] = totalsCell.value;
      }
      _addInheritedColumnTemplates(replacements, table: table, cells: cells);
    }

    return replacements;
  }

  static String _nextHeaderLabel({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
  }) {
    final usedLabels = <String>{};
    for (var column = table.minCol; column <= table.maxCol; column += 1) {
      final label = cells[CellAddress(table.minRow, column)]?.value.trim();
      if (label != null && label.isNotEmpty) {
        usedLabels.add(label.toLowerCase());
      }
    }

    var ordinal = table.maxCol - table.minCol + 2;
    var candidate = 'Column $ordinal';
    while (usedLabels.contains(candidate.toLowerCase())) {
      ordinal += 1;
      candidate = 'Column $ordinal';
    }
    return candidate;
  }

  static MapEntry<CellAddress, CellData?>? _buildTotalsCell({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
  }) {
    if (!table.hasTotalsRow) return null;

    final function = _adjacentTotalsFunction(table: table, cells: cells);
    if (function == null) return null;

    final nextTable = table.copyWith(
      selection: CellSelection(
        CellAddress(table.minRow, table.minCol),
        CellAddress(table.maxRow, table.maxCol + 1),
      ),
    );
    final formula = SheetTableTotalFormulaBuilder.buildFormula(
      table: nextTable,
      column: table.maxCol + 1,
      function: function,
    );
    if (formula == null) return null;

    final address = CellAddress(table.maxRow, table.maxCol + 1);
    final current = cells[address] ?? CellData();
    return MapEntry(address, current.copyWith(value: '', formula: formula));
  }

  static void _addInheritedColumnTemplates(
    Map<CellAddress, CellData?> replacements, {
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
  }) {
    for (var row = table.minRow; row <= table.maxRow; row += 1) {
      final sourceAddress = CellAddress(row, table.maxCol);
      final source = cells[sourceAddress];
      if (source == null || !_hasColumnTemplate(table, row, source)) {
        continue;
      }

      final targetAddress = CellAddress(row, table.maxCol + 1);
      replacements[targetAddress] = _isBodyRow(table, row)
          ? SheetTableCellTemplateBuilder.inheritMetadataAndFormula(
              source: source,
              sourceAddress: sourceAddress,
              targetAddress: targetAddress,
              current: replacements[targetAddress],
            )
          : SheetTableCellTemplateBuilder.inheritMetadata(
              source: source,
              current: replacements[targetAddress],
            );
    }
  }

  static bool _hasColumnTemplate(SheetTable table, int row, CellData cell) {
    if (_isBodyRow(table, row)) {
      return SheetTableCellTemplateBuilder.hasRowTemplate(cell);
    }

    return SheetTableCellTemplateBuilder.hasTemplateMetadata(cell);
  }

  static bool _isBodyRow(SheetTable table, int row) {
    final firstBodyRow = table.showHeaderRow ? table.minRow + 1 : table.minRow;
    final lastBodyRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    return row >= firstBodyRow && row <= lastBodyRow;
  }

  static SheetTableTotalFunction? _adjacentTotalsFunction({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
  }) {
    final sourceFormula = cells[CellAddress(table.maxRow, table.maxCol)]
        ?.formula
        ?.trim()
        .toUpperCase();
    if (sourceFormula == null || sourceFormula.isEmpty) return null;

    for (final function in SheetTableTotalFunction.values) {
      final expectedFormula = SheetTableTotalFormulaBuilder.buildFormula(
        table: table,
        column: table.maxCol,
        function: function,
      )?.toUpperCase();
      if (sourceFormula == expectedFormula) return function;
    }

    return null;
  }

  static bool _isOccupied(CellData? cell) {
    if (cell == null) return false;
    return cell.value.trim().isNotEmpty || cell.formula != null;
  }
}

/// Planned result of appending a column to a structured table.
class SheetTableColumnAppendPlan {
  const SheetTableColumnAppendPlan({
    required this.tableSelection,
    required this.columnSelection,
    required this.blockedCells,
    required this.replacements,
  });

  /// Updated table range after the column append.
  final CellSelection tableSelection;

  /// Column selected after applying the append operation.
  final CellSelection columnSelection;

  /// Occupied destination cells that prevent appending a blank column.
  final List<CellAddress> blockedCells;

  /// Cell updates that should be applied with the column append.
  final Map<CellAddress, CellData?> replacements;

  /// Whether the append can be applied without absorbing existing cells.
  bool get canApply => blockedCells.isEmpty;

  /// Short menu label explaining why the append action is unavailable.
  String get blockedLabel {
    if (blockedCells.isEmpty) return '';
    return blockedCells.length == 1
        ? '${blockedCells.single.label} has data'
        : '${blockedCells.length} cells to the right have data';
  }
}

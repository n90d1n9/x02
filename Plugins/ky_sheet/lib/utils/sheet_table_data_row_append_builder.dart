import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import 'sheet_table_cell_template_builder.dart';
import 'sheet_table_total_autofill_builder.dart';

/// Builds safe row-append plans for structured tables with optional totals rows.
class SheetTableDataRowAppendBuilder {
  const SheetTableDataRowAppendBuilder._();

  /// Returns the table range, selected row, and cell updates for adding a row.
  ///
  /// When [smartFill] is false, row formulas and reusable formatting are not
  /// copied into the new data row, while totals rows are still preserved.
  static SheetTableDataRowAppendPlan build({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
    bool smartFill = true,
  }) {
    final rowSelection = CellSelection(
      CellAddress(table.maxRow + 1, table.minCol),
      CellAddress(table.maxRow + 1, table.maxCol),
    );
    final tableSelection = CellSelection(
      CellAddress(table.minRow, table.minCol),
      CellAddress(table.maxRow + 1, table.maxCol),
    );
    final blockedCells = _occupiedCells(rowSelection, cells);

    if (!table.hasTotalsRow) {
      if (blockedCells.isNotEmpty) {
        return SheetTableDataRowAppendPlan(
          tableSelection: tableSelection,
          rowSelection: rowSelection,
          replacements: const {},
          blockedCells: blockedCells,
          preservesTotalsRow: false,
        );
      }

      final replacements = smartFill
          ? _buildInheritedRowMetadata(
              table: table,
              cells: cells,
              sourceRow: table.maxRow,
              targetRow: table.maxRow + 1,
            )
          : <CellAddress, CellData>{};

      return SheetTableDataRowAppendPlan(
        tableSelection: tableSelection,
        rowSelection: rowSelection,
        replacements: replacements,
        blockedCells: const [],
        preservesTotalsRow: false,
      );
    }

    if (blockedCells.isNotEmpty) {
      return SheetTableDataRowAppendPlan(
        tableSelection: tableSelection,
        rowSelection: CellSelection(
          CellAddress(table.maxRow, table.minCol),
          CellAddress(table.maxRow, table.maxCol),
        ),
        replacements: const {},
        blockedCells: blockedCells,
        preservesTotalsRow: true,
      );
    }

    final draftCells = Map<CellAddress, CellData>.from(cells);
    final oldTotalsRowSelection = CellSelection(
      CellAddress(table.maxRow, table.minCol),
      CellAddress(table.maxRow, table.maxCol),
    );
    for (final address in oldTotalsRowSelection.getCells()) {
      draftCells.remove(address);
    }

    final nextTable = table.copyWith(selection: tableSelection);
    final inheritedRowMetadata = smartFill
        ? _buildInheritedRowMetadata(
            table: table,
            cells: cells,
            sourceRow: table.maxRow - 1,
            targetRow: table.maxRow,
          )
        : <CellAddress, CellData>{};
    for (final entry in inheritedRowMetadata.entries) {
      draftCells[entry.key] = entry.value;
    }

    final totalsCells = SheetTableTotalAutofillBuilder.buildCells(
      table: nextTable,
      cells: draftCells,
    );

    return SheetTableDataRowAppendPlan(
      tableSelection: tableSelection,
      rowSelection: oldTotalsRowSelection,
      replacements: {
        for (final address in oldTotalsRowSelection.getCells()) address: null,
        for (final entry in inheritedRowMetadata.entries)
          entry.key: entry.value,
        for (final entry in totalsCells.entries) entry.key: entry.value,
      },
      blockedCells: const [],
      preservesTotalsRow: true,
    );
  }

  static bool _isOccupied(CellData? cell) {
    if (cell == null) return false;
    return cell.value.trim().isNotEmpty || cell.formula != null;
  }

  static List<CellAddress> _occupiedCells(
    CellSelection selection,
    Map<CellAddress, CellData> cells,
  ) {
    return [
      for (final address in selection.getCells())
        if (_isOccupied(cells[address])) address,
    ];
  }

  static Map<CellAddress, CellData> _buildInheritedRowMetadata({
    required SheetTable table,
    required Map<CellAddress, CellData> cells,
    required int sourceRow,
    required int targetRow,
  }) {
    if (sourceRow < _firstBodyRow(table)) return const {};

    final replacements = <CellAddress, CellData>{};
    for (var column = table.minCol; column <= table.maxCol; column += 1) {
      final sourceAddress = CellAddress(sourceRow, column);
      final source = cells[sourceAddress];
      if (source == null ||
          !SheetTableCellTemplateBuilder.hasRowTemplate(source)) {
        continue;
      }

      final targetAddress = CellAddress(targetRow, column);
      replacements[targetAddress] =
          SheetTableCellTemplateBuilder.inheritMetadataAndFormula(
            source: source,
            sourceAddress: sourceAddress,
            targetAddress: targetAddress,
          );
    }
    return replacements;
  }

  static int _firstBodyRow(SheetTable table) {
    return table.showHeaderRow ? table.minRow + 1 : table.minRow;
  }
}

/// Planned result of appending a data row to a structured table.
class SheetTableDataRowAppendPlan {
  const SheetTableDataRowAppendPlan({
    required this.tableSelection,
    required this.rowSelection,
    required this.replacements,
    required this.blockedCells,
    required this.preservesTotalsRow,
  });

  /// Updated table range after the row append.
  final CellSelection tableSelection;

  /// Row selected after applying the append operation.
  final CellSelection rowSelection;

  /// Cell replacements needed to keep totals rows at the bottom.
  final Map<CellAddress, CellData?> replacements;

  /// Occupied destination cells that prevent moving a totals row down.
  final List<CellAddress> blockedCells;

  /// Whether this plan keeps an existing totals row as the final table row.
  final bool preservesTotalsRow;

  /// Whether the append can be applied without overwriting existing cells.
  bool get canApply => blockedCells.isEmpty;

  /// Menu label for the primary row append action.
  String get actionLabel =>
      preservesTotalsRow ? 'Add Data Row' : 'Add Row Below';

  /// Short menu label explaining why the append action is unavailable.
  String get blockedLabel {
    if (blockedCells.isEmpty) return '';
    return blockedCells.length == 1
        ? '${blockedCells.single.label} has data'
        : '${blockedCells.length} cells below have data';
  }
}

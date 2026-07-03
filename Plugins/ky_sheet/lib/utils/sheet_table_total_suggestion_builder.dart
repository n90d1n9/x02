import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_table.dart';
import '../model/sheet_table_total.dart';
import 'sheet_table_total_formula_builder.dart';

/// Suggested aggregate action for a structured table totals-row column.
class SheetTableTotalSuggestion {
  const SheetTableTotalSuggestion({
    required this.function,
    required this.filledCells,
    required this.numericCells,
  });

  /// Aggregate function best suited to the column's visible body values.
  final SheetTableTotalFunction function;

  /// Number of non-empty body cells used to choose the suggestion.
  final int filledCells;

  /// Number of filled body cells that parse as numeric values.
  final int numericCells;

  /// User-facing menu label for the suggested totals-row action.
  String get label => 'Suggested: ${function.label}';
}

/// Infers a sensible totals-row function from table body column values.
class SheetTableTotalSuggestionBuilder {
  const SheetTableTotalSuggestionBuilder._();

  /// Returns the most useful aggregate function for a table body column.
  static SheetTableTotalSuggestion? suggest({
    required SheetTable table,
    required int column,
    required Map<CellAddress, CellData> cells,
  }) {
    final bodyRange = SheetTableTotalFormulaBuilder.bodyRangeForColumn(
      table: table,
      column: column,
    );
    if (bodyRange == null) return null;

    var filledCells = 0;
    var numericCells = 0;

    for (final address in bodyRange.getCells()) {
      final cell = cells[address];
      final rawValue = cell?.value.trim() ?? '';
      final hasFormula = cell?.formula?.isNotEmpty ?? false;
      if (rawValue.isEmpty && !hasFormula) continue;

      filledCells++;
      if (double.tryParse(rawValue) != null) numericCells++;
    }

    if (filledCells == 0) return null;

    final numericShare = numericCells / filledCells;
    final function = numericShare >= 0.6
        ? SheetTableTotalFunction.sum
        : SheetTableTotalFunction.countA;

    return SheetTableTotalSuggestion(
      function: function,
      filledCells: filledCells,
      numericCells: numericCells,
    );
  }
}

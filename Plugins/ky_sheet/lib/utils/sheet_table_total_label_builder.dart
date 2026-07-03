import '../model/sheet_table.dart';
import '../model/sheet_table_total.dart';

/// Builds text labels for the leading cell of structured table totals rows.
class SheetTableTotalLabelBuilder {
  const SheetTableTotalLabelBuilder._();

  /// Returns whether the column is the preferred totals-row label position.
  static bool isPreferredLabelColumn({
    required SheetTable table,
    required int column,
  }) {
    return table.hasTotalsRow && column == table.minCol;
  }

  /// Returns label presets suitable for the provided totals-row column.
  static List<SheetTableTotalLabelPreset> presetsForColumn({
    required SheetTable table,
    required int column,
  }) {
    if (!isPreferredLabelColumn(table: table, column: column)) {
      return const [];
    }
    return SheetTableTotalLabelPreset.values;
  }

  /// Returns the text label represented by a totals-row label preset.
  static String? buildLabel({
    required SheetTable table,
    required int column,
    required SheetTableTotalLabelPreset preset,
  }) {
    if (!isPreferredLabelColumn(table: table, column: column)) return null;
    return preset.label;
  }
}

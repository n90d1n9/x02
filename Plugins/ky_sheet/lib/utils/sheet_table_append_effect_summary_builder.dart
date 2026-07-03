import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_table.dart';
import 'sheet_table_cell_template_builder.dart';
import 'sheet_table_column_append_builder.dart';
import 'sheet_table_data_row_append_builder.dart';

/// Smart behaviors applied when a structured table grows.
enum SheetTableAppendEffectKind {
  /// Creates a unique header for a newly appended table column.
  generatedHeader,

  /// Copies and shifts reusable calculated formulas into the new range.
  formulaFill,

  /// Carries formatting or validation metadata into the new range.
  formatting,

  /// Preserves or extends totals behavior after the append.
  totalsRow,
}

/// Human-readable append effects shown in table quick actions.
class SheetTableAppendEffectSummary {
  const SheetTableAppendEffectSummary({
    required this.effects,
    required this.fallbackLabel,
    this.blockedDetailLabel,
  });

  /// Ordered list of smart behaviors applied by the append plan.
  final List<SheetTableAppendEffectKind> effects;

  /// Menu detail used when no smart behavior is needed.
  final String fallbackLabel;

  /// Menu detail used when an append is blocked by occupied cells.
  final String? blockedDetailLabel;

  /// Whether the append action is unavailable.
  bool get isBlocked => blockedDetailLabel?.isNotEmpty ?? false;

  /// Whether the append action applies any smart-fill behavior.
  bool get hasSmartFill => effects.isNotEmpty;

  /// Compact secondary text for table append menu actions.
  String get detailLabel {
    if (isBlocked) return blockedDetailLabel!;
    if (effects.isEmpty) return fallbackLabel;
    return 'Smart fill: ${_joinLabels(effects.map(_labelFor))}';
  }

  static String _joinLabels(Iterable<String> labels) {
    final items = labels.toList(growable: false);
    if (items.isEmpty) return '';
    if (items.length == 1) return items.single;
    if (items.length == 2) return '${items.first} and ${items.last}';
    return '${items.take(items.length - 1).join(', ')} and ${items.last}';
  }

  static String _labelFor(SheetTableAppendEffectKind effect) {
    return switch (effect) {
      SheetTableAppendEffectKind.generatedHeader => 'header',
      SheetTableAppendEffectKind.formulaFill => 'formulas',
      SheetTableAppendEffectKind.formatting => 'formatting',
      SheetTableAppendEffectKind.totalsRow => 'totals',
    };
  }
}

/// Builds user-facing summaries for safe table row and column append plans.
class SheetTableAppendEffectSummaryBuilder {
  const SheetTableAppendEffectSummaryBuilder._();

  /// Summarizes the smart-fill effects applied when a table data row is added.
  static SheetTableAppendEffectSummary forDataRow({
    required SheetTableDataRowAppendPlan plan,
  }) {
    if (!plan.canApply) {
      return const SheetTableAppendEffectSummary(
        effects: [],
        fallbackLabel: 'Expands the table range',
        blockedDetailLabel: 'Choose a clear row below first',
      );
    }

    final dataRowCells = _replacementCellsInRow(
      plan.replacements,
      plan.rowSelection.minRow,
    );
    final effects = <SheetTableAppendEffectKind>[];

    if (dataRowCells.any(_hasFormula)) {
      effects.add(SheetTableAppendEffectKind.formulaFill);
    }
    if (dataRowCells.any(SheetTableCellTemplateBuilder.hasTemplateMetadata)) {
      effects.add(SheetTableAppendEffectKind.formatting);
    }
    if (plan.preservesTotalsRow) {
      effects.add(SheetTableAppendEffectKind.totalsRow);
    }

    return SheetTableAppendEffectSummary(
      effects: effects,
      fallbackLabel: 'Expands the table range',
    );
  }

  /// Summarizes the smart-fill effects applied when a table column is added.
  static SheetTableAppendEffectSummary forColumn({
    required SheetTable table,
    required SheetTableColumnAppendPlan plan,
  }) {
    if (!plan.canApply) {
      return const SheetTableAppendEffectSummary(
        effects: [],
        fallbackLabel: 'Expands the table range',
        blockedDetailLabel: 'Choose clear cells to the right first',
      );
    }

    final effects = <SheetTableAppendEffectKind>[];
    final column = plan.columnSelection.minCol;

    if (_hasGeneratedHeader(table, column, plan.replacements)) {
      effects.add(SheetTableAppendEffectKind.generatedHeader);
    }
    if (_replacementCellsInColumn(plan.replacements, column)
        .where((entry) => _isBodyRow(table, entry.key.row))
        .map((entry) => entry.value)
        .any(_hasFormula)) {
      effects.add(SheetTableAppendEffectKind.formulaFill);
    }
    if (_replacementCellsInColumn(plan.replacements, column)
        .map((entry) => entry.value)
        .any(SheetTableCellTemplateBuilder.hasTemplateMetadata)) {
      effects.add(SheetTableAppendEffectKind.formatting);
    }
    if (_hasTotalsFormula(table, column, plan.replacements)) {
      effects.add(SheetTableAppendEffectKind.totalsRow);
    }

    return SheetTableAppendEffectSummary(
      effects: effects,
      fallbackLabel: 'Expands the table range',
    );
  }

  static bool _hasFormula(CellData cell) {
    return cell.formula?.trim().isNotEmpty ?? false;
  }

  static bool _hasGeneratedHeader(
    SheetTable table,
    int column,
    Map<CellAddress, CellData?> replacements,
  ) {
    if (!table.showHeaderRow) return false;
    final header = replacements[CellAddress(table.minRow, column)];
    return header != null && header.value.trim().isNotEmpty;
  }

  static bool _hasTotalsFormula(
    SheetTable table,
    int column,
    Map<CellAddress, CellData?> replacements,
  ) {
    if (!table.hasTotalsRow) return false;
    final totalsCell = replacements[CellAddress(table.maxRow, column)];
    return totalsCell != null && _hasFormula(totalsCell);
  }

  static bool _isBodyRow(SheetTable table, int row) {
    final firstBodyRow = table.showHeaderRow ? table.minRow + 1 : table.minRow;
    final lastBodyRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    return row >= firstBodyRow && row <= lastBodyRow;
  }

  static Iterable<CellData> _replacementCellsInRow(
    Map<CellAddress, CellData?> replacements,
    int row,
  ) sync* {
    for (final entry in replacements.entries) {
      final cell = entry.value;
      if (entry.key.row == row && cell != null) yield cell;
    }
  }

  static Iterable<MapEntry<CellAddress, CellData>> _replacementCellsInColumn(
    Map<CellAddress, CellData?> replacements,
    int column,
  ) sync* {
    for (final entry in replacements.entries) {
      final cell = entry.value;
      if (entry.key.col == column && cell != null) {
        yield MapEntry(entry.key, cell);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../model/sheet_table_total.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_table_total_formula_builder.dart';
import '../utils/sheet_table_total_label_builder.dart';
import '../utils/sheet_table_total_suggestion_builder.dart';

enum _SheetTableTotalAction { clear }

/// Compact menu button for applying formulas to structured table totals cells.
class SheetTableTotalActionButton extends ConsumerWidget {
  const SheetTableTotalActionButton({
    super.key,
    required this.table,
    required this.column,
  });

  /// Table that owns the totals row.
  final SheetTable table;

  /// Column receiving the selected aggregate formula.
  final int column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(spreadsheetProvider);
    final canBuildFormula =
        SheetTableTotalFormulaBuilder.bodyRangeForColumn(
          table: table,
          column: column,
        ) !=
        null;
    final suggestion = SheetTableTotalSuggestionBuilder.suggest(
      table: table,
      column: column,
      cells: cells,
    );
    final labelPresets = SheetTableTotalLabelBuilder.presetsForColumn(
      table: table,
      column: column,
    );
    final hasLabelPresets = labelPresets.isNotEmpty;

    return Tooltip(
      key: ValueKey('ky-sheet-table-total-action-${table.id}-$column'),
      message: hasLabelPresets
          ? 'Totals row labels and formulas'
          : 'Totals row formulas',
      child: Builder(
        builder: (context) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerUp: (_) => _showMenu(
              context,
              ref,
              canBuildFormula: canBuildFormula,
              suggestion: suggestion,
              labelPresets: labelPresets,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: KySheetColors.gridLineStrong),
              ),
              child: SizedBox.square(
                dimension: 20,
                child: Icon(
                  hasLabelPresets ? Icons.summarize_outlined : Icons.functions,
                  size: 14,
                  color: KySheetColors.mutedText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref, {
    required bool canBuildFormula,
    required SheetTableTotalSuggestion? suggestion,
    required List<SheetTableTotalLabelPreset> labelPresets,
  }) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final overlayBox =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final rect = Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      renderBox.size.width,
      renderBox.size.height,
    );

    final action = await showMenu<Object>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlayBox.size),
      constraints: const BoxConstraints(minWidth: 188),
      items: [
        for (final preset in labelPresets)
          PopupMenuItem<Object>(
            key: ValueKey(
              'ky-sheet-table-total-label-${preset.name}-${table.id}-$column',
            ),
            value: preset,
            child: _TotalActionLabel(
              icon: _labelIconFor(preset),
              label: preset.label,
            ),
          ),
        if (labelPresets.isNotEmpty) const PopupMenuDivider(),
        if (suggestion != null)
          PopupMenuItem<Object>(
            key: ValueKey('ky-sheet-table-total-suggested-${table.id}-$column'),
            value: suggestion.function,
            child: _TotalActionLabel(
              icon: Icons.auto_awesome_outlined,
              label: suggestion.label,
            ),
          ),
        if (suggestion != null) const PopupMenuDivider(),
        for (final function in SheetTableTotalFunction.values)
          PopupMenuItem<Object>(
            key: ValueKey(
              'ky-sheet-table-total-${function.name}-${table.id}-$column',
            ),
            value: function,
            enabled: canBuildFormula,
            child: _TotalActionLabel(
              icon: _iconFor(function),
              label: function.label,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<Object>(
          key: ValueKey('ky-sheet-table-total-clear-${table.id}-$column'),
          value: _SheetTableTotalAction.clear,
          child: const _TotalActionLabel(
            icon: Icons.close,
            label: 'Clear Total',
          ),
        ),
      ],
    );
    if (action == null || !context.mounted) return;
    _handleAction(ref, action);
  }

  void _handleAction(WidgetRef ref, Object action) {
    final address = CellAddress(table.maxRow, column);
    if (action == _SheetTableTotalAction.clear) {
      ref.read(spreadsheetProvider.notifier).updateCellValue(address, '');
      ref.read(selectedCellProvider.notifier).state = CellSelection(address);
      return;
    }

    if (action is SheetTableTotalLabelPreset) {
      final label = SheetTableTotalLabelBuilder.buildLabel(
        table: table,
        column: column,
        preset: action,
      );
      if (label == null) return;
      ref.read(spreadsheetProvider.notifier).updateCellValue(address, label);
      ref.read(selectedCellProvider.notifier).state = CellSelection(address);
      return;
    }

    if (action is! SheetTableTotalFunction) return;
    final formula = SheetTableTotalFormulaBuilder.buildFormula(
      table: table,
      column: column,
      function: action,
    );
    if (formula == null) return;

    ref.read(spreadsheetProvider.notifier).updateCellValue(address, formula);
    ref.read(selectedCellProvider.notifier).state = CellSelection(address);
  }

  IconData _iconFor(SheetTableTotalFunction function) {
    return switch (function) {
      SheetTableTotalFunction.sum => Icons.add,
      SheetTableTotalFunction.average => Icons.percent,
      SheetTableTotalFunction.count ||
      SheetTableTotalFunction.countA => Icons.pin_outlined,
      SheetTableTotalFunction.min => Icons.keyboard_arrow_down,
      SheetTableTotalFunction.max => Icons.keyboard_arrow_up,
    };
  }

  IconData _labelIconFor(SheetTableTotalLabelPreset preset) {
    return switch (preset) {
      SheetTableTotalLabelPreset.total => Icons.label_outline,
      SheetTableTotalLabelPreset.grandTotal => Icons.summarize_outlined,
      SheetTableTotalLabelPreset.subtotal => Icons.receipt_long_outlined,
      SheetTableTotalLabelPreset.summary => Icons.notes_outlined,
    };
  }
}

class _TotalActionLabel extends StatelessWidget {
  const _TotalActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: KySheetColors.mutedText, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

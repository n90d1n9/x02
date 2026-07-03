import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/sheet_table_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_table_append_effect_summary_builder.dart';
import '../utils/sheet_table_column_append_builder.dart';
import '../utils/sheet_table_data_row_append_builder.dart';
import '../utils/sheet_table_filter_impact_label_builder.dart';
import '../utils/sheet_table_filter_summary_builder.dart';
import '../utils/sheet_table_filter_visibility_summary_builder.dart';
import '../utils/sheet_table_range_resolver.dart';
import '../utils/sheet_table_total_autofill_builder.dart';

enum _SheetTableCornerAction {
  selectTable,
  clearTableFilters,
  addRowBelow,
  addBlankRowBelow,
  addColumnRight,
  addBlankColumnRight,
  expandToData,
  toggleTotalsRow,
  addTotalsRowBelow,
  fillSuggestedTotals,
  tableStudio,
}

/// Compact active-table corner menu for quick range and studio actions.
class SheetTableCornerActionButton extends ConsumerWidget {
  const SheetTableCornerActionButton({
    super.key,
    required this.table,
    required this.color,
  });

  /// Active table represented by this corner action.
  final SheetTable table;

  /// Accent color borrowed from the table style palette.
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(spreadsheetProvider);
    final filters = ref.watch(filterProvider);
    final filterRules = ref.watch(sheetFilterRulesProvider);
    final filterSummary = SheetTableFilterSummaryBuilder.forTable(
      table: table,
      filters: filters,
      filterRules: filterRules,
    );
    final filterVisibilitySummary =
        SheetTableFilterVisibilitySummaryBuilder.forTable(
          filterSummary: filterSummary,
          cells: cells,
        );
    final expandedSelection = SheetTableRangeResolver.expandDownRight(
      table: table,
      cells: cells,
    );
    final dataRowAppendPlan = SheetTableDataRowAppendBuilder.build(
      table: table,
      cells: cells,
    );
    final blankDataRowAppendPlan = SheetTableDataRowAppendBuilder.build(
      table: table,
      cells: cells,
      smartFill: false,
    );
    final columnAppendPlan = SheetTableColumnAppendBuilder.build(
      table: table,
      cells: cells,
    );
    final blankColumnAppendPlan = SheetTableColumnAppendBuilder.build(
      table: table,
      cells: cells,
      smartFill: false,
    );
    final dataRowAppendSummary =
        SheetTableAppendEffectSummaryBuilder.forDataRow(
          plan: dataRowAppendPlan,
        );
    final columnAppendSummary = SheetTableAppendEffectSummaryBuilder.forColumn(
      table: table,
      plan: columnAppendPlan,
    );
    final suggestedTotalCells = SheetTableTotalAutofillBuilder.buildCells(
      table: table,
      cells: cells,
    );
    final appendTotalsPlan = SheetTableTotalAutofillBuilder.buildAppendPlan(
      table: table,
      cells: cells,
    );
    final canExpand = expandedSelection.label != table.selection.label;

    return Tooltip(
      key: ValueKey('ky-sheet-table-corner-action-${table.id}'),
      message: 'Table quick actions',
      child: Builder(
        builder: (context) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerUp: (_) => _showMenu(
              context,
              ref,
              canExpand: canExpand,
              expandedSelection: expandedSelection,
              filterSummary: filterSummary,
              filterVisibilitySummary: filterVisibilitySummary,
              dataRowAppendPlan: dataRowAppendPlan,
              blankDataRowAppendPlan: blankDataRowAppendPlan,
              dataRowAppendSummary: dataRowAppendSummary,
              columnAppendPlan: columnAppendPlan,
              blankColumnAppendPlan: blankColumnAppendPlan,
              columnAppendSummary: columnAppendSummary,
              suggestedTotalCells: suggestedTotalCells,
              appendTotalsPlan: appendTotalsPlan,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white, width: 1.4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x260F172A),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const SizedBox.square(
                dimension: 18,
                child: Icon(Icons.unfold_more, size: 13, color: Colors.white),
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
    required bool canExpand,
    required CellSelection expandedSelection,
    required SheetTableFilterSummary filterSummary,
    required SheetTableFilterVisibilitySummary filterVisibilitySummary,
    required SheetTableDataRowAppendPlan dataRowAppendPlan,
    required SheetTableDataRowAppendPlan blankDataRowAppendPlan,
    required SheetTableAppendEffectSummary dataRowAppendSummary,
    required SheetTableColumnAppendPlan columnAppendPlan,
    required SheetTableColumnAppendPlan blankColumnAppendPlan,
    required SheetTableAppendEffectSummary columnAppendSummary,
    required Map<CellAddress, CellData> suggestedTotalCells,
    required SheetTableTotalAppendPlan appendTotalsPlan,
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

    final action = await showMenu<_SheetTableCornerAction>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlayBox.size),
      constraints: const BoxConstraints(minWidth: 252),
      items: [
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-select-${table.id}'),
          value: _SheetTableCornerAction.selectTable,
          child: const _CornerActionLabel(
            icon: Icons.select_all,
            label: 'Select Table',
          ),
        ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-clear-filters-${table.id}'),
          value: _SheetTableCornerAction.clearTableFilters,
          enabled: filterSummary.hasFilters,
          child: _CornerActionLabel(
            icon: Icons.filter_alt_off_outlined,
            label: 'Clear Table Filters',
            detail: SheetTableFilterImpactLabelBuilder.build(
              filterSummary: filterSummary,
              visibilitySummary: filterVisibilitySummary,
            ),
          ),
        ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-add-row-${table.id}'),
          value: _SheetTableCornerAction.addRowBelow,
          enabled: dataRowAppendPlan.canApply,
          child: _CornerActionLabel(
            icon: dataRowAppendPlan.canApply ? Icons.add : Icons.block_outlined,
            label: dataRowAppendPlan.canApply
                ? dataRowAppendPlan.actionLabel
                : 'Cannot Add Row: ${dataRowAppendPlan.blockedLabel}',
            detail: dataRowAppendSummary.detailLabel,
          ),
        ),
        if (_hasBlankDataRowAlternative(dataRowAppendSummary))
          PopupMenuItem(
            key: ValueKey('ky-sheet-table-corner-add-blank-row-${table.id}'),
            value: _SheetTableCornerAction.addBlankRowBelow,
            enabled: blankDataRowAppendPlan.canApply,
            child: _CornerActionLabel(
              icon: Icons.add_circle_outline,
              label: blankDataRowAppendPlan.preservesTotalsRow
                  ? 'Add Blank Data Row'
                  : 'Add Blank Row Below',
              detail: _blankDataRowDetail(blankDataRowAppendPlan),
            ),
          ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-add-column-${table.id}'),
          value: _SheetTableCornerAction.addColumnRight,
          enabled: columnAppendPlan.canApply,
          child: _CornerActionLabel(
            icon: columnAppendPlan.canApply
                ? Icons.add_box_outlined
                : Icons.block_outlined,
            label: columnAppendPlan.canApply
                ? 'Add Column Right'
                : 'Cannot Add Column: ${columnAppendPlan.blockedLabel}',
            detail: columnAppendSummary.detailLabel,
          ),
        ),
        if (_hasBlankColumnAlternative(columnAppendSummary))
          PopupMenuItem(
            key: ValueKey('ky-sheet-table-corner-add-blank-column-${table.id}'),
            value: _SheetTableCornerAction.addBlankColumnRight,
            enabled: blankColumnAppendPlan.canApply,
            child: _CornerActionLabel(
              icon: Icons.add_circle_outline,
              label: 'Add Blank Column Right',
              detail: _blankColumnDetail(table),
            ),
          ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-expand-${table.id}'),
          value: _SheetTableCornerAction.expandToData,
          enabled: canExpand,
          child: const _CornerActionLabel(
            icon: Icons.open_in_full,
            label: 'Expand to Data',
          ),
        ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-totals-${table.id}'),
          value: _SheetTableCornerAction.toggleTotalsRow,
          child: _CornerActionLabel(
            icon: Icons.functions,
            label: table.showTotalsRow
                ? 'Hide Totals Row'
                : 'Use Last Row as Totals',
          ),
        ),
        if (!table.showTotalsRow)
          PopupMenuItem(
            key: ValueKey('ky-sheet-table-corner-add-totals-row-${table.id}'),
            value: _SheetTableCornerAction.addTotalsRowBelow,
            enabled: appendTotalsPlan.canApply,
            child: _CornerActionLabel(
              icon: appendTotalsPlan.canApply
                  ? Icons.add_chart_outlined
                  : Icons.block_outlined,
              label: appendTotalsPlan.canApply
                  ? 'Add Totals Row Below'
                  : 'Cannot Add Totals Row: ${appendTotalsPlan.blockedLabel}',
            ),
          ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-autofill-totals-${table.id}'),
          value: _SheetTableCornerAction.fillSuggestedTotals,
          enabled: suggestedTotalCells.isNotEmpty,
          child: const _CornerActionLabel(
            icon: Icons.auto_awesome_outlined,
            label: 'Auto-fill Totals',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-corner-studio-${table.id}'),
          value: _SheetTableCornerAction.tableStudio,
          child: const _CornerActionLabel(
            icon: Icons.table_chart_outlined,
            label: 'Table Studio',
          ),
        ),
      ],
    );
    if (action == null || !context.mounted) return;
    _handleAction(
      ref,
      action,
      expandedSelection: expandedSelection,
      filterSummary: filterSummary,
      dataRowAppendPlan: dataRowAppendPlan,
      blankDataRowAppendPlan: blankDataRowAppendPlan,
      columnAppendPlan: columnAppendPlan,
      blankColumnAppendPlan: blankColumnAppendPlan,
      suggestedTotalCells: suggestedTotalCells,
      appendTotalsPlan: appendTotalsPlan,
    );
  }

  void _handleAction(
    WidgetRef ref,
    _SheetTableCornerAction action, {
    required CellSelection expandedSelection,
    required SheetTableFilterSummary filterSummary,
    required SheetTableDataRowAppendPlan dataRowAppendPlan,
    required SheetTableDataRowAppendPlan blankDataRowAppendPlan,
    required SheetTableColumnAppendPlan columnAppendPlan,
    required SheetTableColumnAppendPlan blankColumnAppendPlan,
    required Map<CellAddress, CellData> suggestedTotalCells,
    required SheetTableTotalAppendPlan appendTotalsPlan,
  }) {
    switch (action) {
      case _SheetTableCornerAction.selectTable:
        ref.read(selectedCellProvider.notifier).state = table.selection;
        return;
      case _SheetTableCornerAction.clearTableFilters:
        if (!filterSummary.hasFilters) return;
        ref
            .read(toolbarControllerProvider)
            .clearFilterColumns(filterSummary.activeColumns);
        ref.read(selectedCellProvider.notifier).state = table.selection;
        return;
      case _SheetTableCornerAction.addRowBelow:
        _applyDataRowAppend(
          ref,
          dataRowAppendPlan,
          description: 'Add data row',
        );
        return;
      case _SheetTableCornerAction.addBlankRowBelow:
        _applyDataRowAppend(
          ref,
          blankDataRowAppendPlan,
          description: 'Add blank data row',
        );
        return;
      case _SheetTableCornerAction.addColumnRight:
        _applyColumnAppend(
          ref,
          columnAppendPlan,
          description: 'Add table column',
        );
        return;
      case _SheetTableCornerAction.addBlankColumnRight:
        _applyColumnAppend(
          ref,
          blankColumnAppendPlan,
          description: 'Add blank table column',
        );
        return;
      case _SheetTableCornerAction.expandToData:
        ref
            .read(sheetTablesProvider.notifier)
            .setSelection(table.id, expandedSelection);
        ref.read(selectedCellProvider.notifier).state = expandedSelection;
        return;
      case _SheetTableCornerAction.toggleTotalsRow:
        ref
            .read(sheetTablesProvider.notifier)
            .setTotalsRowVisible(table.id, !table.showTotalsRow);
        ref.read(selectedCellProvider.notifier).state = table.showTotalsRow
            ? table.selection
            : CellSelection(
                CellAddress(table.maxRow, table.minCol),
                CellAddress(table.maxRow, table.maxCol),
              );
        return;
      case _SheetTableCornerAction.addTotalsRowBelow:
        if (!appendTotalsPlan.canApply) return;
        ref
            .read(sheetTablesProvider.notifier)
            .setSelection(table.id, appendTotalsPlan.tableSelection);
        ref
            .read(sheetTablesProvider.notifier)
            .setTotalsRowVisible(table.id, true);
        _replaceTotalsCells(
          ref,
          appendTotalsPlan.cells,
          description: 'Add totals row',
        );
        ref.read(selectedCellProvider.notifier).state =
            appendTotalsPlan.totalsRowSelection;
        return;
      case _SheetTableCornerAction.fillSuggestedTotals:
        if (suggestedTotalCells.isEmpty) return;
        _replaceTotalsCells(
          ref,
          suggestedTotalCells,
          description: 'Auto-fill totals row',
        );
        ref.read(selectedCellProvider.notifier).state = CellSelection(
          CellAddress(table.maxRow, table.minCol),
          CellAddress(table.maxRow, table.maxCol),
        );
        return;
      case _SheetTableCornerAction.tableStudio:
        ref.read(activeSidebarPanelProvider.notifier).state =
            SheetSidebarPanel.tables;
        return;
    }
  }

  void _applyDataRowAppend(
    WidgetRef ref,
    SheetTableDataRowAppendPlan plan, {
    required String description,
  }) {
    if (!plan.canApply) return;
    ref
        .read(sheetTablesProvider.notifier)
        .setSelection(table.id, plan.tableSelection);
    if (plan.replacements.isNotEmpty) {
      _replaceCells(ref, plan.replacements, description: description);
    }
    ref.read(selectedCellProvider.notifier).state = plan.rowSelection;
  }

  void _applyColumnAppend(
    WidgetRef ref,
    SheetTableColumnAppendPlan plan, {
    required String description,
  }) {
    if (!plan.canApply) return;
    ref
        .read(sheetTablesProvider.notifier)
        .setSelection(table.id, plan.tableSelection);
    if (plan.replacements.isNotEmpty) {
      _replaceCells(ref, plan.replacements, description: description);
    }
    ref.read(selectedCellProvider.notifier).state = plan.columnSelection;
  }

  void _replaceTotalsCells(
    WidgetRef ref,
    Map<CellAddress, CellData> cells, {
    required String description,
  }) {
    final replacements = <CellAddress, CellData?>{
      for (final entry in cells.entries) entry.key: entry.value,
    };
    _replaceCells(ref, replacements, description: description);
  }

  void _replaceCells(
    WidgetRef ref,
    Map<CellAddress, CellData?> cells, {
    required String description,
  }) {
    ref
        .read(spreadsheetProvider.notifier)
        .replaceCells(cells, description: description);
  }

  bool _hasBlankDataRowAlternative(SheetTableAppendEffectSummary summary) {
    return summary.effects.contains(SheetTableAppendEffectKind.formulaFill) ||
        summary.effects.contains(SheetTableAppendEffectKind.formatting);
  }

  bool _hasBlankColumnAlternative(SheetTableAppendEffectSummary summary) {
    return summary.effects.any(
      (effect) => effect != SheetTableAppendEffectKind.generatedHeader,
    );
  }

  String _blankDataRowDetail(SheetTableDataRowAppendPlan plan) {
    if (plan.preservesTotalsRow) {
      return 'Moves totals down; leaves row cells empty';
    }
    return 'Expands table; leaves row cells empty';
  }

  String _blankColumnDetail(SheetTable table) {
    final prefix = table.showHeaderRow ? 'Header only' : 'Empty cells';
    if (table.hasTotalsRow) {
      return '$prefix; no formulas or totals copied';
    }
    return '$prefix; no formulas or formatting copied';
  }
}

/// Menu row layout for active structured table corner actions.
class _CornerActionLabel extends StatelessWidget {
  const _CornerActionLabel({
    required this.icon,
    required this.label,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final detailText = detail?.trim();
    final hasDetail = detailText != null && detailText.isNotEmpty;

    return Row(
      crossAxisAlignment: hasDetail
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: hasDetail ? 2 : 0),
          child: Icon(icon, color: KySheetColors.mutedText, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (hasDetail) ...[
                const SizedBox(height: 2),
                Text(
                  detailText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

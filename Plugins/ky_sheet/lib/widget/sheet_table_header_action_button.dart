import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_filter_rule.dart';
import '../model/sheet_table.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_column_filter_summary_builder.dart';
import '../utils/sheet_column_filter_value_builder.dart';
import '../utils/sheet_filter_evaluator.dart';
import '../utils/sheet_table_calculated_column_summary_builder.dart';
import '../utils/sheet_table_filter_impact_label_builder.dart';
import '../utils/sheet_table_filter_summary_builder.dart';
import '../utils/sheet_table_filter_visibility_summary_builder.dart';
import '../utils/sheet_table_header_action_tooltip_builder.dart';
import '../utils/sheet_table_header_name_validator.dart';
import 'sheet_column_filter_dialog.dart';
import 'sheet_table_header_rename_dialog.dart';

enum _SheetTableHeaderAction {
  renameHeader,
  selectColumnBody,
  sortAscending,
  sortDescending,
  clearSort,
  filterColumn,
  clearFilter,
  clearTableFilters,
  tableStudio,
}

/// Compact menu button for actions attached to a structured table header cell.
class SheetTableHeaderActionButton extends ConsumerWidget {
  const SheetTableHeaderActionButton({
    super.key,
    required this.table,
    required this.column,
  });

  final SheetTable table;
  final int column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(spreadsheetProvider);
    final filters = ref.watch(filterProvider);
    final filterRules = ref.watch(sheetFilterRulesProvider);
    final sortColumn = ref.watch(sortColumnProvider);
    final sortAscending = ref.watch(sortAscendingProvider);
    final filterSummary = SheetColumnFilterSummaryBuilder.forColumn(
      column: column,
      filters: filters,
      filterRules: filterRules,
    );
    final tableFilterSummary = SheetTableFilterSummaryBuilder.forTable(
      table: table,
      filters: filters,
      filterRules: filterRules,
    );
    final tableFilterVisibilitySummary =
        SheetTableFilterVisibilitySummaryBuilder.forTable(
          filterSummary: tableFilterSummary,
          cells: cells,
        );
    final hasFilter = filterSummary.hasFilter;
    final isSorted = sortColumn == column;
    final formulaSummary = SheetTableCalculatedColumnSummaryBuilder.build(
      table: table,
      column: column,
      cells: cells,
    );
    final headerName = SheetTableHeaderNameValidator.currentName(
      table: table,
      column: column,
      cells: cells,
    );
    final hasFormulaStatus = formulaSummary.hasFormulas;
    final foregroundColor = hasFilter || isSorted
        ? KySheetColors.accent
        : hasFormulaStatus
        ? KySheetColors.formula
        : Colors.white;

    return Tooltip(
      key: ValueKey('ky-sheet-table-header-action-${table.id}-$column'),
      message: SheetTableHeaderActionTooltipBuilder.build(
        isSorted: isSorted,
        sortAscending: sortAscending,
        columnFilterSummary: filterSummary,
        tableFilterSummary: tableFilterSummary,
        tableFilterVisibilitySummary: tableFilterVisibilitySummary,
        formulaSummary: formulaSummary,
      ),
      child: Builder(
        builder: (context) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerUp: (_) => _showMenu(
              context,
              ref,
              filterSummary: filterSummary,
              tableFilterSummary: tableFilterSummary,
              tableFilterVisibilitySummary: tableFilterVisibilitySummary,
              isSorted: isSorted,
              sortAscending: sortAscending,
              headerName: headerName,
              formulaSummary: formulaSummary,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: SizedBox.square(
                dimension: 20,
                child: Icon(
                  _iconFor(
                    hasFilter: hasFilter,
                    isSorted: isSorted,
                    sortAscending: sortAscending,
                    hasFormulaStatus: hasFormulaStatus,
                  ),
                  size: 15,
                  color: foregroundColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor({
    required bool hasFilter,
    required bool isSorted,
    required bool sortAscending,
    required bool hasFormulaStatus,
  }) {
    if (isSorted) {
      return sortAscending ? Icons.arrow_upward : Icons.arrow_downward;
    }
    if (hasFilter) return Icons.filter_alt;
    if (hasFormulaStatus) return Icons.functions;
    return Icons.keyboard_arrow_down;
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref, {
    required SheetColumnFilterSummary filterSummary,
    required SheetTableFilterSummary tableFilterSummary,
    required SheetTableFilterVisibilitySummary tableFilterVisibilitySummary,
    required bool isSorted,
    required bool sortAscending,
    required String headerName,
    required SheetTableCalculatedColumnSummary formulaSummary,
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

    final action = await showMenu<_SheetTableHeaderAction>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlayBox.size),
      constraints: const BoxConstraints(minWidth: 226),
      items: [
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-header-rename-${table.id}-$column'),
          value: _SheetTableHeaderAction.renameHeader,
          child: _HeaderActionLabel(
            icon: Icons.drive_file_rename_outline,
            label: 'Rename Header',
            detail: headerName,
          ),
        ),
        if (formulaSummary.hasFormulas)
          PopupMenuItem(
            key: ValueKey(
              'ky-sheet-table-header-calculated-${table.id}-$column',
            ),
            enabled: false,
            child: _HeaderActionLabel(
              icon: Icons.functions,
              label: formulaSummary.title,
              detail: formulaSummary.detailLabel,
            ),
          ),
        if (formulaSummary.hasFormulas)
          PopupMenuItem(
            key: ValueKey(
              'ky-sheet-table-header-select-body-${table.id}-$column',
            ),
            value: _SheetTableHeaderAction.selectColumnBody,
            child: const _HeaderActionLabel(
              icon: Icons.view_column_outlined,
              label: 'Select Column Body',
              detail: 'Review this table body range',
            ),
          ),
        if (formulaSummary.hasFormulas) const PopupMenuDivider(),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-header-sort-asc-${table.id}-$column'),
          value: _SheetTableHeaderAction.sortAscending,
          child: const _HeaderActionLabel(
            icon: Icons.arrow_upward,
            label: 'Sort A to Z',
          ),
        ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-header-sort-desc-${table.id}-$column'),
          value: _SheetTableHeaderAction.sortDescending,
          child: const _HeaderActionLabel(
            icon: Icons.arrow_downward,
            label: 'Sort Z to A',
          ),
        ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-header-clear-sort-${table.id}-$column'),
          value: _SheetTableHeaderAction.clearSort,
          enabled: isSorted,
          child: _HeaderActionLabel(
            icon: Icons.swap_vert,
            label: 'Clear Sort',
            detail: isSorted
                ? 'Current sort: ${sortAscending ? 'A to Z' : 'Z to A'}'
                : 'No active sort',
          ),
        ),
        if (filterSummary.hasFilter)
          PopupMenuItem(
            key: ValueKey(
              'ky-sheet-table-header-filter-status-${table.id}-$column',
            ),
            enabled: false,
            child: _HeaderActionLabel(
              icon: Icons.filter_alt,
              label: 'Active Filter',
              detail: filterSummary.detailLabel,
            ),
          ),
        if (tableFilterSummary.hasFilters)
          PopupMenuItem(
            key: ValueKey(
              'ky-sheet-table-header-filter-impact-${table.id}-$column',
            ),
            enabled: false,
            child: _HeaderActionLabel(
              icon: Icons.filter_list_outlined,
              label: 'Filter Impact',
              detail: SheetTableFilterImpactLabelBuilder.build(
                filterSummary: tableFilterSummary,
                visibilitySummary: tableFilterVisibilitySummary,
              ),
            ),
          ),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-header-filter-${table.id}-$column'),
          value: _SheetTableHeaderAction.filterColumn,
          child: _HeaderActionLabel(
            icon: Icons.filter_alt_outlined,
            label: 'Filter Column',
            detail: filterSummary.hasFilter
                ? 'Edit ${filterSummary.detailLabel}'
                : 'Open filter options',
          ),
        ),
        PopupMenuItem(
          key: ValueKey(
            'ky-sheet-table-header-clear-filter-${table.id}-$column',
          ),
          value: _SheetTableHeaderAction.clearFilter,
          enabled: filterSummary.hasFilter,
          child: _HeaderActionLabel(
            icon: Icons.filter_alt_off_outlined,
            label: 'Clear Filter',
            detail: filterSummary.detailLabel,
          ),
        ),
        if (tableFilterSummary.hasFilters)
          PopupMenuItem(
            key: ValueKey(
              'ky-sheet-table-header-clear-table-filters-${table.id}-$column',
            ),
            value: _SheetTableHeaderAction.clearTableFilters,
            child: _HeaderActionLabel(
              icon: Icons.filter_alt_off,
              label: 'Clear Table Filters',
              detail: SheetTableFilterImpactLabelBuilder.build(
                filterSummary: tableFilterSummary,
                visibilitySummary: tableFilterVisibilitySummary,
              ),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: ValueKey('ky-sheet-table-header-studio-${table.id}-$column'),
          value: _SheetTableHeaderAction.tableStudio,
          child: const _HeaderActionLabel(
            icon: Icons.table_chart_outlined,
            label: 'Table Studio',
          ),
        ),
      ],
    );
    if (action == null || !context.mounted) return;
    await _handleAction(
      context,
      ref,
      action,
      formulaSummary: formulaSummary,
      tableFilterSummary: tableFilterSummary,
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _SheetTableHeaderAction action, {
    required SheetTableCalculatedColumnSummary formulaSummary,
    required SheetTableFilterSummary tableFilterSummary,
  }) async {
    switch (action) {
      case _SheetTableHeaderAction.renameHeader:
        return _renameHeader(context, ref);
      case _SheetTableHeaderAction.selectColumnBody:
        final selection = formulaSummary.bodySelection;
        if (selection != null) {
          ref.read(selectedCellProvider.notifier).state = selection;
        }
        return;
      case _SheetTableHeaderAction.sortAscending:
        ref
            .read(toolbarControllerProvider)
            .sortTableColumn(table, column, ascending: true);
        return;
      case _SheetTableHeaderAction.sortDescending:
        ref
            .read(toolbarControllerProvider)
            .sortTableColumn(table, column, ascending: false);
        return;
      case _SheetTableHeaderAction.clearSort:
        ref.read(toolbarControllerProvider).clearSort();
        return;
      case _SheetTableHeaderAction.filterColumn:
        return _showFilterDialog(context, ref);
      case _SheetTableHeaderAction.clearFilter:
        ref.read(toolbarControllerProvider).removeFilterColumn(column);
        return;
      case _SheetTableHeaderAction.clearTableFilters:
        if (!tableFilterSummary.hasFilters) return;
        ref
            .read(toolbarControllerProvider)
            .clearFilterColumns(tableFilterSummary.activeColumns);
        ref.read(selectedCellProvider.notifier).state = table.selection;
        return;
      case _SheetTableHeaderAction.tableStudio:
        ref.read(activeSidebarPanelProvider.notifier).state =
            SheetSidebarPanel.tables;
        return;
    }
  }

  Future<void> _renameHeader(BuildContext context, WidgetRef ref) async {
    final address = CellAddress(table.minRow, column);
    final initialName = SheetTableHeaderNameValidator.currentName(
      table: table,
      column: column,
      cells: ref.read(spreadsheetProvider),
    );

    final nextName = await showDialog<String>(
      context: context,
      builder: (_) => SheetTableHeaderRenameDialog(
        initialName: initialName,
        validator: (value) => SheetTableHeaderNameValidator.validate(
          table: table,
          column: column,
          cells: ref.read(spreadsheetProvider),
          value: value,
        ),
      ),
    );
    if (nextName == null || !context.mounted) return;

    final trimmedName = nextName.trim();
    ref.read(selectedCellProvider.notifier).state = CellSelection(address);
    if (trimmedName == initialName.trim()) return;

    final currentCell = ref.read(spreadsheetProvider)[address] ?? CellData();
    ref.read(spreadsheetProvider.notifier).replaceCells({
      address: currentCell.copyWith(value: trimmedName, clearFormula: true),
    }, description: 'Rename table header');
  }

  Future<void> _showFilterDialog(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(filterProvider);
    final filterRules = ref.read(sheetFilterRulesProvider);
    final cells = ref.read(spreadsheetProvider);
    final headerName = SheetTableHeaderNameValidator.currentName(
      table: table,
      column: column,
      cells: cells,
    );
    final activeRules = SheetFilterEvaluator.effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );
    final sortColumn = ref.read(sortColumnProvider);
    final result = await showDialog<SheetColumnFilterDialogResult>(
      context: context,
      builder: (_) => SheetColumnFilterDialog(
        column: column,
        titleText: 'Sort & Filter ${table.name}[$headerName]',
        scopeDescription: 'Table body values only',
        initialRule: activeRules[column] ?? const SheetFilterRule(),
        values: SheetColumnFilterValueBuilder.build(
          column: column,
          cells: cells,
          rows: _tableBodyRows(),
        ),
        isSorted: sortColumn == column,
        sortAscending: ref.read(sortAscendingProvider),
      ),
    );
    if (result == null || !context.mounted) return;

    final toolbar = ref.read(toolbarControllerProvider);
    switch (result.action) {
      case SheetColumnFilterDialogAction.sortAscending:
        toolbar.sortTableColumn(table, column, ascending: true);
        break;
      case SheetColumnFilterDialogAction.sortDescending:
        toolbar.sortTableColumn(table, column, ascending: false);
        break;
      case SheetColumnFilterDialogAction.clearSort:
        toolbar.clearSort();
        break;
      case SheetColumnFilterDialogAction.clearFilter:
        toolbar.removeFilterColumn(column);
        break;
      case SheetColumnFilterDialogAction.applyFilter:
        final rule = result.rule;
        if (rule == null) {
          toolbar.removeFilterColumn(column);
        } else {
          toolbar.setFilterRule(column, rule);
        }
        break;
    }

    final lastFilterRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    ref.read(selectedCellProvider.notifier).state = CellSelection(
      CellAddress(table.minRow, column),
      CellAddress(lastFilterRow, column),
    );
  }

  Iterable<int> _tableBodyRows() sync* {
    final firstBodyRow = table.showHeaderRow ? table.minRow + 1 : table.minRow;
    final lastBodyRow = table.hasTotalsRow ? table.maxRow - 1 : table.maxRow;
    for (var row = firstBodyRow; row <= lastBodyRow; row += 1) {
      yield row;
    }
  }
}

/// Menu row layout for structured table header actions.
class _HeaderActionLabel extends StatelessWidget {
  const _HeaderActionLabel({
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

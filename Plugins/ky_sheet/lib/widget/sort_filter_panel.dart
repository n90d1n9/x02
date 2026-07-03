import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/sheet_filter_rule.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_filter_evaluator.dart';
import 'sheet_filter_rule_editor.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for sorting selected ranges and filtering spreadsheet columns.
class SortFilterPanel extends ConsumerStatefulWidget {
  const SortFilterPanel({super.key, this.onClose});

  /// Called when the user closes the sidebar panel.
  final VoidCallback? onClose;

  @override
  ConsumerState<SortFilterPanel> createState() => _SortFilterPanelState();
}

/// State holder for the sort and filter editor controls.
class _SortFilterPanelState extends ConsumerState<SortFilterPanel> {
  final _filterController = TextEditingController();
  final _filterFocusNode = FocusNode();

  int? _syncedColumn;
  SheetFilterOperator? _syncedOperator;
  String? _syncedValue;
  SheetFilterOperator _operator = SheetFilterOperator.contains;

  @override
  void dispose() {
    _filterController.dispose();
    _filterFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final cells = ref.watch(spreadsheetProvider);
    final filters = ref.watch(filterProvider);
    final filterRules = ref.watch(sheetFilterRulesProvider);
    final activeRules = SheetFilterEvaluator.effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );
    final sortColumn = ref.watch(sortColumnProvider);
    final sortAscending = ref.watch(sortAscendingProvider);
    final controller = ref.watch(toolbarControllerProvider);
    final selectedColumn = selection?.start.col;
    final selectedRule = selectedColumn == null
        ? const SheetFilterRule()
        : activeRules[selectedColumn] ?? const SheetFilterRule();
    final sortTarget = _sortTarget(selection, cells, selectedColumn);
    final summary = _FilterSummary.from(
      cells: cells,
      filters: filters,
      filterRules: filterRules,
    );

    _syncSelectedRule(selectedColumn, selectedRule);

    return SheetSidebarPanelSurface(
      icon: Icons.filter_alt,
      title: 'Sort & Filter',
      subtitle: 'Sort ranges and filter rows',
      trailing: SheetSidebarPanelLabelBadge(label: selection?.label ?? 'None'),
      onClose: widget.onClose,
      footer: _SortFilterFooter(
        canUseColumnActions: selectedColumn != null,
        hasActiveRules: activeRules.isNotEmpty,
        onApply: () => _applyFilter(controller, selectedColumn),
        onClearColumn: () {
          if (selectedColumn == null) return;
          _clearColumnFilter(controller, selectedColumn);
        },
        onClearAll: controller.clearFilters,
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _StatusBand(
            icon: Icons.filter_alt,
            label: summary.activeCount == 0
                ? 'No active filters'
                : '${summary.activeCount} active filter${summary.activeCount == 1 ? '' : 's'}',
            detail: summary.detail,
          ),
          const SizedBox(height: 18),
          _SectionLabel(
            icon: Icons.sort,
            label: 'Sort',
            detail: sortColumn == null
                ? 'No sort'
                : '${CellAddress.colToLabel(sortColumn)} ${sortAscending ? 'A-Z' : 'Z-A'}',
          ),
          const SizedBox(height: 10),
          _SortButtonRow(
            enabled: sortTarget?.isRange() ?? false,
            onSortAscending: () =>
                _sort(controller, sortTarget, selectedColumn, ascending: true),
            onSortDescending: () =>
                _sort(controller, sortTarget, selectedColumn, ascending: false),
          ),
          const SizedBox(height: 18),
          _SectionLabel(
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            detail: selectedColumn == null
                ? 'No column'
                : 'Column ${CellAddress.colToLabel(selectedColumn)}',
          ),
          const SizedBox(height: 10),
          SheetFilterRuleEditor(
            operator: _operator,
            valueController: _filterController,
            focusNode: _filterFocusNode,
            enabled: selectedColumn != null,
            onOperatorChanged: _setOperator,
            onSubmitted: () => _applyFilter(controller, selectedColumn),
          ),
          const SizedBox(height: 10),
          _QuickFilterChips(
            enabled: selectedColumn != null,
            onSelected: _setOperator,
          ),
          const SizedBox(height: 18),
          _SectionLabel(
            icon: Icons.tune,
            label: 'Active Filters',
            detail: activeRules.length.toString(),
          ),
          const SizedBox(height: 8),
          if (activeRules.isEmpty)
            const _EmptyFilters()
          else
            for (final entry
                in activeRules.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
              _ActiveFilterTile(
                column: entry.key,
                rule: entry.value,
                onRemove: () => controller.removeFilterColumn(entry.key),
              ),
        ],
      ),
    );
  }

  void _syncSelectedRule(int? selectedColumn, SheetFilterRule rule) {
    final isAlreadySynced =
        _syncedColumn == selectedColumn &&
        _syncedOperator == rule.operator &&
        _syncedValue == rule.value;
    if (isAlreadySynced) return;
    if (_filterFocusNode.hasFocus && _syncedColumn == selectedColumn) return;

    _syncedColumn = selectedColumn;
    _syncedOperator = rule.operator;
    _syncedValue = rule.value;
    final editorOperator = rule.operator == SheetFilterOperator.oneOf
        ? SheetFilterOperator.contains
        : rule.operator;
    final editorValue = rule.operator == SheetFilterOperator.oneOf
        ? ''
        : rule.value;
    _operator = editorOperator;
    if (_filterController.text != editorValue) {
      _filterController.text = editorValue;
      _filterController.selection = TextSelection.collapsed(
        offset: editorValue.length,
      );
    }
  }

  void _setOperator(SheetFilterOperator operator) {
    setState(() {
      _operator = operator;
      if (!operator.requiresValue) {
        _filterController.clear();
        _filterFocusNode.unfocus();
      }
    });
  }

  CellSelection? _sortTarget(
    CellSelection? selection,
    Map<CellAddress, CellData> cells,
    int? selectedColumn,
  ) {
    if (selectedColumn == null) return null;
    if (selection != null && selection.isRange()) return selection;
    if (cells.isEmpty) return null;

    final maxRow = cells.keys.map((address) => address.row).reduce(math.max);
    final maxCol = math.max(
      selectedColumn,
      cells.keys.map((address) => address.col).reduce(math.max),
    );

    return CellSelection(CellAddress(0, 0), CellAddress(maxRow, maxCol));
  }

  void _sort(
    ToolbarController controller,
    CellSelection? selection,
    int? selectedColumn, {
    required bool ascending,
  }) {
    if (selection == null || selectedColumn == null || !selection.isRange()) {
      return;
    }
    controller.sortSelection(
      selection,
      ascending: ascending,
      sortColumn: selectedColumn,
    );
  }

  void _applyFilter(ToolbarController controller, int? selectedColumn) {
    if (selectedColumn == null) return;
    controller.setFilterRule(
      selectedColumn,
      SheetFilterRule(operator: _operator, value: _filterController.text),
    );
  }

  void _clearColumnFilter(ToolbarController controller, int selectedColumn) {
    controller.removeFilterColumn(selectedColumn);
    _filterController.clear();
    setState(() => _operator = SheetFilterOperator.contains);
  }
}

/// Computed filter metrics displayed at the top of the panel.
class _FilterSummary {
  const _FilterSummary({
    required this.totalRows,
    required this.visibleRows,
    required this.activeCount,
  });

  factory _FilterSummary.from({
    required Map<CellAddress, CellData> cells,
    required Map<int, String> filters,
    required Map<int, SheetFilterRule> filterRules,
  }) {
    final activeRules = SheetFilterEvaluator.effectiveRules(
      filters: filters,
      filterRules: filterRules,
    );
    if (cells.isEmpty) {
      return _FilterSummary(
        totalRows: 0,
        visibleRows: 0,
        activeCount: activeRules.length,
      );
    }

    final maxRow = cells.keys.map((address) => address.row).reduce(math.max);
    final rows = [for (var row = 0; row <= maxRow; row++) row];
    final visibleRows = SheetFilterEvaluator.visibleRows(
      rows: rows,
      filters: filters,
      filterRules: filterRules,
      cells: cells,
    );

    return _FilterSummary(
      totalRows: rows.length,
      visibleRows: visibleRows.length,
      activeCount: activeRules.length,
    );
  }

  final int totalRows;
  final int visibleRows;
  final int activeCount;

  String get detail {
    if (totalRows == 0) return 'No used rows';
    return '$visibleRows of $totalRows rows visible';
  }
}

/// Summary card that reports the current filter visibility state.
class _StatusBand extends StatelessWidget {
  const _StatusBand({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: KySheetColors.accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Label row used to introduce compact sort and filter sections.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: KySheetColors.mutedText, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          detail,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Pair of directional sort actions for the selected range.
class _SortButtonRow extends StatelessWidget {
  const _SortButtonRow({
    required this.enabled,
    required this.onSortAscending,
    required this.onSortDescending,
  });

  final bool enabled;
  final VoidCallback onSortAscending;
  final VoidCallback onSortDescending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: enabled ? onSortAscending : null,
            icon: const Icon(Icons.arrow_upward, size: 18),
            label: const Text('A-Z'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: enabled ? onSortDescending : null,
            icon: const Icon(Icons.arrow_downward, size: 18),
            label: const Text('Z-A'),
          ),
        ),
      ],
    );
  }
}

/// Preset filter operator chips for common spreadsheet filtering choices.
class _QuickFilterChips extends StatelessWidget {
  const _QuickFilterChips({required this.enabled, required this.onSelected});

  final bool enabled;
  final ValueChanged<SheetFilterOperator> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = [
      SheetFilterOperator.contains,
      SheetFilterOperator.equals,
      SheetFilterOperator.empty,
      SheetFilterOperator.notEmpty,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ActionChip(
            label: Text(option.label),
            avatar: Icon(_iconFor(option), size: 16),
            onPressed: enabled ? () => onSelected(option) : null,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  IconData _iconFor(SheetFilterOperator operator) {
    return switch (operator) {
      SheetFilterOperator.contains => Icons.search,
      SheetFilterOperator.equals => Icons.drag_handle,
      SheetFilterOperator.empty => Icons.check_box_outline_blank,
      SheetFilterOperator.notEmpty => Icons.check_box,
      _ => Icons.filter_alt_outlined,
    };
  }
}

/// Sticky footer that keeps primary filter actions reachable.
class _SortFilterFooter extends StatelessWidget {
  const _SortFilterFooter({
    required this.canUseColumnActions,
    required this.hasActiveRules,
    required this.onApply,
    required this.onClearColumn,
    required this.onClearAll,
  });

  final bool canUseColumnActions;
  final bool hasActiveRules;
  final VoidCallback onApply;
  final VoidCallback onClearColumn;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('ky-sheet-filter-footer'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('ky-sheet-filter-apply'),
                  onPressed: canUseColumnActions ? onApply : null,
                  icon: const Icon(Icons.done, size: 18),
                  label: const Text('Apply'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: canUseColumnActions ? onClearColumn : null,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                tooltip: 'Clear Column Filter',
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: hasActiveRules ? onClearAll : null,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }
}

/// Removable row describing one active column filter.
class _ActiveFilterTile extends StatelessWidget {
  const _ActiveFilterTile({
    required this.column,
    required this.rule,
    required this.onRemove,
  });

  final int column;
  final SheetFilterRule rule;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KySheetColors.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: KySheetColors.gridLineStrong),
            ),
            child: Text(
              CellAddress.colToLabel(column),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rule.description,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove Filter',
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when no column filters are active.
class _EmptyFilters extends StatelessWidget {
  const _EmptyFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: const Text(
        'No active filters',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

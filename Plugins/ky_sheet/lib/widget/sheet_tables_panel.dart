import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/sheet_table_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_table_range_resolver.dart';
import 'sheet_sidebar_panel_surface.dart';
import 'sheet_table_design_tile.dart';

/// Sidebar workspace for creating and tuning structured table ranges.
class SheetTablesPanel extends ConsumerWidget {
  const SheetTablesPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedCellProvider);
    final tables = ref.watch(sheetTablesProvider);
    final cells = ref.watch(spreadsheetProvider);
    final notifier = ref.read(sheetTablesProvider.notifier);

    return SheetSidebarPanelSurface(
      icon: Icons.table_chart_outlined,
      title: 'Table Studio',
      subtitle: 'Structured ranges',
      trailing: SheetSidebarPanelCountBadge(count: tables.length),
      width: 326,
      onClose: onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _TableActionBand(
            selection: selection,
            tableCount: tables.length,
            onCreate: selection == null
                ? null
                : () => notifier.createFromSelection(selection),
          ),
          const SizedBox(height: 14),
          if (tables.isEmpty)
            const _EmptyTablesPanel()
          else
            for (final table in tables) ...[
              SheetTableDesignTile(
                table: table,
                activeSelection: selection,
                expandedSelection: SheetTableRangeResolver.expandDownRight(
                  table: table,
                  cells: cells,
                ),
                onGoTo: () => ref
                    .read(sheetNavigationControllerProvider)
                    .goTo(table.selection),
                onNameSubmitted: (name) => notifier.rename(table.id, name),
                onUseSelection: selection == null
                    ? null
                    : () => notifier.setSelection(table.id, selection),
                onExpandToData: (expandedSelection) =>
                    notifier.setSelection(table.id, expandedSelection),
                onStyleChanged: (styleId) =>
                    notifier.setStyle(table.id, styleId),
                onHeaderRowChanged: (visible) =>
                    notifier.setHeaderRowVisible(table.id, visible),
                onBandedRowsChanged: (visible) =>
                    notifier.setBandedRowsVisible(table.id, visible),
                onTotalsRowChanged: (visible) =>
                    notifier.setTotalsRowVisible(table.id, visible),
                onRemove: () => notifier.remove(table.id),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

/// Action card for creating a table from the active selection.
class _TableActionBand extends StatelessWidget {
  const _TableActionBand({
    required this.selection,
    required this.tableCount,
    required this.onCreate,
  });

  final CellSelection? selection;
  final int tableCount;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.select_all, color: KySheetColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selection?.label ?? 'No active selection',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _summaryLabel,
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
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('ky-sheet-tables-create'),
              onPressed: onCreate,
              icon: const Icon(Icons.add_chart_outlined, size: 18),
              label: const Text('Create Table'),
            ),
          ],
        ),
      ),
    );
  }

  String get _summaryLabel {
    if (selection == null) return '$tableCount table styles ready';
    return '$tableCount tables · selected range ready';
  }
}

/// Empty state for workbooks without structured tables.
class _EmptyTablesPanel extends StatelessWidget {
  const _EmptyTablesPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(
              Icons.view_week_outlined,
              color: KySheetColors.mutedText,
              size: 26,
            ),
            SizedBox(height: 8),
            Text(
              'No structured tables yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Select a range to create a styled table workspace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

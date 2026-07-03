import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sheet_table.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/sheet_active_table_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../utils/sheet_table_filter_summary_builder.dart';
import '../utils/sheet_table_filter_visibility_summary_builder.dart';
import 'sheet_ribbon_surface.dart';
import 'sheet_ribbon_tab.dart';
import 'sheet_ribbon_tab_groups.dart';

/// Primary spreadsheet ribbon that coordinates tabs, context, and commands.
class ToolbarWidget extends ConsumerStatefulWidget {
  const ToolbarWidget({super.key});

  @override
  ConsumerState<ToolbarWidget> createState() => _ToolbarWidgetState();
}

class _ToolbarWidgetState extends ConsumerState<ToolbarWidget> {
  SheetRibbonTab _selectedTab = SheetRibbonTab.home;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final activeTable = ref.watch(activeSheetTableProvider);
    final cells = ref.watch(spreadsheetProvider);
    final activeTableFilterSummary = _activeTableFilterSummary(
      ref,
      activeTable,
    );
    final activeTableFilterVisibilityLabel = activeTableFilterSummary == null
        ? null
        : SheetTableFilterVisibilitySummaryBuilder.forTable(
            filterSummary: activeTableFilterSummary,
            cells: cells,
          ).detailLabel;
    final zoom = ref.watch(zoomLevelProvider);
    final controller = ref.watch(toolbarControllerProvider);
    final groups = SheetRibbonTabGroups.build(
      tab: _selectedTab,
      controller: controller,
      selection: selection,
      activeTable: activeTable,
      zoom: zoom,
      onOpenPanel: (panel) => _openPanel(ref, panel),
    );

    return SheetRibbonSurface(
      selectedTab: _selectedTab,
      selectionLabel: selection?.label,
      activeTable: activeTable,
      activeTableFilterLabel: activeTableFilterSummary?.detailLabel,
      activeTableFilterVisibilityLabel: activeTableFilterVisibilityLabel,
      onClearActiveTableFilters: activeTableFilterSummary == null
          ? null
          : () => _clearActiveTableFilters(ref, activeTableFilterSummary),
      onOpenTableStudio: activeTable == null
          ? null
          : () => _openPanel(ref, SheetSidebarPanel.tables),
      groups: groups,
      onTabSelected: (tab) => setState(() => _selectedTab = tab),
    );
  }

  void _openPanel(WidgetRef ref, SheetSidebarPanel panel) {
    ref.read(activeSidebarPanelProvider.notifier).state = panel;
  }

  SheetTableFilterSummary? _activeTableFilterSummary(
    WidgetRef ref,
    SheetTable? activeTable,
  ) {
    if (activeTable == null) return null;

    final summary = SheetTableFilterSummaryBuilder.forTable(
      table: activeTable,
      filters: ref.watch(filterProvider),
      filterRules: ref.watch(sheetFilterRulesProvider),
    );
    return summary.hasFilters ? summary : null;
  }

  void _clearActiveTableFilters(
    WidgetRef ref,
    SheetTableFilterSummary summary,
  ) {
    ref
        .read(toolbarControllerProvider)
        .clearFilterColumns(summary.activeColumns);
  }
}

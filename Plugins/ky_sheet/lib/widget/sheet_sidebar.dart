import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sheet_sidebar_provider.dart';
import 'conditional_format_panel.dart';
import 'sheet_chart_builder_panel.dart';
import 'sheet_cell_inspector_panel.dart';
import 'sheet_data_cleanup_panel.dart';
import 'sheet_data_insights_panel.dart';
import 'sheet_data_validation_panel.dart';
import 'sheet_engine_operation_panel.dart';
import 'sheet_find_replace_panel.dart';
import 'sheet_formula_audit_panel.dart';
import 'sheet_formula_health_panel.dart';
import 'sheet_function_library_panel.dart';
import 'sheet_go_to_special_panel.dart';
import 'sheet_history_panel.dart';
import 'sheet_named_ranges_panel.dart';
import 'sheet_performance_panel.dart';
import 'sheet_review_panel.dart';
import 'sheet_sidebar_rail.dart';
import 'sheet_shortcuts_panel.dart';
import 'sheet_tables_panel.dart';
import 'sheet_view_panel.dart';
import 'sort_filter_panel.dart';

class SheetSidebar extends ConsumerWidget {
  const SheetSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePanel = ref.watch(activeSidebarPanelProvider);

    return Row(
      children: [
        SheetSidebarRail(
          activePanel: activePanel,
          onPanelPressed: (panel) => _togglePanel(ref, panel),
          onClosePressed: () => _closePanel(ref),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (activePanel) {
            SheetSidebarPanel.cellInspector => const SheetCellInspectorPanel(),
            SheetSidebarPanel.shortcuts => SheetShortcutsPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.functionLibrary => SheetFunctionLibraryPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.formulaAudit => SheetFormulaAuditPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.formulaHealth => SheetFormulaHealthPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.goToSpecial => SheetGoToSpecialPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.history => SheetHistoryPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.sheetEngineOperations =>
              SheetEngineOperationPanel(onClose: () => _closePanel(ref)),
            SheetSidebarPanel.review => SheetReviewPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.chartBuilder => SheetChartBuilderPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.namedRanges => SheetNamedRangesPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.tables => SheetTablesPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.dataInsights => SheetDataInsightsPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.dataCleanup => SheetDataCleanupPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.findReplace => SheetFindReplacePanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.sortFilter => SortFilterPanel(
              onClose: () => _closePanel(ref),
            ),
            SheetSidebarPanel.sheetView => const SheetViewPanel(),
            SheetSidebarPanel.conditionalFormat =>
              const ConditionalFormatPanel(),
            SheetSidebarPanel.dataValidation =>
              const SheetDataValidationPanel(),
            SheetSidebarPanel.performance => const SheetPerformancePanel(),
            null => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }

  void _togglePanel(WidgetRef ref, SheetSidebarPanel panel) {
    final notifier = ref.read(activeSidebarPanelProvider.notifier);
    notifier.state = notifier.state == panel ? null : panel;
  }

  void _closePanel(WidgetRef ref) {
    ref.read(activeSidebarPanelProvider.notifier).state = null;
  }
}

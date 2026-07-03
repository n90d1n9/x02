import 'package:flutter/material.dart';

import '../state/sheet_sidebar_provider.dart';
import 'sheet_ribbon_command_row.dart';
import 'tool_button.dart';

/// Describes a ribbon shortcut that opens a sidebar panel.
class SheetRibbonPanelLauncherAction {
  const SheetRibbonPanelLauncherAction({
    required this.panel,
    required this.icon,
    required this.tooltip,
  });

  final SheetSidebarPanel panel;
  final IconData icon;
  final String tooltip;
}

/// Catalog of sidebar launcher actions grouped by ribbon tab.
class SheetRibbonPanelLauncherCatalog {
  const SheetRibbonPanelLauncherCatalog._();

  static const formulas = [
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.functionLibrary,
      icon: Icons.functions,
      tooltip: 'Function Library',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.formulaAudit,
      icon: Icons.schema_outlined,
      tooltip: 'Formula Audit',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.formulaHealth,
      icon: Icons.health_and_safety_outlined,
      tooltip: 'Formula Health',
    ),
  ];

  static const insert = [
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.chartBuilder,
      icon: Icons.insert_chart_outlined,
      tooltip: 'Chart Builder',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.namedRanges,
      icon: Icons.bookmarks_outlined,
      tooltip: 'Named Ranges',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.functionLibrary,
      icon: Icons.functions,
      tooltip: 'Function Library',
    ),
  ];

  static const data = [
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.tables,
      icon: Icons.table_chart_outlined,
      tooltip: 'Table Studio',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.dataInsights,
      icon: Icons.insights,
      tooltip: 'Data Insights',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.dataCleanup,
      icon: Icons.cleaning_services_outlined,
      tooltip: 'Data Cleanup',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.sortFilter,
      icon: Icons.filter_alt_outlined,
      tooltip: 'Sort & Filter Panel',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.dataValidation,
      icon: Icons.rule,
      tooltip: 'Data Validation Panel',
    ),
  ];

  static const view = [
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.performance,
      icon: Icons.speed,
      tooltip: 'Performance',
    ),
  ];

  static const review = [
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.review,
      icon: Icons.rate_review_outlined,
      tooltip: 'Review',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.sheetEngineOperations,
      icon: Icons.hub_outlined,
      tooltip: 'Waraq Operations',
    ),
    SheetRibbonPanelLauncherAction(
      panel: SheetSidebarPanel.history,
      icon: Icons.history,
      tooltip: 'History',
    ),
  ];
}

/// Renders sidebar panel launchers as compact ribbon command buttons.
class SheetRibbonPanelLauncherGroup extends StatelessWidget {
  const SheetRibbonPanelLauncherGroup({
    super.key,
    required this.actions,
    required this.onOpenPanel,
  });

  final List<SheetRibbonPanelLauncherAction> actions;
  final ValueChanged<SheetSidebarPanel> onOpenPanel;

  @override
  Widget build(BuildContext context) {
    return SheetRibbonCommandRow(
      children: [
        for (final action in actions)
          ToolButton(
            key: ValueKey('ky-sheet-ribbon-panel-${action.panel.name}'),
            icon: action.icon,
            onPressed: () => onOpenPanel(action.panel),
            tooltip: action.tooltip,
          ),
      ],
    );
  }
}

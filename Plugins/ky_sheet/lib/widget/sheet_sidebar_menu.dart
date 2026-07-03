import 'package:flutter/material.dart';

import '../model/sheet_shortcut.dart';
import '../state/sheet_sidebar_provider.dart';

/// Groups related sidebar panel launchers for the vertical sheet rail.
class SheetSidebarMenuSection {
  const SheetSidebarMenuSection({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<SheetSidebarMenuItem> items;
}

/// Describes one sidebar panel launcher and its optional keyboard shortcut.
class SheetSidebarMenuItem {
  const SheetSidebarMenuItem({
    required this.panel,
    required this.icon,
    required this.tooltip,
    this.shortcutLabel,
  });

  final SheetSidebarPanel panel;
  final IconData icon;
  final String tooltip;
  final String? shortcutLabel;
}

/// Catalog of sidebar panels shown in the sheet rail.
class SheetSidebarMenu {
  const SheetSidebarMenu._();

  static const sections = [
    SheetSidebarMenuSection(
      id: 'core',
      label: 'Core Tools',
      items: [
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.cellInspector,
          icon: Icons.info_outline,
          tooltip: 'Cell Inspector',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.shortcuts,
          icon: Icons.keyboard_alt_outlined,
          tooltip: 'Shortcuts',
          shortcutLabel: SheetShortcutLabels.shortcuts,
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.functionLibrary,
          icon: Icons.functions,
          tooltip: 'Function Library',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.formulaAudit,
          icon: Icons.schema_outlined,
          tooltip: 'Formula Audit',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.formulaHealth,
          icon: Icons.health_and_safety_outlined,
          tooltip: 'Formula Health',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.goToSpecial,
          icon: Icons.manage_search,
          tooltip: 'Go To Special',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.history,
          icon: Icons.history,
          tooltip: 'History',
        ),
      ],
    ),
    SheetSidebarMenuSection(
      id: 'review-sync',
      label: 'Review & Sync',
      items: [
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.sheetEngineOperations,
          icon: Icons.hub_outlined,
          tooltip: 'Waraq Operations',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.review,
          icon: Icons.rate_review_outlined,
          tooltip: 'Review',
        ),
      ],
    ),
    SheetSidebarMenuSection(
      id: 'data',
      label: 'Data Tools',
      items: [
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.chartBuilder,
          icon: Icons.insert_chart_outlined,
          tooltip: 'Chart Builder',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.namedRanges,
          icon: Icons.bookmarks_outlined,
          tooltip: 'Named Ranges',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.tables,
          icon: Icons.table_chart_outlined,
          tooltip: 'Table Studio',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.dataInsights,
          icon: Icons.insights,
          tooltip: 'Data Insights',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.dataCleanup,
          icon: Icons.cleaning_services_outlined,
          tooltip: 'Data Cleanup',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.findReplace,
          icon: Icons.find_replace,
          tooltip: 'Find & Replace',
          shortcutLabel: SheetShortcutLabels.findReplace,
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.sortFilter,
          icon: Icons.filter_alt,
          tooltip: 'Sort & Filter',
          shortcutLabel: SheetShortcutLabels.sortFilter,
        ),
      ],
    ),
    SheetSidebarMenuSection(
      id: 'view-rules',
      label: 'View & Rules',
      items: [
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.sheetView,
          icon: Icons.visibility_outlined,
          tooltip: 'Sheet View',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.conditionalFormat,
          icon: Icons.format_color_fill,
          tooltip: 'Conditional Format',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.dataValidation,
          icon: Icons.rule,
          tooltip: 'Data Validation',
        ),
        SheetSidebarMenuItem(
          panel: SheetSidebarPanel.performance,
          icon: Icons.speed,
          tooltip: 'Performance',
        ),
      ],
    ),
  ];

  static Iterable<SheetSidebarMenuItem> get items sync* {
    for (final section in sections) {
      yield* section.items;
    }
  }
}

import 'package:flutter/material.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/toolbar_provider.dart';
import 'sheet_ribbon_data_group.dart';
import 'sheet_ribbon_formula_group.dart';
import 'sheet_ribbon_group.dart';
import 'sheet_ribbon_home_groups.dart';
import 'sheet_ribbon_panel_launcher_group.dart';
import 'sheet_ribbon_review_group.dart';
import 'sheet_ribbon_structure_group.dart';
import 'sheet_ribbon_tab.dart';
import 'sheet_ribbon_view_group.dart';

class SheetRibbonTabGroups {
  const SheetRibbonTabGroups._();

  static List<Widget> build({
    required SheetRibbonTab tab,
    required ToolbarController controller,
    required CellSelection? selection,
    SheetTable? activeTable,
    required double zoom,
    required ValueChanged<SheetSidebarPanel> onOpenPanel,
  }) {
    return switch (tab) {
      SheetRibbonTab.home => [
        SheetRibbonHomeGroups(controller: controller, selection: selection),
      ],
      SheetRibbonTab.insert => [
        SheetRibbonGroup(
          label: 'Rows & Columns',
          icon: Icons.view_week_outlined,
          children: [
            SheetRibbonStructureGroup(
              controller: controller,
              selection: selection,
            ),
          ],
        ),
        SheetRibbonGroup(
          label: 'Insert',
          icon: Icons.add_chart_outlined,
          children: [
            _panelLaunchers(
              SheetRibbonPanelLauncherCatalog.insert,
              onOpenPanel,
            ),
          ],
        ),
      ],
      SheetRibbonTab.data => [
        SheetRibbonGroup(
          label: 'Data',
          icon: Icons.filter_alt,
          children: [
            SheetRibbonDataGroup(
              controller: controller,
              selection: selection,
              activeTable: activeTable,
              onOpenPanel: onOpenPanel,
            ),
          ],
        ),
        SheetRibbonGroup(
          label: 'Quality',
          icon: Icons.rule,
          children: [
            _panelLaunchers(SheetRibbonPanelLauncherCatalog.data, onOpenPanel),
          ],
        ),
      ],
      SheetRibbonTab.formulas => [
        SheetRibbonGroup(
          label: 'Formula',
          icon: Icons.functions,
          children: [
            SheetRibbonFormulaGroup(
              controller: controller,
              selection: selection,
              onOpenPanel: onOpenPanel,
            ),
          ],
        ),
      ],
      SheetRibbonTab.view => [
        SheetRibbonGroup(
          label: 'View',
          icon: Icons.visibility_outlined,
          children: [
            SheetRibbonViewGroup(
              controller: controller,
              selection: selection,
              zoom: zoom,
              onOpenPanel: onOpenPanel,
            ),
          ],
        ),
        SheetRibbonGroup(
          label: 'Performance',
          icon: Icons.speed,
          children: [
            _panelLaunchers(SheetRibbonPanelLauncherCatalog.view, onOpenPanel),
          ],
        ),
      ],
      SheetRibbonTab.review => [
        SheetRibbonGroup(
          label: 'Review',
          icon: Icons.rate_review_outlined,
          children: [SheetRibbonReviewGroup(onOpenPanel: onOpenPanel)],
        ),
      ],
    };
  }

  static Widget _panelLaunchers(
    List<SheetRibbonPanelLauncherAction> actions,
    ValueChanged<SheetSidebarPanel> onOpenPanel,
  ) {
    return SheetRibbonPanelLauncherGroup(
      actions: actions,
      onOpenPanel: onOpenPanel,
    );
  }
}

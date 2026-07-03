import 'package:flutter/material.dart';

import '../model/cell/cell_selection.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/toolbar_provider.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_menu_button.dart';
import 'sheet_zoom_control.dart';
import 'tool_button.dart';

/// View ribbon commands for freeze panes, sheet view panels, and zoom.
class SheetRibbonViewGroup extends StatelessWidget {
  const SheetRibbonViewGroup({
    super.key,
    required this.controller,
    required this.selection,
    required this.zoom,
    required this.onOpenPanel,
  });

  final ToolbarController controller;
  final CellSelection? selection;
  final double zoom;
  final ValueChanged<SheetSidebarPanel> onOpenPanel;

  @override
  Widget build(BuildContext context) {
    return SheetRibbonCommandRow(
      children: [
        _FreezeMenuButton(controller: controller, selection: selection),
        ToolButton(
          icon: Icons.visibility_outlined,
          onPressed: () => onOpenPanel(SheetSidebarPanel.sheetView),
          tooltip: 'Sheet View',
        ),
        SheetZoomControl(
          zoom: zoom,
          onChanged: controller.setZoom,
          onZoomOut: controller.zoomOut,
          onZoomIn: controller.zoomIn,
          onReset: controller.resetZoom,
        ),
      ],
    );
  }
}

class _FreezeMenuButton extends StatelessWidget {
  const _FreezeMenuButton({required this.controller, required this.selection});

  final ToolbarController controller;
  final CellSelection? selection;

  bool get _hasSelection => selection != null;

  @override
  Widget build(BuildContext context) {
    final actions = [
      SheetRibbonMenuAction(
        label: 'Freeze First Row',
        onSelected: controller.freezeFirstRow,
      ),
      SheetRibbonMenuAction(
        label: 'Freeze First Column',
        onSelected: controller.freezeFirstColumn,
      ),
      SheetRibbonMenuAction(
        label: 'Freeze First Row and Column',
        onSelected: controller.freezeFirstRowAndColumn,
      ),
      SheetRibbonMenuAction(
        label: 'Freeze at Selection',
        onSelected: _hasSelection
            ? () => controller.freezePanesAt(selection!)
            : null,
      ),
      SheetRibbonMenuAction(
        label: 'Unfreeze Panes',
        onSelected: controller.unfreezePanes,
      ),
    ];

    return SheetRibbonMenuButton(
      icon: Icons.view_week_outlined,
      tooltip: 'Freeze Panes',
      actions: actions,
    );
  }
}

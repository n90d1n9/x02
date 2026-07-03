import 'package:flutter/material.dart';

import '../model/cell/cell_selection.dart';
import '../state/toolbar_provider.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_menu_button.dart';

/// Insert/delete/hide/show structural ribbon commands for rows and columns.
class SheetRibbonStructureGroup extends StatelessWidget {
  const SheetRibbonStructureGroup({
    super.key,
    required this.controller,
    required this.selection,
  });

  final ToolbarController controller;
  final CellSelection? selection;

  bool get _hasSelection => selection != null;

  @override
  Widget build(BuildContext context) {
    return SheetRibbonCommandRow(
      children: [
        SheetRibbonMenuButton(
          icon: Icons.add_box,
          tooltip: 'Insert Rows',
          actions: [
            SheetRibbonMenuAction(
              label: 'Insert Row Above',
              onSelected: _hasSelection
                  ? () => controller.insertRowsAbove(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Insert Row Below',
              onSelected: _hasSelection
                  ? () => controller.insertRowsBelow(selection!)
                  : null,
            ),
          ],
        ),
        SheetRibbonMenuButton(
          icon: Icons.view_column,
          tooltip: 'Insert Columns',
          actions: [
            SheetRibbonMenuAction(
              label: 'Insert Column Left',
              onSelected: _hasSelection
                  ? () => controller.insertColumnsLeft(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Insert Column Right',
              onSelected: _hasSelection
                  ? () => controller.insertColumnsRight(selection!)
                  : null,
            ),
          ],
        ),
        SheetRibbonMenuButton(
          icon: Icons.delete,
          tooltip: 'Delete Rows/Columns',
          actions: [
            SheetRibbonMenuAction(
              label: 'Delete Rows',
              onSelected: _hasSelection
                  ? () => controller.deleteRows(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Delete Columns',
              onSelected: _hasSelection
                  ? () => controller.deleteColumns(selection!)
                  : null,
            ),
          ],
        ),
        SheetRibbonMenuButton(
          icon: Icons.visibility_off,
          tooltip: 'Hide/Show Rows/Columns',
          actions: [
            SheetRibbonMenuAction(
              label: 'Hide Rows',
              onSelected: _hasSelection
                  ? () => controller.hideRows(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Hide Columns',
              onSelected: _hasSelection
                  ? () => controller.hideColumns(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Show Rows',
              onSelected: _hasSelection
                  ? () => controller.showRows(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Show Columns',
              onSelected: _hasSelection
                  ? () => controller.showColumns(selection!)
                  : null,
            ),
          ],
        ),
        SheetRibbonMenuButton(
          icon: Icons.fit_screen,
          tooltip: 'Auto-fit Rows/Columns',
          actions: [
            SheetRibbonMenuAction(
              label: 'Auto-fit Row Height',
              onSelected: _hasSelection
                  ? () => controller.autoFitRow(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Auto-fit Column Width',
              onSelected: _hasSelection
                  ? () => controller.autoFitColumn(selection!)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

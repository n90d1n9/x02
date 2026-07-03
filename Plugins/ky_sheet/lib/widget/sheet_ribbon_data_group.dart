import 'package:flutter/material.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/toolbar_provider.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_menu_button.dart';
import 'sheet_ribbon_validation_dialogs.dart';
import 'tool_button.dart';

/// Data ribbon commands for search, validation, sorting, and filtering.
class SheetRibbonDataGroup extends StatelessWidget {
  const SheetRibbonDataGroup({
    super.key,
    required this.controller,
    required this.selection,
    this.activeTable,
    required this.onOpenPanel,
  });

  final ToolbarController controller;
  final CellSelection? selection;
  final SheetTable? activeTable;
  final ValueChanged<SheetSidebarPanel> onOpenPanel;

  bool get _hasSelection => selection != null;

  @override
  Widget build(BuildContext context) {
    return SheetRibbonCommandRow(
      children: [
        ToolButton(
          icon: Icons.search,
          onPressed: () => onOpenPanel(SheetSidebarPanel.findReplace),
          tooltip: 'Search',
        ),
        ToolButton(
          icon: Icons.find_replace,
          onPressed: () => onOpenPanel(SheetSidebarPanel.findReplace),
          tooltip: 'Find and Replace',
        ),
        ToolButton(
          icon: Icons.view_week_outlined,
          onPressed: _hasSelection
              ? () => controller.formatAsTable(selection!)
              : null,
          tooltip: 'Format as Table',
        ),
        ToolButton(
          icon: Icons.table_chart_outlined,
          onPressed: () => onOpenPanel(SheetSidebarPanel.tables),
          tooltip: 'Table Studio',
        ),
        SheetRibbonMenuButton(
          icon: Icons.rule,
          tooltip: 'Data Validation',
          actions: [
            SheetRibbonMenuAction(
              label: 'Required Field',
              onSelected: _hasSelection
                  ? () => controller.applyRequiredValidation(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Number Range',
              onSelected: _hasSelection
                  ? () => _showNumberValidationDialog(
                      context,
                      selection!,
                      controller,
                    )
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'List of Values',
              onSelected: _hasSelection
                  ? () => _showListValidationDialog(
                      context,
                      selection!,
                      controller,
                    )
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Email Address',
              onSelected: _hasSelection
                  ? () => controller.applyEmailValidation(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Clear Validation',
              onSelected: _hasSelection
                  ? () => controller.clearValidation(selection!)
                  : null,
            ),
          ],
        ),
        SheetRibbonMenuButton(
          icon: Icons.sort,
          tooltip: 'Sort',
          actions: [
            SheetRibbonMenuAction(
              label: 'Sort A to Z',
              onSelected: _hasSelection ? () => _sort(ascending: true) : null,
            ),
            SheetRibbonMenuAction(
              label: 'Sort Z to A',
              onSelected: _hasSelection ? () => _sort(ascending: false) : null,
            ),
          ],
        ),
        SheetRibbonMenuButton(
          icon: Icons.filter_alt,
          tooltip: 'Filters',
          actions: [
            SheetRibbonMenuAction(
              label: 'Apply Filter',
              onSelected: _hasSelection
                  ? () => controller.applyFilter(selection!)
                  : null,
            ),
            SheetRibbonMenuAction(
              label: 'Remove Filter',
              onSelected: _hasSelection
                  ? () => controller.removeFilter(selection!)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  void _showNumberValidationDialog(
    BuildContext context,
    CellSelection selection,
    ToolbarController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => SheetNumberValidationDialog(
        controller: controller,
        selection: selection,
      ),
    );
  }

  void _showListValidationDialog(
    BuildContext context,
    CellSelection selection,
    ToolbarController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => SheetListValidationDialog(
        controller: controller,
        selection: selection,
      ),
    );
  }

  void _sort({required bool ascending}) {
    final table = activeTable;
    final selected = selection;
    if (table != null && selected != null) {
      controller.sortTableColumn(
        table,
        selected.start.col,
        ascending: ascending,
      );
      return;
    }

    if (selected != null) {
      controller.sortSelection(selected, ascending: ascending);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/cell/cell_selection.dart';
import '../../model/conditional_format_rule.dart';
import '../../state/sheet_sidebar_provider.dart';
import '../../state/spreadsheet_provider.dart';
import '../../state/toolbar_provider.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_menu_button.dart';
import '../tool_button.dart';

/// Conditional Formatting ribbon commands for highlighting cells, data bars, color scales, and icon sets.
class SheetRibbonConditionalFormattingGroup extends ConsumerWidget {
  const SheetRibbonConditionalFormattingGroup({
    super.key,
    required this.controller,
    required this.selection,
    required this.onOpenPanel,
  });

  final ToolbarController controller;
  final CellSelection? selection;
  final ValueChanged<SheetSidebarPanel> onOpenPanel;

  bool get _hasSelection => selection != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetRibbonCommandRow(
      children: [
        _ConditionalFormattingMenuButton(
          selection: selection,
          controller: controller,
          onOpenPanel: onOpenPanel,
        ),
        ToolButton(
          icon: Icons.format_paint,
          onPressed: _hasSelection
              ? () => controller.clearConditionalFormats(selection!)
              : null,
          tooltip: 'Clear Conditional Formats',
        ),
        ToolButton(
          icon: Icons.manage_search,
          onPressed: () => onOpenPanel(SheetSidebarPanel.conditionalFormat),
          tooltip: 'Manage Rules',
        ),
      ],
    );
  }
}

class _ConditionalFormattingMenuButton extends StatelessWidget {
  const _ConditionalFormattingMenuButton({
    required this.selection,
    required this.controller,
    required this.onOpenPanel,
  });

  final CellSelection? selection;
  final ToolbarController controller;
  final ValueChanged<SheetSidebarPanel> onOpenPanel;

  bool get _hasSelection => selection != null;

  @override
  Widget build(BuildContext context) {
    return SheetRibbonMenuButton(
      icon: Icons.color_lens,
      tooltip: 'Conditional Formatting',
      actions: [
        SheetRibbonMenuAction(
          label: 'Highlight Cells Rules',
          onSelected: _hasSelection
              ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Top/Bottom Rules',
          onSelected: _hasSelection
              ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Data Bars',
          onSelected: _hasSelection
              ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Color Scales',
          onSelected: _hasSelection
              ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Icon Sets',
          onSelected: _hasSelection
              ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'New Rule...',
          onSelected: _hasSelection
              ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
              : null,
        ),
        SheetRibbonMenuAction(
          label: 'Clear Rules from Selected Cells',
          onSelected: _hasSelection
              ? () => controller.clearConditionalFormats(selection!)
              : null,
        ),
      ],
    );
  }

  SheetRibbonMenuAction _buildHighlightCellsMenu() {
    return SheetRibbonMenuAction(
      label: 'Highlight Cells Rules',
      onSelected: _hasSelection
          ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
          : null,
    );
  }

  SheetRibbonMenuAction _buildTopBottomMenu() {
    return SheetRibbonMenuAction(
      label: 'Top/Bottom Rules',
      onSelected: _hasSelection
          ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
          : null,
    );
  }

  SheetRibbonMenuAction _buildDataBarsMenu() {
    return SheetRibbonMenuAction(
      label: 'Data Bars',
      onSelected: _hasSelection
          ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
          : null,
    );
  }

  SheetRibbonMenuAction _buildGradientFillMenu() {
    return SheetRibbonMenuAction(
      label: 'Gradient Fill',
      onSelected: _hasSelection
          ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
          : null,
    );
  }

  SheetRibbonMenuAction _buildSolidFillMenu() {
    return SheetRibbonMenuAction(
      label: 'Solid Fill',
      onSelected: _hasSelection
          ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
          : null,
    );
  }

  Widget _buildDataBarPreview({required bool gradient}) {
    return Container(
      width: 60,
      height: 20,
      decoration: BoxDecoration(
        gradient: gradient
            ? LinearGradient(
                colors: [Colors.blue.shade300, Colors.blue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: gradient ? null : Colors.blue,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  SheetRibbonMenuAction _buildColorScalesMenu() {
    return SheetRibbonMenuAction(
      label: 'Color Scales',
      onSelected: _hasSelection
          ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
          : null,
    );
  }

  SheetRibbonMenuAction _buildIconSetsMenu() {
    return SheetRibbonMenuAction(
      label: 'Icon Sets',
      onSelected: _hasSelection
          ? () => onOpenPanel(SheetSidebarPanel.conditionalFormat)
          : null,
    );
  }

  Widget _buildColorScalePreview(List<Color> colors) {
    return Container(
      width: 60,
      height: 20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showConditionDialog(
    BuildContext context,
    ConditionalFormatCondition condition,
  ) {
    // This would open a dialog to configure the rule
    // For now, we apply a default preset
    _applyPresetRule(condition);
  }

  void _showTopBottomDialog(
    BuildContext context,
    TopBottomType type,
    bool isPercent,
  ) {
    // This would open a dialog to configure top/bottom rules
    // For now, apply default (top/bottom 10)
    _applyPresetRule(
      isPercent
          ? (type == TopBottomType.top
                ? ConditionalFormatCondition.topPercent
                : ConditionalFormatCondition.bottomPercent)
          : (type == TopBottomType.top
                ? ConditionalFormatCondition.topItems
                : ConditionalFormatCondition.bottomItems),
    );
  }

  void _applyPresetRule(ConditionalFormatCondition condition) {
    if (!_hasSelection) return;

    Color backgroundColor;
    Color textColor;

    switch (condition) {
      case ConditionalFormatCondition.greaterThan:
      case ConditionalFormatCondition.topItems:
      case ConditionalFormatCondition.topPercent:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      case ConditionalFormatCondition.lessThan:
      case ConditionalFormatCondition.bottomItems:
      case ConditionalFormatCondition.bottomPercent:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case ConditionalFormatCondition.between:
      case ConditionalFormatCondition.equalTo:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      case ConditionalFormatCondition.containsText:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        break;
      case ConditionalFormatCondition.dateOccurring:
        backgroundColor = Colors.teal.shade100;
        textColor = Colors.teal.shade900;
        break;
      case ConditionalFormatCondition.duplicateValues:
        backgroundColor = Colors.brown.shade100;
        textColor = Colors.brown.shade900;
        break;
      case ConditionalFormatCondition.aboveAverage:
        backgroundColor = Colors.lightBlue.shade100;
        textColor = Colors.lightBlue.shade900;
        break;
      case ConditionalFormatCondition.belowAverage:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      default:
        backgroundColor = Colors.yellow.shade100;
        textColor = Colors.black87;
    }

    controller.applyConditionalFormat(
      selection!,
      condition: condition,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }

  void _applyDataBar(Color color, {required bool gradient}) {
    if (!_hasSelection) return;
    controller.applyDataBarConditionalFormat(
      selection!,
      color: color,
      gradient: gradient,
    );
  }

  void _applyColorScale(List<Color> colors) {
    if (!_hasSelection) return;
    controller.applyColorScaleConditionalFormat(selection!, colors: colors);
  }

  void _applyIconSet(ConditionalFormatIconSet iconSet) {
    if (!_hasSelection) return;
    controller.applyIconSetConditionalFormat(selection!, iconSet: iconSet);
  }

  static const List<Color> _dataBarColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.lightBlue,
    Colors.purple,
  ];

  String _colorName(Color color) {
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.red) return 'Red';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.lightBlue) return 'Light Blue';
    if (color == Colors.purple) return 'Purple';
    return 'Custom';
  }
}

enum TopBottomType { top, bottom }

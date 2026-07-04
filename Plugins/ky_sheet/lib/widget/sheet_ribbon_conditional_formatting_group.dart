import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/conditional_format_rule.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_menu_button.dart';
import 'tool_button.dart';

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
        _buildHighlightCellsMenu(),
        const Divider(height: 1),
        _buildTopBottomMenu(),
        const Divider(height: 1),
        _buildDataBarsMenu(),
        _buildColorScalesMenu(),
        _buildIconSetsMenu(),
        const Divider(height: 1),
        PopupMenuItem(
          enabled: _hasSelection,
          onTap: () => onOpenPanel(SheetSidebarPanel.conditionalFormat),
          child: const Row(
            children: [
              Icon(Icons.rule, size: 18),
              SizedBox(width: 10),
              Text('New Rule...'),
            ],
          ),
        ),
        PopupMenuItem(
          enabled: _hasSelection,
          onTap: () => controller.clearConditionalFormats(selection!),
          child: const Row(
            children: [
              Icon(Icons.clear, size: 18),
              SizedBox(width: 10),
              Text('Clear Rules from Selected Cells'),
            ],
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildHighlightCellsMenu() {
    return PopupMenuItem<String>(
      enabled: _hasSelection,
      child: const Row(
        children: [
          Icon(Icons.highlight, size: 18),
          SizedBox(width: 10),
          Text('Highlight Cells Rules'),
        ],
      ),
      submenu: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.arrow_upward, size: 18, color: Colors.red),
            title: const Text('Greater Than...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showConditionDialog(
                    context,
                    ConditionalFormatCondition.greaterThan,
                  )
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.arrow_downward, size: 18, color: Colors.green),
            title: const Text('Less Than...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showConditionDialog(
                    context,
                    ConditionalFormatCondition.lessThan,
                  )
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.text_fields, size: 18, color: Colors.orange),
            title: const Text('Between...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showConditionDialog(
                    context,
                    ConditionalFormatCondition.between,
                  )
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.text_fields, size: 18, color: Colors.blue),
            title: const Text('Equal To...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showConditionDialog(
                    context,
                    ConditionalFormatCondition.equalTo,
                  )
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.text_format, size: 18, color: Colors.purple),
            title: const Text('Text that Contains...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showConditionDialog(
                    context,
                    ConditionalFormatCondition.containsText,
                  )
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
            title: const Text('A Date Occurring...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showConditionDialog(
                    context,
                    ConditionalFormatCondition.dateOccurring,
                  )
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.looks_one, size: 18, color: Colors.brown),
            title: const Text('Duplicate Values...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyPresetRule(
                    ConditionalFormatCondition.duplicateValues,
                  )
              : null,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildTopBottomMenu() {
    return PopupMenuItem<String>(
      enabled: _hasSelection,
      child: const Row(
        children: [
          Icon(Icons.leaderboard, size: 18),
          SizedBox(width: 10),
          Text('Top/Bottom Rules'),
        ],
      ),
      submenu: [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.trending_up, size: 18, color: Colors.red),
            title: const Text('Top 10 Items...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showTopBottomDialog(context, TopBottomType.top, false)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.trending_up, size: 18, color: Colors.orange),
            title: const Text('Top 10%...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showTopBottomDialog(context, TopBottomType.top, true)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.trending_down, size: 18, color: Colors.green),
            title: const Text('Bottom 10 Items...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showTopBottomDialog(context, TopBottomType.bottom, false)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.trending_down, size: 18, color: Colors.lightGreen),
            title: const Text('Bottom 10%...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _showTopBottomDialog(context, TopBottomType.bottom, true)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.bar_chart, size: 18, color: Colors.blue),
            title: const Text('Above Average...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyPresetRule(ConditionalFormatCondition.aboveAverage)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.bar_chart, size: 18, color: Colors.lightBlue),
            title: const Text('Below Average...'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyPresetRule(ConditionalFormatCondition.belowAverage)
              : null,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildDataBarsMenu() {
    return PopupMenuItem<String>(
      enabled: _hasSelection,
      child: const Row(
        children: [
          Icon(Icons.waterfall_chart, size: 18),
          SizedBox(width: 10),
          Text('Data Bars'),
        ],
      ),
      submenu: [
        _buildGradientFillMenu(),
        _buildSolidFillMenu(),
      ],
    );
  }

  PopupMenuItem<String> _buildGradientFillMenu() {
    return PopupMenuItem<String>(
      enabled: _hasSelection,
      child: ListTile(
        leading: _buildDataBarPreview(gradient: true),
        title: const Text('Gradient Fill'),
        subtitle: const Text('Blue, Green, Red, Orange, Light Blue, Purple'),
        dense: true,
      ),
      submenu: [
        for (final color in _dataBarColors)
          PopupMenuItem(
            child: ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: color,
              ),
              title: Text(_colorName(color)),
              dense: true,
            ),
            onTap: _hasSelection
                ? () => _applyDataBar(color, gradient: true)
                : null,
          ),
      ],
    );
  }

  PopupMenuItem<String> _buildSolidFillMenu() {
    return PopupMenuItem<String>(
      enabled: _hasSelection,
      child: ListTile(
        leading: _buildDataBarPreview(gradient: false),
        title: const Text('Solid Fill'),
        subtitle: const Text('Blue, Green, Red, Orange, Light Blue, Purple'),
        dense: true,
      ),
      submenu: [
        for (final color in _dataBarColors)
          PopupMenuItem(
            child: ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: color,
              ),
              title: Text(_colorName(color)),
              dense: true,
            ),
            onTap: _hasSelection
                ? () => _applyDataBar(color, gradient: false)
                : null,
          ),
      ],
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

  PopupMenuItem<String> _buildColorScalesMenu() {
    return PopupMenuItem<String>(
      enabled: _hasSelection,
      child: const Row(
        children: [
          Icon(Icons.gradient, size: 18),
          SizedBox(width: 10),
          Text('Color Scales'),
        ],
      ),
      submenu: [
        PopupMenuItem(
          child: ListTile(
            leading: _buildColorScalePreview([Colors.red, Colors.yellow, Colors.green]),
            title: const Text('Green - Yellow - Red'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyColorScale([Colors.green, Colors.yellow, Colors.red])
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: _buildColorScalePreview([Colors.red, Colors.yellow, Colors.blue]),
            title: const Text('Red - Yellow - Green'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyColorScale([Colors.red, Colors.yellow, Colors.green])
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: _buildColorScalePreview([Colors.green, Colors.white]),
            title: const Text('Green - White'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyColorScale([Colors.green, Colors.white])
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: _buildColorScalePreview([Colors.red, Colors.white]),
            title: const Text('Red - White'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyColorScale([Colors.red, Colors.white])
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: _buildColorScalePreview([Colors.blue, Colors.white, Colors.red]),
            title: const Text('Blue - White - Red'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyColorScale([Colors.blue, Colors.white, Colors.red])
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: _buildColorScalePreview([Colors.white, Colors.red]),
            title: const Text('White - Red'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyColorScale([Colors.white, Colors.red])
              : null,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildIconSetsMenu() {
    return PopupMenuItem<String>(
      enabled: _hasSelection,
      child: const Row(
        children: [
          Icon(Icons.flag, size: 18),
          SizedBox(width: 10),
          Text('Icon Sets'),
        ],
      ),
      submenu: [
        PopupMenuItem(
          child: ListTile(
            leading: const Row(
              children: [
                Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Icon(Icons.remove, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Icon(Icons.arrow_downward, size: 16, color: Colors.red),
              ],
            ),
            title: const Text('Directional Arrows'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyIconSet(ConditionalFormatIconSet.directionalArrows)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Row(
              children: [
                Icon(Icons.circle, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Icon(Icons.circle, size: 16, color: Colors.yellow),
                SizedBox(width: 4),
                Icon(Icons.circle, size: 16, color: Colors.red),
              ],
            ),
            title: const Text('Traffic Lights'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyIconSet(ConditionalFormatIconSet.trafficLights)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                SizedBox(width: 4),
                Icon(Icons.star_border, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Icon(Icons.star_border, size: 16, color: Colors.grey),
              ],
            ),
            title: const Text('Rating Stars'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyIconSet(ConditionalFormatIconSet.ratingStars)
              : null,
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Row(
              children: [
                Icon(Icons.sentiment_very_satisfied, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Icon(Icons.sentiment_neutral, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Icon(Icons.sentiment_dissatisfied, size: 16, color: Colors.red),
              ],
            ),
            title: const Text('Emoticons'),
            dense: true,
          ),
          onTap: _hasSelection
              ? () => _applyIconSet(ConditionalFormatIconSet.emoticons)
              : null,
        ),
      ],
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

import 'package:flutter/material.dart';

import '../model/workbook_sheet.dart';
import 'status_metric_chip.dart';
import 'workbook_sheet_menu_item.dart';

/// Status bar chip that opens a lightweight workbook sheet switcher.
class StatusSheetSwitcherChip extends StatelessWidget {
  const StatusSheetSwitcherChip({
    super.key,
    required this.value,
    required this.tooltip,
    required this.sheets,
    required this.activeSheetId,
    required this.onSelected,
  });

  /// Compact active sheet position label.
  final String value;

  /// Tooltip describing the active sheet.
  final String tooltip;

  /// Sheets available in the current workbook.
  final List<WorkbookSheet> sheets;

  /// Currently active workbook sheet id.
  final String activeSheetId;

  /// Called when the user chooses a different sheet.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleSheets = [
      for (final sheet in sheets)
        if (!sheet.hidden) sheet,
    ];

    return PopupMenuButton<String>(
      key: const ValueKey('ky-sheet-status-sheet-switcher'),
      tooltip: tooltip,
      enabled: visibleSheets.isNotEmpty,
      offset: const Offset(0, 30),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final entry in visibleSheets.indexed)
          PopupMenuItem(
            key: ValueKey('ky-sheet-status-sheet-${entry.$2.id}'),
            value: entry.$2.id,
            child: WorkbookSheetMenuItem(
              name: entry.$2.name,
              active: entry.$2.id == activeSheetId,
              indexLabel: '${entry.$1 + 1}',
              tabColor: entry.$2.tabColor,
            ),
          ),
      ],
      child: StatusMetricChip(
        label: 'Sheet',
        value: value,
        icon: Icons.table_chart_outlined,
      ),
    );
  }
}

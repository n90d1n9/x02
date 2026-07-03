import 'package:flutter/material.dart';

import '../model/workbook_sheet.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_navigator_dialog.dart';

/// Footer button that opens the workbook's sheet navigator menu.
class SheetTabsNavigatorButton extends StatelessWidget {
  const SheetTabsNavigatorButton({
    super.key,
    required this.sheets,
    required this.activeSheetId,
    this.recentSheetIds = const [],
    required this.onSelected,
    required this.onUnhide,
  });

  final List<WorkbookSheet> sheets;
  final String activeSheetId;
  final List<String> recentSheetIds;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onUnhide;

  @override
  Widget build(BuildContext context) {
    final visibleSheets = [
      for (final sheet in sheets)
        if (!sheet.hidden) sheet,
    ];
    final hiddenSheetCount = sheets.length - visibleSheets.length;
    final sheetCount = visibleSheets.length;
    final activeIndex = visibleSheets.indexWhere(
      (sheet) => sheet.id == activeSheetId,
    );
    final activeSheetName = activeIndex == -1
        ? 'sheet'
        : visibleSheets[activeIndex].name;
    final tooltip = _tooltip(
      activeSheetName: activeSheetName,
      visibleSheetCount: sheetCount,
      hiddenSheetCount: hiddenSheetCount,
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('ky-sheet-tabs-navigator'),
          borderRadius: BorderRadius.circular(8),
          onTap: visibleSheets.isEmpty ? null : () => _openNavigator(context),
          child: Container(
            key: const ValueKey('ky-sheet-tabs-navigator-surface'),
            height: 32,
            constraints: const BoxConstraints(minWidth: 46),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KySheetColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: KySheetColors.gridLineStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.expand_circle_down_outlined,
                  size: 18,
                  color: KySheetColors.mutedText,
                ),
                if (sheetCount > 1) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$sheetCount',
                    key: const ValueKey('ky-sheet-tabs-navigator-count'),
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNavigator(BuildContext context) async {
    final result = await showDialog<SheetNavigatorDialogResult>(
      context: context,
      builder: (context) => SheetNavigatorDialog(
        sheets: sheets,
        activeSheetId: activeSheetId,
        recentSheetIds: recentSheetIds,
      ),
    );

    if (result == null) return;
    switch (result.action) {
      case SheetNavigatorDialogAction.select:
        onSelected(result.sheetId);
      case SheetNavigatorDialogAction.unhideAndSelect:
        onUnhide(result.sheetId);
    }
  }

  String _tooltip({
    required String activeSheetName,
    required int visibleSheetCount,
    required int hiddenSheetCount,
  }) {
    if (hiddenSheetCount > 0) {
      return 'All Sheets: $visibleSheetCount visible, $hiddenSheetCount hidden';
    }

    return visibleSheetCount == 1
        ? 'All Sheets: $activeSheetName'
        : 'All Sheets: $visibleSheetCount sheets';
  }
}

import 'package:flutter/material.dart';

import '../model/workbook_sheet.dart';
import '../theme/ky_sheet_theme.dart';
import 'workbook_sheet_menu_item.dart';

/// Navigator row for a sheet hidden from the workbook tab strip.
class SheetHiddenSheetRow extends StatelessWidget {
  const SheetHiddenSheetRow({
    super.key,
    required this.sheet,
    required this.position,
    required this.onUnhide,
  });

  /// Hidden workbook sheet represented by this row.
  final WorkbookSheet sheet;

  /// Zero-based sheet position in the full workbook.
  final int position;

  /// Called when the hidden sheet should be restored.
  final VoidCallback onUnhide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: 0.72,
              child: WorkbookSheetMenuItem(
                name: sheet.name,
                active: false,
                indexLabel: '${position + 1}',
                tabColor: sheet.tabColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: ValueKey('ky-sheet-hidden-unhide-${sheet.id}'),
            onPressed: onUnhide,
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text('Unhide'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: KySheetColors.accent,
              side: const BorderSide(color: KySheetColors.gridLineStrong),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

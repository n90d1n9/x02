import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

/// Compact section label for popup menus with grouped spreadsheet actions.
class SheetMenuSectionLabel extends StatelessWidget {
  const SheetMenuSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: KySheetColors.mutedText,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

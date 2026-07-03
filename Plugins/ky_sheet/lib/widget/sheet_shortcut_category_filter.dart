import 'package:flutter/material.dart';

import '../model/sheet_shortcut.dart';
import '../theme/ky_sheet_theme.dart';

/// Segmented category filter used by the shortcut guide sidebar.
class SheetShortcutCategoryFilter extends StatelessWidget {
  const SheetShortcutCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final SheetShortcutCategory? selectedCategory;
  final ValueChanged<SheetShortcutCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SheetShortcutCategory?>(
      key: const ValueKey('ky-sheet-shortcut-category-filter'),
      segments: [
        const ButtonSegment<SheetShortcutCategory?>(
          value: null,
          label: Text('All', key: ValueKey('ky-sheet-shortcut-category-all')),
        ),
        for (final category in SheetShortcutCategory.values)
          ButtonSegment<SheetShortcutCategory?>(
            value: category,
            label: Text(
              _compactLabel(category),
              key: ValueKey('ky-sheet-shortcut-category-${category.name}'),
            ),
          ),
      ],
      selected: {selectedCategory},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        minimumSize: WidgetStateProperty.all(const Size(0, 32)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 9),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return KySheetColors.mutedText;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return KySheetColors.accent;
          }
          return KySheetColors.surfaceMuted;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.selected)
                ? KySheetColors.accent
                : KySheetColors.gridLine,
          );
        }),
      ),
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }

  static String _compactLabel(SheetShortcutCategory category) {
    return switch (category) {
      SheetShortcutCategory.editing => 'Edit',
      SheetShortcutCategory.navigation => 'Nav',
      SheetShortcutCategory.sheets => 'Sheets',
      SheetShortcutCategory.tools => 'Tools',
    };
  }
}

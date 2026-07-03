import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

/// Labeled color choice used by sheet tab color surfaces.
class SheetTabColorOption {
  const SheetTabColorOption({required this.label, required this.color});

  /// User-facing color label for tooltips and semantics.
  final String label;

  /// Color applied to a workbook sheet tab.
  final Color color;

  String get keySuffix => label.toLowerCase().replaceAll(' ', '-');
}

/// Compact swatch picker for assigning a workbook sheet tab color.
class SheetTabColorPicker extends StatelessWidget {
  const SheetTabColorPicker({
    super.key,
    this.currentColor,
    this.options = defaultOptions,
    required this.onSelected,
  });

  /// Balanced palette used by the sheet tab color dialog.
  static const defaultOptions = [
    SheetTabColorOption(label: 'Blue', color: Color(0xFF2563EB)),
    SheetTabColorOption(label: 'Green', color: Color(0xFF16A34A)),
    SheetTabColorOption(label: 'Amber', color: Color(0xFFF59E0B)),
    SheetTabColorOption(label: 'Red', color: Color(0xFFDC2626)),
    SheetTabColorOption(label: 'Cyan', color: Color(0xFF0891B2)),
    SheetTabColorOption(label: 'Purple', color: Color(0xFF7C3AED)),
    SheetTabColorOption(label: 'Pink', color: Color(0xFFDB2777)),
    SheetTabColorOption(label: 'Slate', color: Color(0xFF475569)),
  ];

  /// Currently applied sheet tab color.
  final Color? currentColor;

  /// Color options shown in the picker.
  final List<SheetTabColorOption> options;

  /// Called when the user chooses a color, or null to clear it.
  final ValueChanged<Color?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SheetTabColorClearButton(
          selected: currentColor == null,
          onSelected: () => onSelected(null),
        ),
        for (final option in options)
          _SheetTabColorSwatchButton(
            option: option,
            selected: _sameColor(currentColor, option.color),
            onSelected: () => onSelected(option.color),
          ),
      ],
    );
  }

  bool _sameColor(Color? first, Color second) {
    return first?.toARGB32() == second.toARGB32();
  }
}

/// Icon button that clears the current sheet tab color.
class _SheetTabColorClearButton extends StatelessWidget {
  const _SheetTabColorClearButton({
    required this.selected,
    required this.onSelected,
  });

  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'No Color',
      child: Semantics(
        button: true,
        selected: selected,
        label: 'No Color',
        child: InkWell(
          key: const ValueKey('ky-sheet-tab-color-none'),
          onTap: onSelected,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? KySheetColors.accentSoft
                  : KySheetColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? KySheetColors.accent
                    : KySheetColors.gridLineStrong,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              selected ? Icons.check : Icons.format_color_reset_outlined,
              size: 18,
              color: selected ? KySheetColors.accent : KySheetColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Color swatch button that marks the active sheet tab color.
class _SheetTabColorSwatchButton extends StatelessWidget {
  const _SheetTabColorSwatchButton({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final SheetTabColorOption option;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: option.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${option.label} tab color',
        child: InkWell(
          key: ValueKey('ky-sheet-tab-color-${option.keySuffix}'),
          onTap: onSelected,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: option.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? KySheetColors.text : KySheetColors.gridLine,
                width: selected ? 2 : 1,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    size: 18,
                    color: _foregroundFor(option.color),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Color _foregroundFor(Color color) {
    return color.computeLuminance() > 0.45 ? KySheetColors.text : Colors.white;
  }
}

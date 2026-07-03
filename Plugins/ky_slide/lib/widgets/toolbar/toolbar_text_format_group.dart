import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/rich_text_content.dart';
import 'ribbon_menu_button.dart';
import 'ribbon_toggle_button.dart';
import 'toolbar_color_menu_button.dart';
import 'toolbar_text_typography_menus.dart';

/// Contextual ribbon group for selected text component formatting.
class ToolbarTextFormatGroup extends StatelessWidget {
  static const _fontSizes = [12.0, 16.0, 20.0, 24.0, 32.0, 44.0, 56.0];

  final RichTextContent richText;
  final List<Color> colors;
  final bool enabled;
  final bool compact;
  final Color accentColor;
  final ValueChanged<Color> onTextColorSelected;
  final ValueChanged<Color> onTextHighlightSelected;
  final VoidCallback onTextHighlightCleared;
  final ValueChanged<String> onFontFamilySelected;
  final ValueChanged<double> onFontSizeSelected;
  final ValueChanged<double> onLineHeightSelected;
  final ValueChanged<double> onLetterSpacingSelected;
  final ValueChanged<bool> onBoldChanged;
  final ValueChanged<bool> onItalicChanged;
  final ValueChanged<bool> onUnderlineChanged;
  final ValueChanged<bool> onStrikethroughChanged;
  final ValueChanged<TextAlign> onAlignmentSelected;

  const ToolbarTextFormatGroup({
    super.key,
    required this.richText,
    required this.colors,
    required this.onTextColorSelected,
    required this.onTextHighlightSelected,
    required this.onTextHighlightCleared,
    required this.onFontFamilySelected,
    required this.onFontSizeSelected,
    required this.onLineHeightSelected,
    required this.onLetterSpacingSelected,
    required this.onBoldChanged,
    required this.onItalicChanged,
    required this.onUnderlineChanged,
    required this.onStrikethroughChanged,
    required this.onAlignmentSelected,
    this.enabled = true,
    this.compact = false,
    this.accentColor = const Color(0xFF38BDF8),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarColorMenuButton(
          icon: Icons.format_color_text,
          tooltip: 'Text Color',
          menuLabelPrefix: 'Text',
          colors: _colorChoices(),
          selectedColor: richText.style.color,
          enabled: enabled,
          compact: compact,
          onSelected: onTextColorSelected,
        ),
        ToolbarColorMenuButton(
          icon: Icons.border_color,
          tooltip: 'Text Highlight',
          menuLabelPrefix: 'Highlight',
          colors: _highlightChoices(),
          selectedColor: richText.style.backgroundColor,
          enabled: enabled,
          compact: compact,
          onSelected: onTextHighlightSelected,
          onCleared: onTextHighlightCleared,
          clearLabel: 'No Highlight',
        ),
        ToolbarFontFamilyMenu(
          selectedFamily: richText.style.fontFamily,
          enabled: enabled,
          compact: compact,
          onSelected: onFontFamilySelected,
        ),
        RibbonMenuButton<double>(
          icon: Icons.format_size,
          tooltip: 'Text Size',
          enabled: enabled,
          compact: compact,
          onSelected: onFontSizeSelected,
          itemBuilder: (context) => [
            for (final size in _fontSizes)
              PopupMenuItem(
                value: size,
                child: _TextMenuRow(
                  icon: Icons.format_size,
                  label: size.toStringAsFixed(0),
                  selected:
                      ((richText.style.fontSize ?? 0) - size).abs() <
                      _precisionTolerance,
                ),
              ),
          ],
        ),
        ToolbarLineHeightMenu(
          selectedLineHeight: richText.style.height,
          enabled: enabled,
          compact: compact,
          onSelected: onLineHeightSelected,
        ),
        ToolbarLetterSpacingMenu(
          selectedLetterSpacing: richText.style.letterSpacing,
          enabled: enabled,
          compact: compact,
          onSelected: onLetterSpacingSelected,
        ),
        RibbonToggleButton(
          activeIcon: Icons.format_bold,
          inactiveIcon: Icons.format_bold,
          tooltip: richText.isBold ? 'Remove Bold' : 'Bold',
          isActive: richText.isBold,
          onPressed: enabled ? () => onBoldChanged(!richText.isBold) : null,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonToggleButton(
          activeIcon: Icons.format_italic,
          inactiveIcon: Icons.format_italic,
          tooltip: richText.isItalic ? 'Remove Italic' : 'Italic',
          isActive: richText.isItalic,
          onPressed: enabled ? () => onItalicChanged(!richText.isItalic) : null,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonToggleButton(
          activeIcon: Icons.format_underlined,
          inactiveIcon: Icons.format_underlined,
          tooltip: richText.isUnderline ? 'Remove Underline' : 'Underline',
          isActive: richText.isUnderline,
          onPressed: enabled
              ? () => onUnderlineChanged(!richText.isUnderline)
              : null,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonToggleButton(
          activeIcon: Icons.format_strikethrough,
          inactiveIcon: Icons.format_strikethrough,
          tooltip: richText.isStrikethrough
              ? 'Remove Strikethrough'
              : 'Strikethrough',
          isActive: richText.isStrikethrough,
          onPressed: enabled
              ? () => onStrikethroughChanged(!richText.isStrikethrough)
              : null,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonMenuButton<TextAlign>(
          icon: _alignmentIcon(richText.alignment),
          tooltip: 'Text Alignment',
          enabled: enabled,
          compact: compact,
          onSelected: onAlignmentSelected,
          itemBuilder: (context) => [
            _alignmentItem(TextAlign.left, Icons.format_align_left, 'Left'),
            _alignmentItem(
              TextAlign.center,
              Icons.format_align_center,
              'Center',
            ),
            _alignmentItem(TextAlign.right, Icons.format_align_right, 'Right'),
            _alignmentItem(
              TextAlign.justify,
              Icons.format_align_justify,
              'Justify',
            ),
          ],
        ),
      ],
    );
  }

  List<Color> _colorChoices() {
    final seeded = <Color>[
      ?richText.style.color,
      ...colors,
      const Color(0xFFFFFFFF),
      const Color(0xFF0F172A),
    ];
    final seen = <int>{};

    return [
      for (final color in seeded)
        if (seen.add(color.toARGB32())) color,
    ].take(8).toList();
  }

  List<Color> _highlightChoices() {
    final seeded = <Color>[
      ?richText.style.backgroundColor,
      const Color(0xFFFFF3BF),
      const Color(0xFFBBF7D0),
      const Color(0xFFBAE6FD),
      const Color(0xFFFECACA),
      const Color(0xFFEDE9FE),
    ];
    final seen = <int>{};

    return [
      for (final color in seeded)
        if (seen.add(color.toARGB32())) color,
    ];
  }

  IconData _alignmentIcon(TextAlign alignment) {
    return switch (alignment) {
      TextAlign.center => Icons.format_align_center,
      TextAlign.right || TextAlign.end => Icons.format_align_right,
      TextAlign.justify => Icons.format_align_justify,
      _ => Icons.format_align_left,
    };
  }

  PopupMenuItem<TextAlign> _alignmentItem(
    TextAlign alignment,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: alignment,
      child: _TextMenuRow(
        icon: icon,
        label: label,
        selected: richText.alignment == alignment,
      ),
    );
  }
}

const _precisionTolerance = 0.001;

/// Popup menu row for text formatting values.
class _TextMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _TextMenuRow({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle : icon,
          color: selected ? const Color(0xFF38BDF8) : Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Toolbar text format group', size: Size(520, 88))
Widget toolbarTextFormatGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarTextFormatGroup(
          richText: RichTextContent(
            text: 'Quarterly update',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontFamily: 'Inter',
              fontSize: 24,
              height: 1.3,
              letterSpacing: 0.5,
              backgroundColor: Color(0xFFFFF3BF),
            ),
            isBold: true,
            isStrikethrough: true,
            alignment: TextAlign.center,
          ),
          colors: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
          onTextColorSelected: (_) {},
          onTextHighlightSelected: (_) {},
          onTextHighlightCleared: () {},
          onFontFamilySelected: (_) {},
          onFontSizeSelected: (_) {},
          onLineHeightSelected: (_) {},
          onLetterSpacingSelected: (_) {},
          onBoldChanged: (_) {},
          onItalicChanged: (_) {},
          onUnderlineChanged: (_) {},
          onStrikethroughChanged: (_) {},
          onAlignmentSelected: (_) {},
        ),
      ),
    ),
  );
}

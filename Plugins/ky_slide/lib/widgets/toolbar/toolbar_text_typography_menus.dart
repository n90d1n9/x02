import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'ribbon_menu_button.dart';

/// Font family chooser for text objects in the contextual ribbon.
class ToolbarFontFamilyMenu extends StatelessWidget {
  static const defaultFamilies = [
    'Aptos',
    'Inter',
    'Poppins',
    'Roboto',
    'Georgia',
    'Courier New',
  ];

  final String? selectedFamily;
  final List<String> families;
  final bool enabled;
  final bool compact;
  final ValueChanged<String> onSelected;

  const ToolbarFontFamilyMenu({
    super.key,
    required this.selectedFamily,
    required this.onSelected,
    this.families = defaultFamilies,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return RibbonMenuButton<String>(
      icon: Icons.font_download_outlined,
      tooltip: 'Font Family',
      enabled: enabled,
      compact: compact,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final family in _familyChoices())
          PopupMenuItem(
            value: family,
            child: _TypographyMenuRow(
              icon: Icons.text_fields,
              label: family,
              selected: family == selectedFamily,
              previewStyle: TextStyle(fontFamily: family),
            ),
          ),
      ],
    );
  }

  List<String> _familyChoices() {
    final seeded = <String>[?selectedFamily, ...families];
    final seen = <String>{};

    return [
      for (final family in seeded)
        if (seen.add(family)) family,
    ];
  }
}

/// Line spacing chooser for text objects in the contextual ribbon.
class ToolbarLineHeightMenu extends StatelessWidget {
  static const defaultLineHeights = [1.0, 1.15, 1.3, 1.5, 1.75, 2.0];

  final double? selectedLineHeight;
  final List<double> lineHeights;
  final bool enabled;
  final bool compact;
  final ValueChanged<double> onSelected;

  const ToolbarLineHeightMenu({
    super.key,
    required this.selectedLineHeight,
    required this.onSelected,
    this.lineHeights = defaultLineHeights,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return RibbonMenuButton<double>(
      icon: Icons.format_line_spacing,
      tooltip: 'Line Spacing',
      enabled: enabled,
      compact: compact,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final lineHeight in _lineHeightChoices())
          PopupMenuItem(
            value: lineHeight,
            child: _TypographyMenuRow(
              icon: Icons.format_line_spacing,
              label: _lineHeightLabel(lineHeight),
              selected:
                  ((selectedLineHeight ?? 1.0) - lineHeight).abs() <
                  _precisionTolerance,
            ),
          ),
      ],
    );
  }

  List<double> _lineHeightChoices() {
    final seeded = <double>[?selectedLineHeight, ...lineHeights];
    final seen = <String>{};

    return [
      for (final lineHeight in seeded)
        if (seen.add(lineHeight.toStringAsFixed(2))) lineHeight,
    ];
  }

  String _lineHeightLabel(double lineHeight) {
    if ((lineHeight - 1.0).abs() < _precisionTolerance) return 'Single';
    final label = lineHeight
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '${label}x';
  }
}

/// Character spacing chooser for selected text objects in the contextual ribbon.
class ToolbarLetterSpacingMenu extends StatelessWidget {
  static const defaultLetterSpacings = [-0.5, 0.0, 0.5, 1.5, 3.0];

  final double? selectedLetterSpacing;
  final List<double> letterSpacings;
  final bool enabled;
  final bool compact;
  final ValueChanged<double> onSelected;

  const ToolbarLetterSpacingMenu({
    super.key,
    required this.selectedLetterSpacing,
    required this.onSelected,
    this.letterSpacings = defaultLetterSpacings,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return RibbonMenuButton<double>(
      icon: Icons.format_textdirection_l_to_r,
      tooltip: 'Character Spacing',
      enabled: enabled,
      compact: compact,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final letterSpacing in _letterSpacingChoices())
          PopupMenuItem(
            value: letterSpacing,
            child: _TypographyMenuRow(
              icon: Icons.format_textdirection_l_to_r,
              label: _letterSpacingLabel(letterSpacing),
              selected:
                  ((selectedLetterSpacing ?? 0.0) - letterSpacing).abs() <
                  _precisionTolerance,
            ),
          ),
      ],
    );
  }

  List<double> _letterSpacingChoices() {
    final seeded = <double>[?selectedLetterSpacing, ...letterSpacings];
    final seen = <String>{};

    return [
      for (final letterSpacing in seeded)
        if (seen.add(letterSpacing.toStringAsFixed(2))) letterSpacing,
    ];
  }

  String _letterSpacingLabel(double letterSpacing) {
    if (letterSpacing.abs() < _precisionTolerance) return 'Normal';
    if (letterSpacing < 0) return 'Tight';

    final label = letterSpacing
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '$label pt';
  }
}

const _precisionTolerance = 0.001;

/// Popup menu row for typography choices with an optional font preview.
class _TypographyMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final TextStyle? previewStyle;

  const _TypographyMenuRow({
    required this.icon,
    required this.label,
    required this.selected,
    this.previewStyle,
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
          style:
              previewStyle?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ) ??
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

@Preview(name: 'Toolbar font family menu', size: Size(120, 88))
Widget toolbarFontFamilyMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarFontFamilyMenu(
          selectedFamily: 'Inter',
          onSelected: (_) {},
        ),
      ),
    ),
  );
}

@Preview(name: 'Toolbar line height menu', size: Size(120, 88))
Widget toolbarLineHeightMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarLineHeightMenu(
          selectedLineHeight: 1.3,
          onSelected: (_) {},
        ),
      ),
    ),
  );
}

@Preview(name: 'Toolbar letter spacing menu', size: Size(120, 88))
Widget toolbarLetterSpacingMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarLetterSpacingMenu(
          selectedLetterSpacing: 0.5,
          onSelected: (_) {},
        ),
      ),
    ),
  );
}

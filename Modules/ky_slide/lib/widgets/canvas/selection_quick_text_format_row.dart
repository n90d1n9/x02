import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/rich_text_content.dart';
import '../../models/selection_quick_format_action.dart';
import '../../models/text_style_preset.dart';

/// Compact text styling controls shown inside the selected-object quick menu.
class SelectionQuickTextFormatRow extends StatelessWidget {
  static const List<String> _fontFamilies = [
    'Aptos',
    'Inter',
    'Poppins',
    'Georgia',
  ];
  static const List<double> _fontSizes = [16, 24, 32, 44];
  static const List<double> _lineHeights = [1, 1.15, 1.3, 1.5];
  static const List<double> _letterSpacings = [-0.5, 0, 0.5, 1.5, 3];

  final RichTextContent richText;
  final List<Color> colors;
  final TextStylePreset? selectedPreset;
  final ValueChanged<SelectionQuickFormatAction> onSelected;

  const SelectionQuickTextFormatRow({
    super.key,
    required this.richText,
    required this.colors,
    required this.onSelected,
    this.selectedPreset,
  });

  @override
  Widget build(BuildContext context) {
    final fontFamilies = _fontFamilyChoices();
    final textColors = _textColors();
    final highlightColors = _highlightColors();
    final lineHeights = _lineHeightChoices();
    final letterSpacings = _letterSpacingChoices();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in TextStylePreset.values)
              _QuickTextPresetButton(
                preset: preset,
                selected: selectedPreset == preset,
                onPressed: () {
                  onSelected(SelectionQuickFormatAction.textPreset(preset));
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _QuickTextIconButton(
              icon: Icons.format_bold,
              tooltip: richText.isBold ? 'Remove bold' : 'Bold text',
              selected: richText.isBold,
              onPressed: () {
                onSelected(
                  SelectionQuickFormatAction.textBold(!richText.isBold),
                );
              },
            ),
            _QuickTextIconButton(
              icon: Icons.format_italic,
              tooltip: richText.isItalic ? 'Remove italic' : 'Italic text',
              selected: richText.isItalic,
              onPressed: () {
                onSelected(
                  SelectionQuickFormatAction.textItalic(!richText.isItalic),
                );
              },
            ),
            _QuickTextIconButton(
              icon: Icons.format_underlined,
              tooltip: richText.isUnderline
                  ? 'Remove underline'
                  : 'Underline text',
              selected: richText.isUnderline,
              onPressed: () {
                onSelected(
                  SelectionQuickFormatAction.textUnderline(
                    !richText.isUnderline,
                  ),
                );
              },
            ),
            _QuickTextIconButton(
              icon: Icons.format_strikethrough,
              tooltip: richText.isStrikethrough
                  ? 'Remove strikethrough'
                  : 'Strikethrough text',
              selected: richText.isStrikethrough,
              onPressed: () {
                onSelected(
                  SelectionQuickFormatAction.textStrikethrough(
                    !richText.isStrikethrough,
                  ),
                );
              },
            ),
            for (final alignment in _alignments)
              _QuickTextIconButton(
                icon: _alignmentIcon(alignment),
                tooltip: '${_alignmentLabel(alignment)} align text',
                selected: richText.alignment == alignment,
                onPressed: () {
                  onSelected(
                    SelectionQuickFormatAction.textAlignment(alignment),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final letterSpacing in letterSpacings)
              _QuickTextLetterSpacingButton(
                letterSpacing: letterSpacing,
                selected:
                    ((richText.style.letterSpacing ?? 0) - letterSpacing)
                        .abs() <
                    0.001,
                onPressed: () {
                  onSelected(
                    SelectionQuickFormatAction.textLetterSpacing(letterSpacing),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final family in fontFamilies)
              _QuickTextFontFamilyButton(
                family: family,
                selected: richText.style.fontFamily == family,
                onPressed: () {
                  onSelected(SelectionQuickFormatAction.textFontFamily(family));
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final size in _fontSizes)
              _QuickTextSizeButton(
                size: size,
                selected: ((richText.style.fontSize ?? 0) - size).abs() < 0.001,
                onPressed: () {
                  onSelected(SelectionQuickFormatAction.textFontSize(size));
                },
              ),
            for (final lineHeight in lineHeights)
              _QuickTextLineHeightButton(
                lineHeight: lineHeight,
                selected:
                    ((richText.style.height ?? 1.0) - lineHeight).abs() < 0.001,
                onPressed: () {
                  onSelected(
                    SelectionQuickFormatAction.textLineHeight(lineHeight),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final color in textColors)
              _QuickTextColorButton(
                color: color,
                selected: richText.style.color == color,
                onPressed: () {
                  onSelected(SelectionQuickFormatAction.textColor(color));
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _QuickTextIconButton(
              icon: Icons.format_color_reset,
              tooltip: 'Clear highlight',
              selected: richText.style.backgroundColor == null,
              onPressed: () {
                onSelected(
                  const SelectionQuickFormatAction.textClearHighlight(),
                );
              },
            ),
            for (final color in highlightColors)
              _QuickTextColorButton(
                color: color,
                selected: richText.style.backgroundColor == color,
                tooltipPrefix: 'Highlight',
                square: true,
                onPressed: () {
                  onSelected(
                    SelectionQuickFormatAction.textHighlightColor(color),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  static const List<TextAlign> _alignments = [
    TextAlign.left,
    TextAlign.center,
    TextAlign.right,
    TextAlign.justify,
  ];

  List<String> _fontFamilyChoices() {
    final seeded = [?richText.style.fontFamily, ..._fontFamilies];
    final seen = <String>{};

    return [
      for (final family in seeded)
        if (seen.add(family)) family,
    ].take(4).toList();
  }

  List<double> _lineHeightChoices() {
    final seeded = [?richText.style.height, ..._lineHeights];
    final seen = <String>{};

    return [
      for (final lineHeight in seeded)
        if (seen.add(lineHeight.toStringAsFixed(2))) lineHeight,
    ].take(5).toList();
  }

  List<double> _letterSpacingChoices() {
    final seeded = [?richText.style.letterSpacing, ..._letterSpacings];
    final seen = <String>{};

    return [
      for (final letterSpacing in seeded)
        if (seen.add(letterSpacing.toStringAsFixed(2))) letterSpacing,
    ].take(5).toList();
  }

  List<Color> _textColors() {
    final seeded = [
      ?richText.style.color,
      ...colors,
      const Color(0xFFFFFFFF),
      const Color(0xFF0F172A),
    ];
    final seen = <int>{};

    return [
      for (final color in seeded)
        if (seen.add(color.toARGB32())) color,
    ].take(6).toList();
  }

  List<Color> _highlightColors() {
    final seeded = [
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
    ].take(6).toList();
  }

  IconData _alignmentIcon(TextAlign alignment) {
    return switch (alignment) {
      TextAlign.center => Icons.format_align_center,
      TextAlign.right || TextAlign.end => Icons.format_align_right,
      TextAlign.justify => Icons.format_align_justify,
      _ => Icons.format_align_left,
    };
  }

  String _alignmentLabel(TextAlign alignment) {
    return switch (alignment) {
      TextAlign.center => 'Center',
      TextAlign.right || TextAlign.end => 'Right',
      TextAlign.justify => 'Justify',
      _ => 'Left',
    };
  }
}

/// Icon button for applying a theme-aware text preset from the quick menu.
class _QuickTextPresetButton extends StatelessWidget {
  final TextStylePreset preset;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickTextPresetButton({
    required this.preset,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(preset);
    final foreground = selected ? const Color(0xFF38BDF8) : Colors.white70;

    return Tooltip(
      message: selected
          ? '$label text preset selected'
          : 'Apply $label text preset',
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onPressed,
        child: Container(
          width: 30,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(_iconFor(preset), color: foreground, size: 16),
        ),
      ),
    );
  }

  IconData _iconFor(TextStylePreset preset) {
    return switch (preset) {
      TextStylePreset.title => Icons.title,
      TextStylePreset.subtitle => Icons.short_text,
      TextStylePreset.body => Icons.notes,
      TextStylePreset.caption => Icons.subtitles_outlined,
      TextStylePreset.quote => Icons.format_quote,
    };
  }

  String _labelFor(TextStylePreset preset) {
    return switch (preset) {
      TextStylePreset.title => 'Title',
      TextStylePreset.subtitle => 'Subtitle',
      TextStylePreset.body => 'Body',
      TextStylePreset.caption => 'Caption',
      TextStylePreset.quote => 'Quote',
    };
  }
}

/// Icon toggle used by the quick text formatting row.
class _QuickTextIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickTextIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? const Color(0xFF38BDF8) : Colors.white70;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onPressed,
        child: Container(
          width: 30,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(icon, color: foreground, size: 16),
        ),
      ),
    );
  }
}

/// Font-family chip used by quick text formatting controls.
class _QuickTextFontFamilyButton extends StatelessWidget {
  final String family;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickTextFontFamilyButton({
    required this.family,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? const Color(0xFF38BDF8) : Colors.white70;

    return Tooltip(
      message: 'Font family $family',
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onPressed,
        child: Container(
          height: 26,
          constraints: const BoxConstraints(minWidth: 42, maxWidth: 82),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            family,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontFamily: family,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Font-size chip used by quick text formatting controls.
class _QuickTextSizeButton extends StatelessWidget {
  final double size;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickTextSizeButton({
    required this.size,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = size.toStringAsFixed(0);
    final foreground = selected ? const Color(0xFF38BDF8) : Colors.white70;

    return Tooltip(
      message: '$label pt text',
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onPressed,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Line-height chip used by quick text formatting controls.
class _QuickTextLineHeightButton extends StatelessWidget {
  final double lineHeight;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickTextLineHeightButton({
    required this.lineHeight,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = _lineHeightLabel(lineHeight);
    final foreground = selected ? const Color(0xFF38BDF8) : Colors.white70;

    return Tooltip(
      message: '$label line spacing',
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onPressed,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  String _lineHeightLabel(double lineHeight) {
    if ((lineHeight - 1.0).abs() < 0.001) return '1x';

    return '${lineHeight.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}x';
  }
}

/// Character-spacing chip used by quick text formatting controls.
class _QuickTextLetterSpacingButton extends StatelessWidget {
  final double letterSpacing;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickTextLetterSpacingButton({
    required this.letterSpacing,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = _letterSpacingLabel(letterSpacing);
    final foreground = selected ? const Color(0xFF38BDF8) : Colors.white70;

    return Tooltip(
      message: _letterSpacingTooltip(letterSpacing),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onPressed,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  String _letterSpacingLabel(double value) {
    if (value.abs() < 0.001) return 'Normal';

    final label = value
        .abs()
        .toStringAsFixed(1)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return value > 0 ? '+$label' : '-$label';
  }

  String _letterSpacingTooltip(double value) {
    if (value.abs() < 0.001) return 'Normal character spacing';
    if (value < 0) return 'Tight character spacing';

    final label = value.toStringAsFixed(1).replaceFirst(RegExp(r'\.?0+$'), '');
    return '$label pt character spacing';
  }
}

/// Color swatch for quick selected-text color changes.
class _QuickTextColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final String tooltipPrefix;
  final bool square;
  final VoidCallback onPressed;

  const _QuickTextColorButton({
    required this.color,
    required this.selected,
    required this.onPressed,
    this.tooltipPrefix = 'Text',
    this.square = false,
  });

  @override
  Widget build(BuildContext context) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    final label = '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final radius = BorderRadius.circular(square ? 6 : 999);

    return Tooltip(
      message: '$tooltipPrefix $label',
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? const Color(0xFF38BDF8)
                  : Colors.white.withValues(alpha: 0.22),
              width: selected ? 2 : 1,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

@Preview(name: 'Selection quick text format row', size: Size(260, 230))
Widget selectionQuickTextFormatRowPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SizedBox(
          width: 184,
          child: SelectionQuickTextFormatRow(
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
            selectedPreset: TextStylePreset.body,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/object_style_preset.dart';
import '../../models/rich_text_content.dart';
import '../../models/selection_quick_format_action.dart';
import '../../models/text_paragraph_format.dart';
import '../../models/text_style_preset.dart';
import 'selection_quick_format_preset_row.dart';
import 'selection_quick_paragraph_format_row.dart';
import 'selection_quick_text_format_row.dart';

const double _richQuickFormatColumnWidth = 232;
const double _richQuickFormatColumnGap = 16;
const double _richQuickFormatHorizontalPadding = 12;
const double _richQuickFormatVerticalPadding = 10;
const double _richQuickFormatSurfaceWidth =
    (_richQuickFormatColumnWidth * 2) +
    _richQuickFormatColumnGap +
    (_richQuickFormatHorizontalPadding * 2);
const double _richQuickFormatEstimatedSurfaceHeight = 748;

/// Popup menu for fast selected-object fill, outline, and opacity changes.
class SelectionQuickFormatMenu extends StatelessWidget {
  final bool enabled;
  final Color accentColor;
  final Color secondaryColor;
  final ObjectStylePreset? selectedPreset;
  final List<Color> fillColors;
  final Color? selectedFillColor;
  final Color selectedBorderColor;
  final double selectedBorderWidth;
  final double selectedOpacity;
  final bool selectedGlowEnabled;
  final Color? selectedGlowColor;
  final RichTextContent? richText;
  final TextParagraphListStyle activeParagraphListStyle;
  final TextStylePreset? selectedTextPreset;
  final ValueChanged<SelectionQuickFormatAction> onSelected;

  const SelectionQuickFormatMenu({
    super.key,
    required this.enabled,
    required this.accentColor,
    required this.secondaryColor,
    required this.fillColors,
    required this.selectedFillColor,
    required this.selectedBorderColor,
    required this.selectedBorderWidth,
    required this.selectedOpacity,
    required this.onSelected,
    this.selectedGlowEnabled = false,
    this.selectedGlowColor,
    this.selectedPreset,
    this.richText,
    this.activeParagraphListStyle = TextParagraphListStyle.none,
    this.selectedTextPreset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = fillColors.take(6).toList();

    return PopupMenuButton<SelectionQuickFormatAction>(
      tooltip: 'Quick format',
      enabled: enabled,
      color: const Color(0xFF111827),
      elevation: 10,
      offset: const Offset(0, 34),
      constraints: richText == null
          ? null
          : const BoxConstraints(
              minWidth: _richQuickFormatSurfaceWidth,
              maxWidth: _richQuickFormatSurfaceWidth,
            ),
      onSelected: onSelected,
      itemBuilder: (context) => richText == null
          ? _objectMenuItems(context, colors)
          : [_richTextSurface(context: context, colors: colors)],
      child: _QuickFormatIconShell(enabled: enabled),
    );
  }

  static const List<double> _borderWidths = [0, 1, 2, 4];
  static const List<double> _opacityStops = [1, 0.75, 0.5, 0.25];

  List<PopupMenuEntry<SelectionQuickFormatAction>> _objectMenuItems(
    BuildContext context,
    List<Color> colors,
  ) {
    return [
      _presetSection(context),
      const PopupMenuDivider(height: 8),
      _fillSection(colors),
      const PopupMenuDivider(height: 8),
      _outlineSection(colors),
      const PopupMenuDivider(height: 8),
      _outlineWidthSection(),
      const PopupMenuDivider(height: 8),
      _opacitySection(),
      const PopupMenuDivider(height: 8),
      _effectsSection(colors),
    ];
  }

  PopupMenuEntry<SelectionQuickFormatAction> _richTextSurface({
    required BuildContext context,
    required List<Color> colors,
  }) {
    return _QuickFormatSurfaceEntry(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _richQuickFormatColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _presetBlock(context),
                const _InlineDivider(),
                _fillBlock(colors),
                const _InlineDivider(),
                _outlineBlock(colors),
                const _InlineDivider(),
                _outlineWidthBlock(),
                const _InlineDivider(),
                _opacityBlock(),
                const _InlineDivider(),
                _QuickFormatSection(
                  label: 'Effects',
                  width: _richQuickFormatColumnWidth,
                  child: _effectsBlock(colors),
                ),
              ],
            ),
          ),
          const SizedBox(width: _richQuickFormatColumnGap),
          SizedBox(
            width: _richQuickFormatColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuickFormatSection(
                  label: 'Text',
                  width: _richQuickFormatColumnWidth,
                  child: SelectionQuickTextFormatRow(
                    richText: richText!,
                    colors: colors,
                    selectedPreset: selectedTextPreset,
                    onSelected: (action) {
                      Navigator.pop<SelectionQuickFormatAction>(
                        context,
                        action,
                      );
                    },
                  ),
                ),
                const _InlineDivider(),
                _QuickFormatSection(
                  label: 'Paragraph',
                  width: _richQuickFormatColumnWidth,
                  child: SelectionQuickParagraphFormatRow(
                    activeListStyle: activeParagraphListStyle,
                    onSelected: (action) {
                      Navigator.pop<SelectionQuickFormatAction>(
                        context,
                        action,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SelectionQuickFormatAction> _presetSection(
    BuildContext context,
  ) {
    return _section(label: 'Presets', child: _presetBlock(context));
  }

  Widget _presetBlock(BuildContext context) {
    return SelectionQuickFormatPresetRow(
      accentColor: accentColor,
      secondaryColor: secondaryColor,
      selectedPreset: selectedPreset,
      onSelected: (preset) {
        Navigator.pop<SelectionQuickFormatAction>(
          context,
          SelectionQuickFormatAction.objectPreset(preset),
        );
      },
    );
  }

  PopupMenuItem<SelectionQuickFormatAction> _fillSection(List<Color> colors) {
    return _section(label: 'Fill', child: _fillBlock(colors));
  }

  Widget _fillBlock(List<Color> colors) {
    return _QuickFormatSwatchRow(
      colors: colors,
      selectedColor: selectedFillColor,
      clearLabel: 'None',
      clearTooltip: 'No fill',
      clearSelected: selectedFillColor == null,
      clearAction: const SelectionQuickFormatAction.clearFill(),
      tooltipBuilder: (color) => 'Fill ${_colorHex(color)}',
      actionBuilder: SelectionQuickFormatAction.fillColor,
    );
  }

  PopupMenuItem<SelectionQuickFormatAction> _outlineSection(
    List<Color> colors,
  ) {
    return _section(label: 'Outline', child: _outlineBlock(colors));
  }

  Widget _outlineBlock(List<Color> colors) {
    return _QuickFormatSwatchRow(
      colors: colors,
      selectedColor: selectedBorderWidth <= 0 ? null : selectedBorderColor,
      clearLabel: 'None',
      clearTooltip: 'No outline',
      clearSelected: selectedBorderWidth <= 0,
      clearAction: const SelectionQuickFormatAction.clearBorder(),
      tooltipBuilder: (color) => 'Outline ${_colorHex(color)}',
      actionBuilder: SelectionQuickFormatAction.borderColor,
    );
  }

  PopupMenuItem<SelectionQuickFormatAction> _outlineWidthSection() {
    return _section(label: 'Outline width', child: _outlineWidthBlock());
  }

  Widget _outlineWidthBlock() {
    return _QuickFormatChoiceRow(
      choices: [
        for (final width in _borderWidths)
          _QuickFormatChoice(
            label: _borderWidthShortLabel(width),
            tooltip: _borderWidthLabel(width),
            isSelected: (selectedBorderWidth - width).abs() < 0.001,
            action: SelectionQuickFormatAction.borderWidth(width),
          ),
      ],
    );
  }

  PopupMenuItem<SelectionQuickFormatAction> _opacitySection() {
    return _section(label: 'Opacity', child: _opacityBlock());
  }

  Widget _opacityBlock() {
    return _QuickFormatChoiceRow(
      choices: [
        for (final opacity in _opacityStops)
          _QuickFormatChoice(
            label: '${(opacity * 100).round()}%',
            tooltip: '${(opacity * 100).round()}% opacity',
            isSelected: (selectedOpacity - opacity).abs() < 0.001,
            action: SelectionQuickFormatAction.opacity(opacity),
          ),
      ],
    );
  }

  PopupMenuItem<SelectionQuickFormatAction> _effectsSection(
    List<Color> colors,
  ) {
    return _section(label: 'Effects', child: _effectsBlock(colors));
  }

  Widget _effectsBlock(List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuickFormatChoiceRow(
          choices: [
            _QuickFormatChoice(
              label: 'None',
              tooltip: 'No glow',
              isSelected: !selectedGlowEnabled,
              action: const SelectionQuickFormatAction.glowEnabled(false),
            ),
            _QuickFormatChoice(
              label: 'Glow',
              tooltip: 'Glow on',
              isSelected: selectedGlowEnabled,
              action: const SelectionQuickFormatAction.glowEnabled(true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _QuickFormatSwatchRow(
          colors: colors,
          selectedColor: selectedGlowEnabled ? selectedGlowColor : null,
          tooltipBuilder: (color) => 'Glow ${_colorHex(color)}',
          actionBuilder: SelectionQuickFormatAction.glowColor,
        ),
      ],
    );
  }

  PopupMenuItem<SelectionQuickFormatAction> _section({
    required String label,
    required Widget child,
  }) {
    return PopupMenuItem<SelectionQuickFormatAction>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: _QuickFormatSection(label: label, child: child),
    );
  }

  String _borderWidthLabel(double width) {
    if (width <= 0) return 'No outline';
    return '${width.round()} px outline';
  }

  String _borderWidthShortLabel(double width) {
    if (width <= 0) return 'None';
    return '${width.round()} px';
  }

  String _colorHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// Non-selectable popup entry used for the rich quick-format tool surface.
class _QuickFormatSurfaceEntry
    extends PopupMenuEntry<SelectionQuickFormatAction> {
  static const double _surfaceHeight = _richQuickFormatEstimatedSurfaceHeight;

  final Widget child;

  const _QuickFormatSurfaceEntry({required this.child});

  @override
  double get height => _surfaceHeight;

  @override
  bool represents(SelectionQuickFormatAction? value) => false;

  @override
  State<_QuickFormatSurfaceEntry> createState() =>
      _QuickFormatSurfaceEntryState();
}

/// State wrapper for the rich quick-format popup entry.
class _QuickFormatSurfaceEntryState extends State<_QuickFormatSurfaceEntry> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _richQuickFormatSurfaceWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _richQuickFormatHorizontalPadding,
          vertical: _richQuickFormatVerticalPadding,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Labeled popup section containing compact quick-format controls.
class _QuickFormatSection extends StatelessWidget {
  final String label;
  final Widget child;
  final double width;

  const _QuickFormatSection({
    required this.label,
    required this.child,
    this.width = 184,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Lightweight separator used inside the rich-text quick-format surface.
class _InlineDivider extends StatelessWidget {
  const _InlineDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

/// Horizontal strip of color swatches used by quick fill and outline controls.
class _QuickFormatSwatchRow extends StatelessWidget {
  final List<Color> colors;
  final Color? selectedColor;
  final String? clearLabel;
  final String? clearTooltip;
  final bool clearSelected;
  final SelectionQuickFormatAction? clearAction;
  final String Function(Color color) tooltipBuilder;
  final SelectionQuickFormatAction Function(Color color) actionBuilder;

  const _QuickFormatSwatchRow({
    required this.colors,
    required this.selectedColor,
    required this.tooltipBuilder,
    required this.actionBuilder,
    this.clearLabel,
    this.clearTooltip,
    this.clearSelected = false,
    this.clearAction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (clearAction != null)
          _QuickFormatChoiceButton(
            choice: _QuickFormatChoice(
              label: clearLabel ?? 'None',
              tooltip: clearTooltip ?? 'No color',
              isSelected: clearSelected,
              action: clearAction!,
            ),
          ),
        for (final color in colors)
          _QuickFormatSwatchButton(
            color: color,
            tooltip: tooltipBuilder(color),
            isSelected: selectedColor == color,
            action: actionBuilder(color),
          ),
      ],
    );
  }
}

/// Color swatch button that returns a typed quick-format action.
class _QuickFormatSwatchButton extends StatelessWidget {
  final Color color;
  final String tooltip;
  final bool isSelected;
  final SelectionQuickFormatAction action;

  const _QuickFormatSwatchButton({
    required this.color,
    required this.tooltip,
    required this.isSelected,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFF38BDF8)
        : Colors.white.withValues(alpha: 0.22);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            Navigator.pop<SelectionQuickFormatAction>(context, action);
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Choice model for compact numeric quick-format chips.
class _QuickFormatChoice {
  final String label;
  final String tooltip;
  final bool isSelected;
  final SelectionQuickFormatAction action;

  const _QuickFormatChoice({
    required this.label,
    required this.tooltip,
    required this.isSelected,
    required this.action,
  });
}

/// Horizontal strip of compact text chips for widths and opacity stops.
class _QuickFormatChoiceRow extends StatelessWidget {
  final List<_QuickFormatChoice> choices;

  const _QuickFormatChoiceRow({required this.choices});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final choice in choices) _QuickFormatChoiceButton(choice: choice),
      ],
    );
  }
}

/// Text chip button that returns a typed quick-format action.
class _QuickFormatChoiceButton extends StatelessWidget {
  final _QuickFormatChoice choice;

  const _QuickFormatChoiceButton({required this.choice});

  @override
  Widget build(BuildContext context) {
    final foreground = choice.isSelected
        ? const Color(0xFF38BDF8)
        : Colors.white70;

    return Tooltip(
      message: choice.tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () {
          Navigator.pop<SelectionQuickFormatAction>(context, choice.action);
        },
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: choice.isSelected
                ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: choice.isSelected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            choice.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

/// Stable icon shell for the selected-object quick-format trigger.
class _QuickFormatIconShell extends StatelessWidget {
  final bool enabled;

  const _QuickFormatIconShell({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Icon(
        Icons.format_paint_outlined,
        size: 17,
        color: enabled ? const Color(0xFF38BDF8) : Colors.white24,
      ),
    );
  }
}

@Preview(name: 'Selection quick format menu', size: Size(260, 120))
Widget selectionQuickFormatMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SelectionQuickFormatMenu(
          enabled: true,
          accentColor: const Color(0xFF2563EB),
          secondaryColor: const Color(0xFF14B8A6),
          selectedPreset: ObjectStylePreset.soft,
          fillColors: const [
            Color(0xFF2563EB),
            Color(0xFF14B8A6),
            Color(0xFFF43F5E),
            Color(0xFFF59E0B),
          ],
          selectedFillColor: const Color(0xFF2563EB),
          selectedBorderColor: const Color(0xFF14B8A6),
          selectedBorderWidth: 2,
          selectedOpacity: 0.75,
          selectedGlowEnabled: true,
          selectedGlowColor: const Color(0xFF14B8A6),
          activeParagraphListStyle: TextParagraphListStyle.bullet,
          richText: RichTextContent(
            text: 'Quarterly update',
            style: const TextStyle(color: Color(0xFF2563EB), fontSize: 24),
            isBold: true,
          ),
          onSelected: (_) {},
        ),
      ),
    ),
  );
}

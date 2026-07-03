import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/selection_quick_format_action.dart';
import '../../models/text_paragraph_format.dart';

/// Compact paragraph controls shown inside the selected-text quick menu.
class SelectionQuickParagraphFormatRow extends StatelessWidget {
  final TextParagraphListStyle activeListStyle;
  final ValueChanged<SelectionQuickFormatAction> onSelected;

  const SelectionQuickParagraphFormatRow({
    super.key,
    required this.onSelected,
    this.activeListStyle = TextParagraphListStyle.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _QuickParagraphIconButton(
              icon: Icons.format_list_bulleted,
              tooltip: activeListStyle == TextParagraphListStyle.bullet
                  ? 'Remove bullets'
                  : 'Bulleted list',
              selected: activeListStyle == TextParagraphListStyle.bullet,
              onPressed: () {
                onSelected(
                  SelectionQuickFormatAction.paragraphListStyle(
                    activeListStyle == TextParagraphListStyle.bullet
                        ? TextParagraphListStyle.none
                        : TextParagraphListStyle.bullet,
                  ),
                );
              },
            ),
            _QuickParagraphIconButton(
              icon: Icons.format_list_numbered,
              tooltip: activeListStyle == TextParagraphListStyle.numbered
                  ? 'Remove numbering'
                  : 'Numbered list',
              selected: activeListStyle == TextParagraphListStyle.numbered,
              onPressed: () {
                onSelected(
                  SelectionQuickFormatAction.paragraphListStyle(
                    activeListStyle == TextParagraphListStyle.numbered
                        ? TextParagraphListStyle.none
                        : TextParagraphListStyle.numbered,
                  ),
                );
              },
            ),
            _QuickParagraphIconButton(
              icon: Icons.format_indent_decrease,
              tooltip: 'Decrease indent',
              onPressed: () {
                onSelected(
                  const SelectionQuickFormatAction.textIndent(
                    TextIndentDirection.decrease,
                  ),
                );
              },
            ),
            _QuickParagraphIconButton(
              icon: Icons.format_indent_increase,
              tooltip: 'Increase indent',
              onPressed: () {
                onSelected(
                  const SelectionQuickFormatAction.textIndent(
                    TextIndentDirection.increase,
                  ),
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
            for (final transform in TextCaseTransform.values)
              _QuickParagraphCaseButton(
                transform: transform,
                onPressed: () {
                  onSelected(SelectionQuickFormatAction.textCase(transform));
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Icon button for list and indentation paragraph commands.
class _QuickParagraphIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  const _QuickParagraphIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
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

/// Compact text chip for text case paragraph transforms.
class _QuickParagraphCaseButton extends StatelessWidget {
  final TextCaseTransform transform;
  final VoidCallback onPressed;

  const _QuickParagraphCaseButton({
    required this.transform,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltipFor(transform),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onPressed,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            _labelFor(transform),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(TextCaseTransform transform) {
    return switch (transform) {
      TextCaseTransform.sentence => 'Aa',
      TextCaseTransform.lowercase => 'aa',
      TextCaseTransform.uppercase => 'AA',
      TextCaseTransform.title => 'Tt',
    };
  }

  String _tooltipFor(TextCaseTransform transform) {
    return switch (transform) {
      TextCaseTransform.sentence => 'Sentence case',
      TextCaseTransform.lowercase => 'lowercase',
      TextCaseTransform.uppercase => 'UPPERCASE',
      TextCaseTransform.title => 'Title Case',
    };
  }
}

@Preview(name: 'Selection quick paragraph format row', size: Size(240, 120))
Widget selectionQuickParagraphFormatRowPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SizedBox(
          width: 184,
          child: SelectionQuickParagraphFormatRow(
            activeListStyle: TextParagraphListStyle.bullet,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
}

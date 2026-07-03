import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/rich_text_content.dart';
import '../../models/text_paragraph_format.dart';
import '../../services/text_paragraph_formatting_service.dart';
import 'ribbon_icon_button.dart';
import 'ribbon_menu_button.dart';
import 'ribbon_toggle_button.dart';

/// Contextual ribbon group for paragraph lists, indentation, and case.
class ToolbarParagraphFormatGroup extends StatelessWidget {
  final RichTextContent richText;
  final bool enabled;
  final bool compact;
  final Color accentColor;
  final TextParagraphFormattingService formattingService;
  final ValueChanged<TextParagraphListStyle> onListStyleSelected;
  final ValueChanged<TextIndentDirection> onIndentChanged;
  final ValueChanged<TextCaseTransform> onTextCaseSelected;

  const ToolbarParagraphFormatGroup({
    super.key,
    required this.richText,
    required this.onListStyleSelected,
    required this.onIndentChanged,
    required this.onTextCaseSelected,
    this.enabled = true,
    this.compact = false,
    this.accentColor = const Color(0xFF38BDF8),
    this.formattingService = const TextParagraphFormattingService(),
  });

  @override
  Widget build(BuildContext context) {
    final activeListStyle = formattingService.activeListStyle(richText.text);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonToggleButton(
          activeIcon: Icons.format_list_bulleted,
          inactiveIcon: Icons.format_list_bulleted,
          tooltip: activeListStyle == TextParagraphListStyle.bullet
              ? 'Remove Bullets'
              : 'Bulleted List',
          isActive: activeListStyle == TextParagraphListStyle.bullet,
          onPressed: enabled
              ? () => onListStyleSelected(
                  activeListStyle == TextParagraphListStyle.bullet
                      ? TextParagraphListStyle.none
                      : TextParagraphListStyle.bullet,
                )
              : null,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonToggleButton(
          activeIcon: Icons.format_list_numbered,
          inactiveIcon: Icons.format_list_numbered,
          tooltip: activeListStyle == TextParagraphListStyle.numbered
              ? 'Remove Numbering'
              : 'Numbered List',
          isActive: activeListStyle == TextParagraphListStyle.numbered,
          onPressed: enabled
              ? () => onListStyleSelected(
                  activeListStyle == TextParagraphListStyle.numbered
                      ? TextParagraphListStyle.none
                      : TextParagraphListStyle.numbered,
                )
              : null,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonIconButton(
          icon: Icons.format_indent_decrease,
          tooltip: 'Decrease Indent',
          compact: compact,
          onPressed: enabled
              ? () => onIndentChanged(TextIndentDirection.decrease)
              : null,
        ),
        RibbonIconButton(
          icon: Icons.format_indent_increase,
          tooltip: 'Increase Indent',
          compact: compact,
          onPressed: enabled
              ? () => onIndentChanged(TextIndentDirection.increase)
              : null,
        ),
        RibbonMenuButton<TextCaseTransform>(
          icon: Icons.text_fields,
          tooltip: 'Change Case',
          enabled: enabled,
          compact: compact,
          onSelected: onTextCaseSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: TextCaseTransform.sentence,
              child: _ParagraphMenuRow(
                icon: Icons.text_fields,
                label: 'Sentence case',
              ),
            ),
            PopupMenuItem(
              value: TextCaseTransform.lowercase,
              child: _ParagraphMenuRow(
                icon: Icons.text_fields,
                label: 'lowercase',
              ),
            ),
            PopupMenuItem(
              value: TextCaseTransform.uppercase,
              child: _ParagraphMenuRow(
                icon: Icons.text_fields,
                label: 'UPPERCASE',
              ),
            ),
            PopupMenuItem(
              value: TextCaseTransform.title,
              child: _ParagraphMenuRow(icon: Icons.title, label: 'Title Case'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Popup menu row for paragraph formatting commands.
class _ParagraphMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ParagraphMenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
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

@Preview(name: 'Toolbar paragraph format group', size: Size(300, 88))
Widget toolbarParagraphFormatGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarParagraphFormatGroup(
          richText: RichTextContent(
            text: '- Revenue improved\n- Launch pilot',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          onListStyleSelected: (_) {},
          onIndentChanged: (_) {},
          onTextCaseSelected: (_) {},
        ),
      ),
    ),
  );
}

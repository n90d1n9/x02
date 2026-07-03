import 'package:flutter/material.dart';

import '../model/cell/cell_selection.dart';
import '../model/number_format.dart';
import '../model/sheet_shortcut.dart';
import '../state/toolbar_provider.dart';
import 'color_button.dart';
import 'sheet_ribbon_command_row.dart';
import 'sheet_ribbon_group.dart';
import 'tool_button.dart';
import 'tool_popup_button.dart';

/// Home ribbon command groups for clipboard, formatting, alignment, and numbers.
class SheetRibbonHomeGroups extends StatelessWidget {
  const SheetRibbonHomeGroups({
    super.key,
    required this.controller,
    required this.selection,
  });

  final ToolbarController controller;
  final CellSelection? selection;

  bool get _hasSelection => selection != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetRibbonGroup(
          label: 'Clipboard',
          icon: Icons.content_paste,
          children: [_buildClipboardButtons()],
        ),
        SheetRibbonGroup(
          label: 'Format',
          icon: Icons.format_bold,
          children: [
            _buildFormattingButtons(),
            _buildColorButtons(),
            _buildTextColorButtons(),
          ],
        ),
        SheetRibbonGroup(
          label: 'Align',
          icon: Icons.format_align_left,
          children: [_buildAlignmentButtons(), _buildTextLayoutButtons()],
        ),
        SheetRibbonGroup(
          label: 'Number',
          icon: Icons.percent,
          children: [_buildNumberFormatTools()],
        ),
      ],
    );
  }

  Widget _buildFormattingButtons() {
    return SheetRibbonCommandRow(
      children: [
        ToolButton(
          icon: Icons.format_bold,
          onPressed: _hasSelection
              ? () => controller.toggleBold(selection!)
              : null,
          tooltip: 'Bold (${SheetShortcutLabels.bold})',
        ),
        ToolButton(
          icon: Icons.format_italic,
          onPressed: _hasSelection
              ? () => controller.toggleItalic(selection!)
              : null,
          tooltip: 'Italic (${SheetShortcutLabels.italic})',
        ),
        ToolButton(
          icon: Icons.format_underline,
          onPressed: _hasSelection
              ? () => controller.toggleUnderline(selection!)
              : null,
          tooltip: 'Underline (${SheetShortcutLabels.underline})',
        ),
        ToolButton(
          icon: Icons.format_clear,
          onPressed: _hasSelection
              ? () => controller.clearFormatting(selection!)
              : null,
          tooltip: 'Clear Formatting',
        ),
      ],
    );
  }

  Widget _buildAlignmentButtons() {
    return SheetRibbonCommandRow(
      children: [
        ToolButton(
          icon: Icons.format_align_left,
          onPressed: _hasSelection
              ? () => controller.setAlign(selection!, TextAlign.left)
              : null,
          tooltip: 'Align Left',
        ),
        ToolButton(
          icon: Icons.format_align_center,
          onPressed: _hasSelection
              ? () => controller.setAlign(selection!, TextAlign.center)
              : null,
          tooltip: 'Align Center',
        ),
        ToolButton(
          icon: Icons.format_align_right,
          onPressed: _hasSelection
              ? () => controller.setAlign(selection!, TextAlign.right)
              : null,
          tooltip: 'Align Right',
        ),
      ],
    );
  }

  Widget _buildTextLayoutButtons() {
    return SheetRibbonCommandRow(
      children: [
        ToolButton(
          icon: Icons.wrap_text,
          onPressed: _hasSelection
              ? () => controller.toggleWrapText(selection!)
              : null,
          tooltip: 'Wrap Text',
        ),
        ToolButton(
          icon: Icons.merge_type,
          onPressed: _hasSelection
              ? () => controller.mergeCells(selection!)
              : null,
          tooltip: 'Merge Cells',
        ),
      ],
    );
  }

  Widget _buildNumberFormatTools() {
    return SheetRibbonCommandRow(
      children: [
        ToolPopupButton<String>(
          icon: Icons.percent,
          tooltip: 'Number Format',
          enabled: _hasSelection,
          onSelected: _hasSelection
              ? (format) => controller.setNumberFormat(selection!, format)
              : null,
          itemBuilder: (context) => [
            for (final format in SheetNumberFormatId.values)
              PopupMenuItem(
                value: format,
                child: Row(
                  children: [
                    Icon(_numberFormatIcon(format), size: 18),
                    const SizedBox(width: 10),
                    Text(SheetNumberFormatId.labelFor(format)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildClipboardButtons() {
    return SheetRibbonCommandRow(
      children: [
        ToolButton(
          icon: Icons.content_copy,
          onPressed: _hasSelection ? () => controller.copy(selection!) : null,
          tooltip: 'Copy (Ctrl+C)',
        ),
        ToolButton(
          icon: Icons.content_cut,
          onPressed: _hasSelection ? () => controller.cut(selection!) : null,
          tooltip: 'Cut (Ctrl+X)',
        ),
        ToolButton(
          icon: Icons.content_paste,
          onPressed: _hasSelection ? () => controller.paste(selection!) : null,
          tooltip: 'Paste (Ctrl+V)',
        ),
      ],
    );
  }

  Widget _buildColorButtons() {
    return SheetRibbonCommandRow(
      children: [
        const Text('Fill: ', style: TextStyle(fontSize: 12)),
        ColorButton(
          color: Colors.yellow[100]!,
          tooltip: 'Fill Yellow',
          onPressed: _hasSelection
              ? () => controller.setBackground(selection!, Colors.yellow[100]!)
              : null,
        ),
        ColorButton(
          color: Colors.green[100]!,
          tooltip: 'Fill Green',
          onPressed: _hasSelection
              ? () => controller.setBackground(selection!, Colors.green[100]!)
              : null,
        ),
        ColorButton(
          color: Colors.blue[100]!,
          tooltip: 'Fill Blue',
          onPressed: _hasSelection
              ? () => controller.setBackground(selection!, Colors.blue[100]!)
              : null,
        ),
        ColorButton(
          color: Colors.red[100]!,
          tooltip: 'Fill Red',
          onPressed: _hasSelection
              ? () => controller.setBackground(selection!, Colors.red[100]!)
              : null,
        ),
        ColorButton(
          color: Colors.white,
          tooltip: 'Clear Fill',
          onPressed: _hasSelection
              ? () => controller.setBackground(selection!, Colors.white)
              : null,
        ),
      ],
    );
  }

  Widget _buildTextColorButtons() {
    return SheetRibbonCommandRow(
      children: [
        const Text('Text: ', style: TextStyle(fontSize: 12)),
        ColorButton(
          color: Colors.black,
          tooltip: 'Text Black',
          onPressed: _hasSelection
              ? () => controller.setTextColor(selection!, Colors.black)
              : null,
        ),
        ColorButton(
          color: Colors.red,
          tooltip: 'Text Red',
          onPressed: _hasSelection
              ? () => controller.setTextColor(selection!, Colors.red)
              : null,
        ),
        ColorButton(
          color: Colors.blue,
          tooltip: 'Text Blue',
          onPressed: _hasSelection
              ? () => controller.setTextColor(selection!, Colors.blue)
              : null,
        ),
        ColorButton(
          color: Colors.green,
          tooltip: 'Text Green',
          onPressed: _hasSelection
              ? () => controller.setTextColor(selection!, Colors.green)
              : null,
        ),
      ],
    );
  }

  IconData _numberFormatIcon(String format) {
    switch (format) {
      case SheetNumberFormatId.number:
        return Icons.pin;
      case SheetNumberFormatId.currency:
        return Icons.attach_money;
      case SheetNumberFormatId.percent:
        return Icons.percent;
      case SheetNumberFormatId.date:
        return Icons.calendar_today;
      case SheetNumberFormatId.general:
      default:
        return Icons.text_fields;
    }
  }
}

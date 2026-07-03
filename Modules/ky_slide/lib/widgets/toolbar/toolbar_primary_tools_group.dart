import 'package:flutter/material.dart';

import '../../models/enums.dart';
import 'toolbar_tool_button.dart';

class ToolbarPrimaryToolsGroup extends StatelessWidget {
  final ToolMode currentTool;
  final VoidCallback onSelectTool;
  final VoidCallback onTextTool;
  final bool compact;

  const ToolbarPrimaryToolsGroup({
    super.key,
    required this.currentTool,
    required this.onSelectTool,
    required this.onTextTool,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ToolbarToolButton(
          icon: Icons.near_me,
          label: 'Select',
          isSelected: currentTool == ToolMode.select,
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          onPressed: onSelectTool,
          compact: compact,
        ),
        ToolbarToolButton(
          icon: Icons.text_fields,
          label: 'Text',
          isSelected: currentTool == ToolMode.text,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          onPressed: onTextTool,
          compact: compact,
        ),
      ],
    );
  }
}

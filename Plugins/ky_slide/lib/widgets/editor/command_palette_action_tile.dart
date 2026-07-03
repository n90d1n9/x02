import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/command_palette_action.dart';
import 'command_palette_action_badges.dart';
import 'command_palette_highlighted_text.dart';

/// A single actionable result row in the command palette.
class CommandPaletteActionTile extends StatelessWidget {
  final CommandPaletteAction action;
  final bool selected;
  final Color accentColor;
  final String query;
  final VoidCallback onTap;

  const CommandPaletteActionTile({
    super.key,
    required this.action,
    required this.selected,
    required this.accentColor,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = action.enabled;
    final tileColor = selected
        ? accentColor
        : Color.lerp(accentColor, Colors.white, 0.28) ?? accentColor;

    return Tooltip(
      message: enabled ? action.title : '${action.title} unavailable',
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: action.title,
        child: Material(
          color: selected
              ? tileColor.withValues(alpha: 0.11)
              : Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? onTap : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? tileColor.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    action.icon,
                    color: enabled ? tileColor : Colors.white24,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CommandPaletteHighlightedText(
                          text: action.title,
                          query: query,
                          maxLines: 1,
                          style: TextStyle(
                            color: enabled ? Colors.white : Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                          highlightStyle: TextStyle(
                            color: enabled ? tileColor : Colors.white38,
                            backgroundColor: enabled
                                ? tileColor.withValues(alpha: 0.13)
                                : Colors.white.withValues(alpha: 0.05),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        CommandPaletteHighlightedText(
                          text: action.description,
                          query: query,
                          maxLines: 1,
                          style: TextStyle(
                            color: enabled ? Colors.white54 : Colors.white24,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          highlightStyle: TextStyle(
                            color: enabled ? Colors.white : Colors.white38,
                            backgroundColor: enabled
                                ? tileColor.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.05),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  CommandPaletteActionBadges(
                    category: action.category,
                    shortcutLabel: action.shortcutLabel,
                    metadataLabels: action.metadataLabels,
                    enabled: enabled,
                    accentColor: tileColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Command palette action tile', size: Size(520, 160))
Widget commandPaletteActionTilePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 460,
          child: CommandPaletteActionTile(
            selected: true,
            accentColor: const Color(0xFF38BDF8),
            query: 'duplicate',
            onTap: () {},
            action: CommandPaletteAction(
              id: 'preview-duplicate-object',
              title: 'Duplicate Selected Object',
              description: 'Create a copy of the selected layer',
              category: 'Object',
              icon: Icons.copy_all_outlined,
              keywords: const ['duplicate', 'object'],
              shortcutLabel: 'Cmd/Ctrl+D',
              metadataLabels: const ['Selected', 'Layer'],
              onInvoke: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

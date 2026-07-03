import 'package:flutter/material.dart';

import 'document_command.dart';

/// Shows high-value command shortcuts above the full command list.
class DocumentCommandSuggestionStrip extends StatelessWidget {
  static const stripKey = ValueKey('document-command-suggestion-strip');
  static const chipPrefixKey = 'document-command-suggestion-chip';

  final List<DocumentCommand> commands;
  final ValueChanged<DocumentCommand> onSelected;

  const DocumentCommandSuggestionStrip({
    super.key,
    required this.commands,
    required this.onSelected,
  });

  static Key chipKey(String commandId) {
    return ValueKey('$chipPrefixKey-$commandId');
  }

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: stripKey,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final command in commands) ...[
                    _SuggestedCommandButton(
                      command: command,
                      onPressed: command.enabled
                          ? () => onSelected(command)
                          : null,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedCommandButton extends StatelessWidget {
  final DocumentCommand command;
  final VoidCallback? onPressed;

  const _SuggestedCommandButton({
    required this.command,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = command.title;
    final tooltip = command.enabled
        ? command.subtitle
        : command.disabledReason ?? command.subtitle;

    return Tooltip(
      message: tooltip,
      child: FilledButton.tonalIcon(
        key: DocumentCommandSuggestionStrip.chipKey(command.id),
        onPressed: onPressed,
        icon: Icon(command.icon, size: 17),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'document_command.dart';
import 'document_command_availability_badge.dart';
import 'document_command_preview_model.dart';
import 'document_command_shortcut_chip.dart';

/// Shows a focused preview for the top command palette result.
class DocumentCommandPreviewPanel extends StatelessWidget {
  static const panelKey = ValueKey('document-command-preview-panel');
  static const runButtonKey = ValueKey('document-command-preview-run');

  final DocumentCommandPreviewModel model;
  final ValueChanged<DocumentCommand> onSelected;

  const DocumentCommandPreviewPanel({
    super.key = panelKey,
    required this.model,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = _CommandPreviewContent(model: model);
            final action = _CommandPreviewAction(
              model: model,
              onSelected: onSelected,
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  content,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 14),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommandPreviewContent extends StatelessWidget {
  final DocumentCommandPreviewModel model;

  const _CommandPreviewContent({required this.model});

  @override
  Widget build(BuildContext context) {
    final command = model.command;
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = command.enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.56);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: command.enabled
                ? colorScheme.primaryContainer.withValues(alpha: 0.72)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.62),
            ),
          ),
          child: Icon(
            command.icon,
            size: 20,
            color: command.enabled
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top result',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                command.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                command.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _CommandPreviewMeta(model: model),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommandPreviewMeta extends StatelessWidget {
  final DocumentCommandPreviewModel model;

  const _CommandPreviewMeta({required this.model});

  @override
  Widget build(BuildContext context) {
    final shortcut = model.shortcutLabel;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DocumentCommandAvailabilityBadge(
          label: model.statusLabel,
          reason: model.statusDescription,
          icon: model.isEnabled
              ? Icons.play_circle_outline
              : Icons.info_outline,
        ),
        _CommandCategoryChip(label: model.categoryLabel),
        if (shortcut != null) DocumentCommandShortcutChip(shortcut: shortcut),
      ],
    );
  }
}

class _CommandPreviewAction extends StatelessWidget {
  final DocumentCommandPreviewModel model;
  final ValueChanged<DocumentCommand> onSelected;

  const _CommandPreviewAction({required this.model, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: DocumentCommandPreviewPanel.runButtonKey,
      icon: const Icon(Icons.keyboard_return),
      label: const Text('Run'),
      onPressed: model.isEnabled ? () => onSelected(model.command) : null,
    );
  }
}

class _CommandCategoryChip extends StatelessWidget {
  final String label;

  const _CommandCategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

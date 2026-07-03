import 'package:flutter/material.dart';

/// Renders a reusable multiline draft composer for document side panels.
class DocumentPanelComposerCard extends StatelessWidget {
  final TextEditingController controller;
  final String fieldLabel;
  final String actionLabel;
  final IconData actionIcon;
  final bool hasDraft;
  final VoidCallback onSubmit;
  final Key? fieldKey;
  final Key? actionKey;
  final int minLines;
  final int maxLines;

  const DocumentPanelComposerCard({
    super.key,
    required this.controller,
    required this.fieldLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.hasDraft,
    required this.onSubmit,
    this.fieldKey,
    this.actionKey,
    this.minLines = 2,
    this.maxLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            key: fieldKey,
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: fieldLabel,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: actionKey,
            onPressed: hasDraft ? onSubmit : null,
            icon: Icon(actionIcon, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

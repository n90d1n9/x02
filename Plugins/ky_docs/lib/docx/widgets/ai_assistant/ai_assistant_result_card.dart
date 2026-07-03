import 'package:flutter/material.dart';

/// Displays an AI-generated suggestion with actions for document insertion.
class AIAssistantResultCard extends StatelessWidget {
  final String result;
  final VoidCallback onCopy;
  final VoidCallback onInsert;
  final VoidCallback onReplace;
  final VoidCallback onClear;

  const AIAssistantResultCard({
    super.key,
    required this.result,
    required this.onCopy,
    required this.onInsert,
    required this.onReplace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'AI Suggestion',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(result, style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: onInsert,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Insert'),
                ),
                FilledButton.icon(
                  onPressed: onReplace,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Replace'),
                ),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

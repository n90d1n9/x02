import 'package:flutter/material.dart';

import '../services/document_writing_insights.dart';

class DocumentWritingMetricsGrid extends StatelessWidget {
  final DocumentWritingInsightMetrics metrics;

  const DocumentWritingMetricsGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _WritingMetricTile(
          icon: Icons.notes_outlined,
          label: 'Words',
          value: '${metrics.wordCount}',
        ),
        _WritingMetricTile(
          icon: Icons.short_text,
          label: 'Avg sentence',
          value: '${metrics.averageWordsPerSentenceLabel} words',
        ),
        _WritingMetricTile(
          icon: Icons.warning_amber_rounded,
          label: 'Long sentences',
          value: '${metrics.longSentenceCount}',
          emphasized: metrics.longSentenceCount > 0,
        ),
        _WritingMetricTile(
          icon: Icons.segment_outlined,
          label: 'Paragraphs',
          value: '${metrics.paragraphCount}',
        ),
      ],
    );
  }
}

class _WritingMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  const _WritingMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = emphasized
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return SizedBox(
      width: 132,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
          border: Border.all(
            color: accentColor.withValues(alpha: emphasized ? 0.32 : 0.18),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

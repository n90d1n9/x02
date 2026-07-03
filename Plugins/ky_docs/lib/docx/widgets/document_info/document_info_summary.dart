import 'package:flutter/material.dart';

import '../../models/document_metadata.dart';
import '../../services/document_statistics.dart';

class DocumentInfoSummary extends StatelessWidget {
  final DocumentMetadata metadata;
  final DocumentTextStatistics statistics;

  const DocumentInfoSummary({
    super.key,
    required this.metadata,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final insights = statistics.writingInsights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _DocumentIdentityCard(metadata: metadata),
        const SizedBox(height: 14),
        _MetricGrid(
          metrics: [
            _InfoMetric(
              icon: Icons.notes_outlined,
              label: 'Words',
              value: '${statistics.wordCount}',
            ),
            _InfoMetric(
              icon: Icons.text_fields,
              label: 'Characters',
              value: '${statistics.characterCount}',
            ),
            _InfoMetric(
              icon: Icons.schedule_outlined,
              label: 'Reading time',
              value: statistics.readingTimeLabel,
            ),
            _InfoMetric(
              icon: Icons.auto_graph,
              label: 'Writing quality',
              value: '${insights.qualityLabel} ${insights.score}/100',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoSection(
          title: 'Document details',
          children: [
            _PropertyRow(
              label: 'Created',
              value: _formatDateTime(metadata.createdAt),
            ),
            _PropertyRow(
              label: 'Modified',
              value: _formatDateTime(metadata.lastModified),
            ),
            _PropertyRow(label: 'Author', value: metadata.author),
            _PropertyRow(label: 'Folder', value: metadata.folderId ?? 'None'),
          ],
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Structure',
          children: [
            _PropertyRow(
              label: 'Paragraphs',
              value: '${statistics.paragraphCount}',
            ),
            _PropertyRow(
              label: 'Sentences',
              value: '${statistics.sentenceCount}',
            ),
            _PropertyRow(
              label: 'Characters without spaces',
              value: '${statistics.characterCountNoSpaces}',
            ),
          ],
        ),
        if (metadata.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TagSection(tags: metadata.tags),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = _monthName(dateTime.month);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month ${dateTime.day}, ${dateTime.year} at $hour:$minute';
  }

  String _monthName(int month) {
    return const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
  }
}

class _DocumentIdentityCard extends StatelessWidget {
  final DocumentMetadata metadata;

  const _DocumentIdentityCard({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.description_outlined, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metadata.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (metadata.isFavorite)
                      Icon(
                        Icons.star_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Owned by ${metadata.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_InfoMetric> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 560.0;
        final columns = width >= 520 ? 4 : 2;
        const spacing = 8.0;
        final tileWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: tileWidth,
                child: _MetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _InfoMetric {
  final IconData icon;
  final String label;
  final String value;

  const _InfoMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _MetricTile extends StatelessWidget {
  final _InfoMetric metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metric.icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final String label;
  final String value;

  const _PropertyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 156,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagSection extends StatelessWidget {
  final List<String> tags;

  const _TagSection({required this.tags});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _InfoSection(
      title: 'Tags',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              Chip(
                label: Text(tag),
                visualDensity: VisualDensity.compact,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

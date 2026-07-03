import 'package:flutter/material.dart';

import '../services/document_statistics.dart';
import 'document_writing_insights_strip.dart';
import 'stat_item.dart';

/// Displays live word count, reading time, and writing quality metrics.
class DocumentStatisticsPanel extends StatelessWidget {
  static const closeButtonKey = ValueKey('document-statistics-close');

  final DocumentStatistics statistics;
  final VoidCallback? onOpenWritingInsights;
  final VoidCallback? onClose;

  const DocumentStatisticsPanel({
    super.key,
    required this.statistics,
    this.onOpenWritingInsights,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = statistics.snapshot;
    final metrics = [
      _DocumentStatMetric(
        icon: Icons.subject,
        label: 'Words',
        value: snapshot.wordCount.toString(),
      ),
      _DocumentStatMetric(
        icon: Icons.text_fields,
        label: 'Characters',
        value: snapshot.characterCount.toString(),
      ),
      _DocumentStatMetric(
        icon: Icons.format_list_numbered,
        label: 'Paragraphs',
        value: snapshot.paragraphCount.toString(),
      ),
      _DocumentStatMetric(
        icon: Icons.timer_outlined,
        label: 'Read Time',
        value: snapshot.readingTimeLabel,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onClose != null) ...[
            _StatisticsHeader(onClose: onClose),
            const SizedBox(height: 12),
          ],
          _StatisticsMetricLayout(metrics: metrics),
          const SizedBox(height: 14),
          DocumentWritingInsightsStrip(
            insights: snapshot.writingInsights,
            onOpenDetails: onOpenWritingInsights,
          ),
        ],
      ),
    );
  }
}

/// Displays the dock title and close control for document statistics.
class _StatisticsHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const _StatisticsHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.analytics_outlined, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Writing statistics',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          key: DocumentStatisticsPanel.closeButtonKey,
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// Chooses a responsive arrangement for the document statistic metrics.
class _StatisticsMetricLayout extends StatelessWidget {
  final List<_DocumentStatMetric> metrics;

  const _StatisticsMetricLayout({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          final itemWidth = ((constraints.maxWidth - 16) / 2).clamp(
            120.0,
            220.0,
          );

          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              for (final metric in metrics)
                SizedBox(width: itemWidth, child: _StatMetricItem(metric)),
            ],
          );
        }

        return Row(
          children: [
            for (final metric in metrics)
              Expanded(child: _StatMetricItem(metric)),
          ],
        );
      },
    );
  }
}

/// Renders one document statistic using the shared statistic item visual.
class _StatMetricItem extends StatelessWidget {
  final _DocumentStatMetric metric;

  const _StatMetricItem(this.metric);

  @override
  Widget build(BuildContext context) {
    return StatItem(
      icon: metric.icon,
      label: metric.label,
      value: metric.value,
    );
  }
}

/// Describes one metric shown in the document statistics panel.
class _DocumentStatMetric {
  final IconData icon;
  final String label;
  final String value;

  const _DocumentStatMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/document_writing_insights.dart';
import 'document_writing_metrics_grid.dart';
import 'document_writing_score_meter.dart';

class DocumentWritingInsightsDialog extends StatelessWidget {
  final DocumentWritingInsights insights;

  const DocumentWritingInsightsDialog({super.key, required this.insights});

  static Future<void> show(
    BuildContext context, {
    required DocumentWritingInsights insights,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => DocumentWritingInsightsDialog(insights: insights),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.auto_graph, color: colorScheme.primary),
      title: const Text('Writing Insights'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScoreSummary(insights: insights),
              const SizedBox(height: 16),
              _InsightHighlights(insights: insights),
              const SizedBox(height: 16),
              DocumentWritingMetricsGrid(metrics: insights.metrics),
              const SizedBox(height: 16),
              _RecommendationList(recommendations: insights.recommendations),
            ],
          ),
        ),
      ),
      actions: [
        if (insights.hasRecommendations)
          TextButton.icon(
            onPressed: () => _copyRecommendations(context),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy recommendations'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _copyRecommendations(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: insights.recommendationsText));
    messenger?.showSnackBar(
      const SnackBar(content: Text('Writing recommendations copied')),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final DocumentWritingInsights insights;

  const _ScoreSummary({required this.insights});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, insights.score);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          DocumentWritingScoreMeter(insights: insights, size: 70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insights.qualityLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  insights.hasRecommendations
                      ? 'Review recommended refinements'
                      : 'No writing issues detected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightHighlights extends StatelessWidget {
  final DocumentWritingInsights insights;

  const _InsightHighlights({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final insight in insights.highlights)
          _InsightHighlightChip(insight: insight),
      ],
    );
  }
}

class _InsightHighlightChip extends StatelessWidget {
  final DocumentWritingInsight insight;

  const _InsightHighlightChip({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, insight.tone);
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForKind(insight.kind), size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${insight.label}: ${insight.value}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForKind(DocumentWritingInsightKind kind) {
    return switch (kind) {
      DocumentWritingInsightKind.readability => Icons.menu_book_outlined,
      DocumentWritingInsightKind.structure => Icons.account_tree_outlined,
      DocumentWritingInsightKind.rhythm => Icons.graphic_eq,
    };
  }
}

class _RecommendationList extends StatelessWidget {
  final List<String> recommendations;

  const _RecommendationList({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    final items = recommendations.isEmpty
        ? const ['Looks good for now']
        : recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  recommendations.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.tips_and_updates_outlined,
                  size: 17,
                  color: recommendations.isEmpty
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Color _scoreColor(BuildContext context, int score) {
  final colorScheme = Theme.of(context).colorScheme;
  if (score >= 72) return colorScheme.primary;
  return colorScheme.error;
}

Color _toneColor(BuildContext context, DocumentWritingInsightTone tone) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (tone) {
    DocumentWritingInsightTone.positive => colorScheme.primary,
    DocumentWritingInsightTone.neutral => colorScheme.onSurfaceVariant,
    DocumentWritingInsightTone.caution => colorScheme.error,
  };
}

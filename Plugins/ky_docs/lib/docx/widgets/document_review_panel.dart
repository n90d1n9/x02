import 'package:flutter/material.dart';

import '../services/document_statistics.dart';
import '../services/document_writing_insights.dart';
import 'document_writing_metrics_grid.dart';
import 'document_writing_quality_badge.dart';
import 'document_writing_score_meter.dart';
import 'panel/document_panel_header.dart';
import 'panel/document_panel_section_header.dart';
import 'panel/document_panel_shell.dart';

class DocumentReviewPanel extends StatelessWidget {
  final DocumentTextStatistics statistics;
  final VoidCallback? onClose;
  final VoidCallback? onOpenWritingInsights;
  final bool showHeader;
  final bool showFrame;

  const DocumentReviewPanel({
    super.key,
    required this.statistics,
    this.onClose,
    this.onOpenWritingInsights,
    this.showHeader = true,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    final insights = statistics.writingInsights;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          _ReviewHeader(
            issueCount: insights.recommendations.length,
            onClose: onClose,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            children: [
              _ReviewSummaryCard(
                insights: insights,
                onOpenWritingInsights: onOpenWritingInsights,
              ),
              const SizedBox(height: 16),
              const DocumentPanelSectionHeader(
                icon: Icons.query_stats_outlined,
                title: 'Document metrics',
              ),
              const SizedBox(height: 10),
              DocumentWritingMetricsGrid(metrics: insights.metrics),
              const SizedBox(height: 18),
              const DocumentPanelSectionHeader(
                icon: Icons.tips_and_updates_outlined,
                title: 'Suggestions',
              ),
              const SizedBox(height: 8),
              _SuggestionList(insights: insights),
              const SizedBox(height: 18),
              const DocumentPanelSectionHeader(
                icon: Icons.track_changes_outlined,
                title: 'Focus areas',
              ),
              const SizedBox(height: 8),
              _FocusAreaList(insights: insights),
            ],
          ),
        ),
      ],
    );

    return DocumentPanelShell(showFrame: showFrame, child: content);
  }
}

class _ReviewHeader extends StatelessWidget {
  final int issueCount;
  final VoidCallback? onClose;

  const _ReviewHeader({required this.issueCount, this.onClose});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelHeader(
      icon: Icons.rate_review_outlined,
      title: 'Review',
      subtitle: issueCount == 0
          ? 'No writing issues detected'
          : '$issueCount suggestion${issueCount == 1 ? '' : 's'}',
      closeTooltip: 'Close review',
      onClose: onClose,
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final DocumentWritingInsights insights;
  final VoidCallback? onOpenWritingInsights;

  const _ReviewSummaryCard({
    required this.insights,
    required this.onOpenWritingInsights,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document quality',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DocumentWritingQualityBadge(insights: insights),
                    const SizedBox(height: 12),
                    Text(
                      insights.hasRecommendations
                          ? 'Review the suggested refinements before sharing.'
                          : 'This draft is ready for a closer read.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DocumentWritingScoreMeter(insights: insights, size: 78),
            ],
          ),
          if (onOpenWritingInsights != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onOpenWritingInsights,
                icon: const Icon(Icons.open_in_new, size: 17),
                label: const Text('Open details'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final DocumentWritingInsights insights;

  const _SuggestionList({required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.recommendations.isEmpty) {
      return const _EmptyReviewState();
    }

    return Column(
      children: [
        for (final recommendation in insights.recommendations)
          _SuggestionTile(recommendation: recommendation),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String recommendation;

  const _SuggestionTile({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.24),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              size: 18,
              color: colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recommendation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusAreaList extends StatelessWidget {
  final DocumentWritingInsights insights;

  const _FocusAreaList({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final insight in insights.highlights)
          _FocusAreaTile(insight: insight),
      ],
    );
  }
}

class _FocusAreaTile extends StatelessWidget {
  final DocumentWritingInsight insight;

  const _FocusAreaTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, insight.tone);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_iconForKind(insight.kind), size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                insight.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              insight.value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.30),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Looks good for now',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

Color _toneColor(BuildContext context, DocumentWritingInsightTone tone) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (tone) {
    DocumentWritingInsightTone.positive => colorScheme.primary,
    DocumentWritingInsightTone.neutral => colorScheme.onSurfaceVariant,
    DocumentWritingInsightTone.caution => colorScheme.error,
  };
}

IconData _iconForKind(DocumentWritingInsightKind kind) {
  return switch (kind) {
    DocumentWritingInsightKind.readability => Icons.menu_book_outlined,
    DocumentWritingInsightKind.structure => Icons.account_tree_outlined,
    DocumentWritingInsightKind.rhythm => Icons.graphic_eq,
  };
}

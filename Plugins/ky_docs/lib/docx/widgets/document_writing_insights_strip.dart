import 'package:flutter/material.dart';

import '../services/document_writing_insights.dart';
import 'document_writing_quality_badge.dart';

class DocumentWritingInsightsStrip extends StatelessWidget {
  final DocumentWritingInsights insights;
  final VoidCallback? onOpenDetails;

  const DocumentWritingInsightsStrip({
    super.key,
    required this.insights,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        DocumentWritingQualityBadge(
          insights: insights,
          onPressed: onOpenDetails,
        ),
        for (final highlight in insights.highlights)
          _InsightChip(insight: highlight),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  final DocumentWritingInsight insight;

  const _InsightChip({required this.insight});

  @override
  Widget build(BuildContext context) {
    return _InsightContainer(
      tone: insight.tone,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconForKind(insight.kind),
            size: 16,
            color: _toneColor(context, insight.tone),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${insight.label}: ${insight.value}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _labelStyle(context, insight.tone),
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

class _InsightContainer extends StatelessWidget {
  final DocumentWritingInsightTone tone;
  final Widget child;

  const _InsightContainer({required this.tone, required this.child});

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

TextStyle? _labelStyle(BuildContext context, DocumentWritingInsightTone tone) {
  return Theme.of(context).textTheme.labelSmall?.copyWith(
    color: _toneColor(context, tone),
    fontWeight: FontWeight.w700,
  );
}

Color _toneColor(BuildContext context, DocumentWritingInsightTone tone) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (tone) {
    DocumentWritingInsightTone.positive => colorScheme.primary,
    DocumentWritingInsightTone.neutral => colorScheme.onSurfaceVariant,
    DocumentWritingInsightTone.caution => colorScheme.error,
  };
}

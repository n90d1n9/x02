import 'package:flutter/material.dart';

import '../services/document_writing_insights.dart';

class DocumentWritingQualityBadge extends StatelessWidget {
  final DocumentWritingInsights insights;
  final bool includePrefix;
  final bool showScore;
  final bool dense;
  final VoidCallback? onPressed;

  const DocumentWritingQualityBadge({
    super.key,
    required this.insights,
    this.includePrefix = false,
    this.showScore = true,
    this.dense = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tone = insights.score >= 72
        ? DocumentWritingInsightTone.positive
        : DocumentWritingInsightTone.caution;
    final color = _toneColor(context, tone);
    final label = _label;

    final badge = Container(
      constraints: BoxConstraints(maxWidth: dense ? 180 : 240),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph, size: dense ? 15 : 16, color: color),
          SizedBox(width: dense ? 6 : 8),
          Flexible(
            child: Text(
              label,
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

    final action = onPressed;
    return Tooltip(
      message: insights.hasRecommendations
          ? insights.recommendations.first
          : 'Writing quality looks healthy',
      child: action == null
          ? badge
          : Semantics(
              button: true,
              child: InkWell(
                onTap: action,
                borderRadius: BorderRadius.circular(8),
                child: badge,
              ),
            ),
    );
  }

  String get _label {
    final prefix = includePrefix ? 'Quality: ' : '';
    final score = showScore ? ' ${insights.score}/100' : '';
    return '$prefix${insights.qualityLabel}$score';
  }

  Color _toneColor(BuildContext context, DocumentWritingInsightTone tone) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (tone) {
      DocumentWritingInsightTone.positive => colorScheme.primary,
      DocumentWritingInsightTone.neutral => colorScheme.onSurfaceVariant,
      DocumentWritingInsightTone.caution => colorScheme.error,
    };
  }
}

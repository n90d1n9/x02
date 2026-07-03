import 'package:flutter/material.dart';

import 'find_replace_summary.dart';

/// Displays a concise preview of the pending find-and-replace operation.
class DocxFindReplaceReplacementPreview extends StatelessWidget {
  final DocxFindReplaceSummary summary;

  const DocxFindReplaceReplacementPreview({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = summary.hasQuery && !summary.hasMatches
        ? colorScheme.error
        : colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              summary.hasMatches
                  ? Icons.manage_search_outlined
                  : Icons.info_outline,
              size: 18,
              color: statusColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.detailLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (summary.hasMatches) ...[
              const SizedBox(width: 10),
              _ReplacementCountBadge(
                label: summary.countLabel,
                color: statusColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplacementCountBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ReplacementCountBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

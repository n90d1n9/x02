import 'package:flutter/material.dart';

import '../models/document_import_structure.dart';

class DocumentImportStructureSummaryView extends StatelessWidget {
  final DocumentImportStructureSummary summary;

  const DocumentImportStructureSummaryView({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final headings = summary.headings.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StructurePill(
              icon: Icons.article_outlined,
              label: summary.pageLabel,
            ),
            _StructurePill(
              icon: Icons.title,
              label: _countLabel(summary.headingCount, 'heading'),
            ),
            _StructurePill(
              icon: Icons.format_list_bulleted,
              label: _countLabel(summary.listItemCount, 'list item'),
            ),
            if (summary.tableCount > 0)
              _StructurePill(
                icon: Icons.table_chart_outlined,
                label: _countLabel(summary.tableCount, 'table'),
              ),
            _StructurePill(
              icon: Icons.subject,
              label: _countLabel(summary.paragraphCount, 'paragraph'),
            ),
          ],
        ),
        if (headings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _HeadingPreview(headings: headings),
        ],
        if (summary.qualitySignals.isNotEmpty) ...[
          const SizedBox(height: 12),
          _QualitySignalList(signals: summary.qualitySignals),
        ],
      ],
    );
  }

  String _countLabel(int count, String label) {
    return count == 1 ? '1 $label' : '$count ${label}s';
  }
}

class _StructurePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StructurePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadingPreview extends StatelessWidget {
  final List<String> headings;

  const _HeadingPreview({required this.headings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Headings',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final heading in headings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _QualitySignalList extends StatelessWidget {
  final List<String> signals;

  const _QualitySignalList({required this.signals});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final signal in signals)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      signal,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
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

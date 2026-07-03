import 'package:flutter/material.dart';

import '../../services/document_statistics.dart';
import 'document_status_popover.dart';
import 'document_status_chip.dart';

/// Opens a compact status-bar popover with live document statistics.
class DocumentStatisticsStatusChip extends StatelessWidget {
  static const chipKey = ValueKey('document-statistics-status-chip');
  static const menuKey = ValueKey('document-statistics-status-menu');

  final DocumentTextStatistics statistics;

  const DocumentStatisticsStatusChip({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Show document statistics',
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _DocumentStatisticsMenu(statistics: statistics),
        ),
      ],
      child: DocumentStatusChip(
        key: chipKey,
        icon: Icons.text_fields,
        label: statistics.wordCountLabel,
        tooltip: statistics.summaryTooltip,
      ),
    );
  }
}

/// Renders the compact metrics summary opened from the word-count chip.
class _DocumentStatisticsMenu extends StatelessWidget {
  final DocumentTextStatistics statistics;

  const _DocumentStatisticsMenu({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return DocumentStatusPopover(
      contentKey: DocumentStatisticsStatusChip.menuKey,
      icon: Icons.analytics_outlined,
      title: 'Document statistics',
      subtitle: statistics.readingTimeTooltip,
      width: 292,
      children: [
        DocumentStatusPopoverMetricLine(
          icon: Icons.subject,
          label: 'Words',
          value: statistics.wordCountLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.text_fields,
          label: 'Characters',
          value: statistics.characterCountLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.space_bar,
          label: 'Without spaces',
          value: statistics.characterCountNoSpacesLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.format_list_numbered,
          label: 'Paragraphs',
          value: statistics.paragraphCountLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.short_text,
          label: 'Sentences',
          value: statistics.sentenceCountLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.schedule_outlined,
          label: 'Reading time',
          value: '${statistics.readingTimeLabel} read',
        ),
      ],
    );
  }
}

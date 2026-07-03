import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/document_table.dart';
import '../models/drawing_data.dart';
import 'chart_preview.dart';
import 'drawing_tools.dart';
import 'table_preview.dart';

class DocumentEmbeddedContentPanel extends StatelessWidget {
  final List<DocumentTable> tables;
  final List<ChartData> charts;
  final List<DrawingData> drawings;
  final ValueChanged<String> onDeleteChart;

  const DocumentEmbeddedContentPanel({
    super.key,
    required this.tables,
    required this.charts,
    required this.drawings,
    required this.onDeleteChart,
  });

  bool get _hasContent =>
      tables.isNotEmpty || charts.isNotEmpty || drawings.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tables.isNotEmpty)
              _EmbeddedContentSection(
                title: 'Tables',
                children: [
                  for (final table in tables) DocxTablePreview(table: table),
                ],
              ),
            if (charts.isNotEmpty)
              _EmbeddedContentSection(
                title: 'Charts',
                topSpacing: tables.isNotEmpty ? 16 : 0,
                children: [
                  for (final chart in charts)
                    DocxChartPreview(
                      chart: chart,
                      onDelete: () => onDeleteChart(chart.id),
                    ),
                ],
              ),
            if (drawings.isNotEmpty)
              _EmbeddedContentSection(
                title: 'Drawings & Shapes',
                topSpacing: tables.isNotEmpty || charts.isNotEmpty ? 16 : 0,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final drawing in drawings)
                        DocxDrawingPreview(drawing: drawing),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedContentSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double topSpacing;

  const _EmbeddedContentSection({
    required this.title,
    required this.children,
    this.topSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

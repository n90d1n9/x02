import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sheet_viewport_provider.dart';
import '../theme/ky_sheet_theme.dart';

class SheetPerformancePanel extends ConsumerWidget {
  const SheetPerformancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(sheetViewportStatsProvider);

    return Container(
      width: 286,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(left: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(),
          const Divider(height: 1, color: KySheetColors.gridLine),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _MetricTile(
                  icon: Icons.grid_view,
                  label: 'Rendered Cells',
                  value: _formatInt(stats.renderedCells),
                  detail: '${_formatInt(stats.visibleCells)} visible',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CompactMetric(
                        label: 'Rows',
                        value:
                            '${_formatInt(stats.renderedRows)} / ${_formatInt(stats.visibleRows)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CompactMetric(
                        label: 'Columns',
                        value:
                            '${_formatInt(stats.renderedColumns)} / ${_formatInt(stats.visibleColumns)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _StatRow(label: 'Mode', value: 'Virtualized'),
                _StatRow(label: 'Row Window', value: stats.rowWindowLabel),
                _StatRow(
                  label: 'Column Window',
                  value: stats.columnWindowLabel,
                ),
                _StatRow(
                  label: 'Skipped Cells',
                  value: _formatInt(stats.skippedCells),
                ),
                _StatRow(
                  label: 'Render Share',
                  value: '${(stats.renderRatio * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatInt(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;
      buffer.write(text[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          Icon(Icons.speed, color: KySheetColors.accent, size: 19),
          SizedBox(width: 8),
          Text(
            'Performance',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: KySheetColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: KySheetColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              detail,
              style: const TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

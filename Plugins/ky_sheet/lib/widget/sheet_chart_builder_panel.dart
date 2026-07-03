import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sheet_chart.dart';
import '../state/sheet_chart_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_chart_preview.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for previewing chart data from the active selection.
class SheetChartBuilderPanel extends ConsumerWidget {
  const SheetChartBuilderPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedCellProvider);
    final spec = ref.watch(sheetChartSpecProvider);
    final data = ref.watch(sheetChartDataProvider);

    return SheetSidebarPanelSurface(
      icon: Icons.insert_chart_outlined,
      title: 'Chart Builder',
      subtitle: 'Visualize selection',
      trailing: SheetSidebarPanelLabelBadge(label: selection?.label ?? 'None'),
      onClose: onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SegmentedButton<SheetChartType>(
            segments: const [
              ButtonSegment(
                value: SheetChartType.bar,
                icon: Icon(Icons.bar_chart, size: 16),
                label: Text('Bar'),
              ),
              ButtonSegment(
                value: SheetChartType.line,
                icon: Icon(Icons.show_chart, size: 16),
                label: Text('Line'),
              ),
              ButtonSegment(
                value: SheetChartType.pie,
                icon: Icon(Icons.donut_small, size: 16),
                label: Text('Pie'),
              ),
            ],
            selected: {spec.type},
            showSelectedIcon: false,
            onSelectionChanged: (next) =>
                _updateSpec(ref, spec.copyWith(type: next.first)),
          ),
          const SizedBox(height: 12),
          _OptionSwitch(
            label: 'Header row',
            value: spec.useFirstRowAsHeaders,
            onChanged: (value) =>
                _updateSpec(ref, spec.copyWith(useFirstRowAsHeaders: value)),
          ),
          _OptionSwitch(
            label: 'Label column',
            value: spec.useFirstColumnAsLabels,
            onChanged: (value) =>
                _updateSpec(ref, spec.copyWith(useFirstColumnAsLabels: value)),
          ),
          const SizedBox(height: 12),
          SheetChartPreview(data: data, type: spec.type),
          const SizedBox(height: 14),
          _ChartStats(data: data, spec: spec),
          if (data.series.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SeriesList(data: data),
          ],
        ],
      ),
    );
  }

  void _updateSpec(WidgetRef ref, SheetChartSpec spec) {
    ref.read(sheetChartSpecProvider.notifier).state = spec;
  }
}

/// Boolean chart option row.
class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Summary card for selected chart type and data volume.
class _ChartStats extends StatelessWidget {
  const _ChartStats({required this.data, required this.spec});

  final SheetChartData data;
  final SheetChartSpec spec;

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
        child: Row(
          children: [
            _Stat(label: 'Type', value: spec.typeLabel),
            const SizedBox(width: 10),
            _Stat(label: 'Series', value: data.series.length.toString()),
            const SizedBox(width: 10),
            _Stat(label: 'Points', value: data.pointCount.toString()),
          ],
        ),
      ),
    );
  }
}

/// Compact label and value metric for chart summaries.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Series summary list for the generated chart data.
class _SeriesList extends StatelessWidget {
  const _SeriesList({required this.data});

  final SheetChartData data;

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
            const Row(
              children: [
                Icon(
                  Icons.stacked_line_chart,
                  color: KySheetColors.mutedText,
                  size: 17,
                ),
                SizedBox(width: 7),
                Text(
                  'Series',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final series in data.series) ...[
              _SeriesTile(series: series),
              if (series != data.series.last) const SizedBox(height: 7),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single generated chart series row.
class _SeriesTile extends StatelessWidget {
  const _SeriesTile({required this.series});

  final SheetChartSeries series;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            series.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '${series.points.length} pts',
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

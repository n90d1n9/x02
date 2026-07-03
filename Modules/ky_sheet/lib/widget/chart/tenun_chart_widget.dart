import 'package:flutter/material.dart';
import 'package:tenun/tenun.dart';

import '../../model/sheet_chart.dart';
import '../../theme/ky_sheet_theme.dart';

/// Advanced chart widget using Tenun library for high-performance rendering.
///
/// Supports all major chart types with smooth animations and interactive features.
class TenunChartWidget extends StatefulWidget {
  const TenunChartWidget({
    super.key,
    required this.data,
    required this.type,
    this.width,
    this.height,
    this.showLegend = true,
    this.showTitle = false,
    this.title,
    this.animate = true,
  });

  final SheetChartData data;
  final SheetChartType type;
  final double? width;
  final double? height;
  final bool showLegend;
  final bool showTitle;
  final String? title;
  final bool animate;

  @override
  State<TenunChartWidget> createState() => _TenunChartWidgetState();
}

class _TenunChartWidgetState extends State<TenunChartWidget> {
  @override
  Widget build(BuildContext context) {
    if (!widget.data.hasData) {
      return _buildEmptyChart();
    }

    final chartWidget = _buildChart();

    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showTitle && widget.title != null) ...[
            Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: KySheetColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: chartWidget),
          if (widget.showLegend) ...[const SizedBox(height: 8), _buildLegend()],
        ],
      ),
    );
  }

  Widget _buildChart() {
    // Convert SheetChartData to Tenun-compatible format
    final categories = widget.data.primaryPoints.map((p) => p.label).toList();
    final seriesList = widget.data.series.map((series) {
      return ChartSeries(
        name: series.label,
        values: series.points.map((p) => p.value).toList(),
      );
    }).toList();

    switch (widget.type) {
      case SheetChartType.bar:
        return _buildBarChart(categories, seriesList);
      case SheetChartType.line:
        return _buildLineChart(categories, seriesList);
      case SheetChartType.pie:
        return _buildPieChart(seriesList);
    }
  }

  Widget _buildBarChart(List<String> categories, List<ChartSeries> seriesList) {
    return BarChart(
      data: ChartData(
        labels: categories,
        datasets: seriesList
            .map(
              (s) => ChartDataset(
                label: s.name,
                data: s.values,
                backgroundColor: _getChartColors()
                    .take(s.values.length)
                    .toList(),
              ),
            )
            .toList(),
      ),
      options: BarChartOptions(
        responsive: true,
        animation: widget.animate
            ? const ChartAnimation(duration: Duration(milliseconds: 600))
            : null,
        barOptions: const BarOptions(
          barThickness: 20,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List<String> categories,
    List<ChartSeries> seriesList,
  ) {
    return LineChart(
      data: ChartData(
        labels: categories,
        datasets: seriesList
            .map(
              (s) => ChartDataset(
                label: s.name,
                data: s.values,
                borderColor: _getChartColors()[seriesList.indexOf(s)],
                backgroundColor: _getChartColors()[seriesList.indexOf(s)]
                    .withOpacity(0.1),
                fill: false,
              ),
            )
            .toList(),
      ),
      options: LineChartOptions(
        responsive: true,
        animation: widget.animate
            ? const ChartAnimation(duration: Duration(milliseconds: 600))
            : null,
        lineOptions: const LineOptions(
          tension: 0.3,
          pointRadius: 4,
          pointHoverRadius: 6,
        ),
      ),
    );
  }

  Widget _buildPieChart(List<ChartSeries> seriesList) {
    if (seriesList.isEmpty || seriesList.first.values.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final firstSeries = seriesList.first;
    final categories = widget.data.primaryPoints.map((p) => p.label).toList();

    return PieChart(
      data: ChartData(
        labels: categories.isEmpty
            ? List.generate(firstSeries.values.length, (i) => 'Item ${i + 1}')
            : categories,
        datasets: [
          ChartDataset(
            label: firstSeries.name,
            data: firstSeries.values,
            backgroundColor: _getChartColors()
                .take(firstSeries.values.length)
                .toList(),
          ),
        ],
      ),
      options: PieChartOptions(
        responsive: true,
        animation: widget.animate
            ? const ChartAnimation(duration: Duration(milliseconds: 600))
            : null,
        pieOptions: const PieOptions(cutout: '0%'),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: KySheetColors.mutedText.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No numeric chart data',
            style: TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select cells with numeric values',
            style: TextStyle(
              color: KySheetColors.mutedText.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final labels = widget.type == SheetChartType.pie
        ? widget.data.series.firstOrNull?.points
                  .map((p) => p.label)
                  .take(6)
                  .toList() ??
              []
        : widget.data.series.map((s) => s.label).take(6).toList();

    if (labels.isEmpty) return const SizedBox.shrink();

    final colors = _getChartColors();

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < labels.length && i < colors.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  labels[i],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: KySheetColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<Color> _getChartColors() {
    return const [
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEF4444), // Red
      Color(0xFF8B5CF6), // Violet
      Color(0xFFEC4899), // Pink
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF97316), // Orange
    ];
  }
}

/// Helper class for chart series data
class ChartSeries {
  ChartSeries({required this.name, required this.values});

  final String name;
  final List<double> values;
}

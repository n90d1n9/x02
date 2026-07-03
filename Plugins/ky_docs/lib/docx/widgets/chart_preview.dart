import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/chart_type.dart';
import 'lince_chart_painter.dart';

class DocxChartPreview extends StatelessWidget {
  final ChartData chart;
  final VoidCallback onDelete;

  const DocxChartPreview({
    super.key,
    required this.chart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_chartIcon(chart.type), size: 18, color: chart.color),
                const SizedBox(width: 8),
                Text(
                  chart.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 150, child: _ChartCanvas(chart: chart)),
          ],
        ),
      ),
    );
  }

  IconData _chartIcon(ChartType type) {
    switch (type) {
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.pie:
        return Icons.pie_chart;
      case ChartType.doughnut:
        return Icons.donut_small;
    }
  }
}

class _ChartCanvas extends StatelessWidget {
  final ChartData chart;

  const _ChartCanvas({required this.chart});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(8), child: _buildChart());
  }

  Widget _buildChart() {
    switch (chart.type) {
      case ChartType.bar:
        return _BarChartPreview(chart: chart);
      case ChartType.line:
        return _LineChartPreview(chart: chart);
      case ChartType.pie:
        return _PieChartPreview(chart: chart);
      case ChartType.doughnut:
        return _DoughnutChartPreview(chart: chart);
    }
  }
}

class _BarChartPreview extends StatelessWidget {
  final ChartData chart;

  const _BarChartPreview({required this.chart});

  @override
  Widget build(BuildContext context) {
    final maxValue = chart.values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: chart.values.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final height = (value / maxValue) * 100;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [chart.color, chart.color.withValues(alpha: 0.6)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: chart.color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chart.labels[index],
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LineChartPreview extends StatelessWidget {
  final ChartData chart;

  const _LineChartPreview({required this.chart});

  @override
  Widget build(BuildContext context) {
    final maxValue = chart.values.reduce((a, b) => a > b ? a : b);
    final minValue = chart.values.reduce((a, b) => a < b ? a : b);

    return CustomPaint(
      painter: LineChartPainter(
        points: chart.values,
        labels: chart.labels,
        color: chart.color,
        maxValue: maxValue,
        minValue: minValue,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PieChartPreview extends StatelessWidget {
  final ChartData chart;

  const _PieChartPreview({required this.chart});

  @override
  Widget build(BuildContext context) {
    final total = chart.values.reduce((a, b) => a + b);
    final colors = _generateColors(chart.values.length, chart.color);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CustomPaint(
            painter: PieChartPainter(
              values: chart.values,
              colors: colors,
              total: total,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chart.labels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final value = chart.values[index];
              final percentage = (value / total * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$label: $percentage%',
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DoughnutChartPreview extends StatelessWidget {
  final ChartData chart;

  const _DoughnutChartPreview({required this.chart});

  @override
  Widget build(BuildContext context) {
    final total = chart.values.reduce((a, b) => a + b);
    final colors = _generateColors(chart.values.length, chart.color);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CustomPaint(
            painter: DoughnutChartPainter(
              values: chart.values,
              colors: colors,
              total: total,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chart.labels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final value = chart.values[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$label: ${value.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

List<Color> _generateColors(int count, Color baseColor) {
  return List.generate(count, (index) {
    final blue = baseColor.toARGB32() & 0xFF;
    final hue = (blue + (index * 360 / count)) % 360;
    return HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor();
  });
}

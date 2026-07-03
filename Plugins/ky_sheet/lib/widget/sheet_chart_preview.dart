import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/sheet_chart.dart';
import '../theme/ky_sheet_theme.dart';

class SheetChartPreview extends StatelessWidget {
  const SheetChartPreview({super.key, required this.data, required this.type});

  final SheetChartData data;
  final SheetChartType type;

  @override
  Widget build(BuildContext context) {
    if (!data.hasData) return const _EmptyChartPreview();

    final painter = switch (type) {
      SheetChartType.bar => _BarChartPainter(data),
      SheetChartType.line => _LineChartPainter(data),
      SheetChartType.pie => _PieChartPainter(data.primaryPoints),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 170,
              child: CustomPaint(
                key: const ValueKey('ky-sheet-chart-preview-canvas'),
                painter: painter,
              ),
            ),
            const SizedBox(height: 10),
            _ChartLegend(series: data.series, type: type),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.series, required this.type});

  final List<SheetChartSeries> series;
  final SheetChartType type;

  @override
  Widget build(BuildContext context) {
    final labels = type == SheetChartType.pie
        ? series.first.points.map((point) => point.label).take(4).toList()
        : series.map((series) => series.label).take(4).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (var index = 0; index < labels.length; index++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _chartColors[index % _chartColors.length],
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const SizedBox.square(dimension: 9),
              ),
              const SizedBox(width: 5),
              Text(
                labels[index],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KySheetColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter(this.data);

  final SheetChartData data;

  @override
  void paint(Canvas canvas, Size size) {
    final series = data.series
        .where((series) => series.points.isNotEmpty)
        .toList();
    if (series.isEmpty) return;

    final maxValue = math.max(data.maxValue, 1);
    final paint = Paint()..style = PaintingStyle.fill;
    final categories = data.primaryPoints.map((point) => point.label).toList();
    final groupWidth = size.width / math.max(categories.length, 1);
    final barWidth = math.min(
      18.0,
      (groupWidth - 8) / math.max(series.length, 1),
    );

    _drawGuideLines(canvas, size);

    for (
      var categoryIndex = 0;
      categoryIndex < categories.length;
      categoryIndex++
    ) {
      final groupLeft = categoryIndex * groupWidth;
      for (var seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
        final value = _pointValueForCategory(
          series[seriesIndex],
          categories[categoryIndex],
        );
        if (value == null) continue;

        final barHeight = (value / maxValue) * (size.height - 16);
        final left =
            groupLeft +
            4 +
            (seriesIndex * barWidth) +
            ((groupWidth - (barWidth * series.length)) / 2);
        paint.color = _chartColors[seriesIndex % _chartColors.length];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              left,
              size.height - barHeight,
              barWidth - 2,
              barHeight,
            ),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }

  double? _pointValueForCategory(SheetChartSeries series, String label) {
    for (final point in series.points) {
      if (point.label == label) return point.value;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.data);

  final SheetChartData data;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(data.maxValue, 1);
    _drawGuideLines(canvas, size);

    for (var seriesIndex = 0; seriesIndex < data.series.length; seriesIndex++) {
      final points = data.series[seriesIndex].points;
      if (points.isEmpty) continue;

      final path = Path();
      final strokePaint = Paint()
        ..color = _chartColors[seriesIndex % _chartColors.length]
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dotPaint = Paint()
        ..color = _chartColors[seriesIndex % _chartColors.length]
        ..style = PaintingStyle.fill;

      for (var index = 0; index < points.length; index++) {
        final x = points.length == 1
            ? size.width / 2
            : (index / (points.length - 1)) * size.width;
        final y =
            size.height -
            ((points[index].value / maxValue) * (size.height - 16));
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      }

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter(this.points);

  final List<SheetChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final usablePoints = points.where((point) => point.value > 0).toList();
    final total = usablePoints.fold<double>(
      0,
      (sum, point) => sum + point.value,
    );
    if (usablePoints.isEmpty || total <= 0) return;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2.4,
    );
    final paint = Paint()..style = PaintingStyle.fill;
    var start = -math.pi / 2;

    for (var index = 0; index < usablePoints.length; index++) {
      final sweep = (usablePoints[index].value / total) * math.pi * 2;
      paint.color = _chartColors[index % _chartColors.length];
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }

    paint
      ..color = KySheetColors.surfaceMuted
      ..style = PaintingStyle.fill;
    canvas.drawCircle(rect.center, rect.width * 0.18, paint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _EmptyChartPreview extends StatelessWidget {
  const _EmptyChartPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const SizedBox(
        height: 190,
        child: Center(
          child: Text(
            'No numeric chart data',
            style: TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

void _drawGuideLines(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = KySheetColors.gridLine
    ..strokeWidth = 1;
  for (var index = 1; index <= 3; index++) {
    final y = size.height * (index / 4);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
}

const _chartColors = [
  Color(0xFF2563EB),
  Color(0xFF0891B2),
  Color(0xFFF59E0B),
  Color(0xFF16A34A),
  Color(0xFFDC2626),
];

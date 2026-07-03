import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/chart_data.dart';

class LineChartPainter extends CustomPainter {
  final ChartData data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.values.reduce(math.max);
    final path = Path();
    final paint = Paint()
      ..color = data.colors.first
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < data.values.length; i++) {
      final x = (i / (data.values.length - 1)) * size.width;
      final y =
          size.height - (data.values[i] / maxValue) * (size.height - 40) - 20;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      final circlePaint = Paint()
        ..shader = RadialGradient(
          colors: [data.colors.first, data.colors.first.withValues(alpha: 0.5)],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 6));

      canvas.drawCircle(Offset(x, y), 6, circlePaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) => false;
}

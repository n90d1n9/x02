import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/chart_data.dart';

class PieChartPainter extends CustomPainter {
  final ChartData data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final total = data.values.reduce((a, b) => a + b);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.values.length; i++) {
      final sweepAngle = (data.values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            data.colors[i % data.colors.length],
            data.colors[i % data.colors.length].withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) => false;
}

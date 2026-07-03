import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chart_data.dart';

class BarChartPainter extends CustomPainter {
  final ChartData data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.values.reduce(math.max);
    final barWidth = size.width / (data.values.length * 2);
    final spacing = barWidth * 0.5;

    for (int i = 0; i < data.values.length; i++) {
      final barHeight = (data.values[i] / maxValue) * (size.height - 40);
      final x = i * (barWidth + spacing) + spacing;
      final y = size.height - barHeight - 20;

      final gradient = LinearGradient(
        colors: [
          data.colors[i % data.colors.length],
          data.colors[i % data.colors.length].withValues(alpha: 0.6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x, y, barWidth, barHeight),
        );

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: data.labels[i],
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) => false;
}

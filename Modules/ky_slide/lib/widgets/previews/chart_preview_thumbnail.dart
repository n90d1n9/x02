import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/enums.dart';

class ChartPreviewThumbnail extends StatelessWidget {
  final ChartType type;
  final List<Color> colors;

  const ChartPreviewThumbnail({
    super.key,
    required this.type,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _colorAt(0).withValues(alpha: 0.34)),
        ),
        child: CustomPaint(
          painter: _ChartPreviewPainter(type: type, colors: _resolvedColors),
        ),
      ),
    );
  }

  List<Color> get _resolvedColors {
    if (colors.isNotEmpty) return colors;
    return const [Color(0xFF38BDF8), Color(0xFF22C55E), Color(0xFFF59E0B)];
  }

  Color _colorAt(int index) {
    final resolved = _resolvedColors;
    return resolved[index % resolved.length];
  }
}

class _ChartPreviewPainter extends CustomPainter {
  final ChartType type;
  final List<Color> colors;

  const _ChartPreviewPainter({required this.type, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case ChartType.bar:
        _paintBars(canvas, size);
      case ChartType.pie:
        _paintPie(canvas, size);
      default:
        _paintLine(canvas, size);
    }
  }

  void _paintBars(Canvas canvas, Size size) {
    final values = [0.48, 0.78, 0.58, 0.9];
    final gap = size.width * 0.08;
    final barWidth = (size.width - gap * (values.length - 1)) / values.length;

    for (var index = 0; index < values.length; index++) {
      final height = size.height * values[index];
      final left = index * (barWidth + gap);
      final top = size.height - height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = _colorAt(index, 0.72));
    }
  }

  void _paintLine(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.24, size.height * 0.52),
      Offset(size.width * 0.48, size.height * 0.64),
      Offset(size.width * 0.72, size.height * 0.32),
      Offset(size.width, size.height * 0.24),
    ];

    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = _colorAt(1, 0.18));

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _colorAt(0, 0.86)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2,
    );
  }

  void _paintPie(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final values = [0.42, 0.28, 0.2, 0.1];
    var startAngle = -math.pi / 2;

    for (var index = 0; index < values.length; index++) {
      final sweepAngle = values[index] * math.pi * 2;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        Paint()..color = _colorAt(index, 0.76),
      );
      startAngle += sweepAngle;
    }
  }

  Color _colorAt(int index, double alpha) {
    return colors[index % colors.length].withValues(alpha: alpha);
  }

  @override
  bool shouldRepaint(covariant _ChartPreviewPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.colors != colors;
  }
}

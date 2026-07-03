import 'package:flutter/material.dart';

import '../../models/component.dart';

class ShapePreviewThumbnail extends StatelessWidget {
  final ComponentType type;
  final Color accentColor;

  const ShapePreviewThumbnail({
    super.key,
    required this.type,
    required this.accentColor,
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
          border: Border.all(color: accentColor.withValues(alpha: 0.34)),
        ),
        child: CustomPaint(
          painter: _ShapePreviewPainter(type: type, color: accentColor),
        ),
      ),
    );
  }
}

class _ShapePreviewPainter extends CustomPainter {
  final ComponentType type;
  final Color color;

  const _ShapePreviewPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    switch (type) {
      case ComponentType.circle:
        canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
      case ComponentType.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
      default:
        final roundedRect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(4),
        );
        canvas.drawRRect(roundedRect, fillPaint);
        canvas.drawRRect(roundedRect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePreviewPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}

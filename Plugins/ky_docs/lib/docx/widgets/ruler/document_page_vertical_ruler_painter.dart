import 'package:flutter/material.dart';

import 'document_page_ruler_geometry.dart';
import 'document_page_vertical_ruler_geometry.dart';

/// Paints the vertical ruler background, ticks, shaded margins, and guides.
class DocumentPageVerticalRulerPainter extends CustomPainter {
  final DocumentPageVerticalRulerGeometry geometry;
  final ColorScheme colorScheme;

  const DocumentPageVerticalRulerPainter({
    required this.geometry,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.62);
    final marginPaint = Paint()
      ..color = colorScheme.primaryContainer.withValues(alpha: 0.34);
    final tickPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.62)
      ..strokeWidth = 1;
    final marginLinePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.82)
      ..strokeWidth = 1.4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      backgroundPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, geometry.topMarginY),
      marginPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, geometry.bottomMarginY, size.width, size.height),
      marginPaint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final tick in geometry.ticks()) {
      final tickWidth = _tickWidth(tick.kind);

      canvas.drawLine(
        Offset(size.width, tick.y),
        Offset(size.width - tickWidth, tick.y),
        tickPaint,
      );

      if (tick.kind == DocumentPageRulerTickKind.inch && tick.inchNumber > 0) {
        textPainter.text = TextSpan(
          text: '${tick.inchNumber}',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        );
        textPainter.layout(maxWidth: size.width - 4);
        textPainter.paint(canvas, Offset(3, tick.y - (textPainter.height / 2)));
      }
    }

    canvas.drawLine(
      Offset(0, geometry.topMarginY),
      Offset(size.width, geometry.topMarginY),
      marginLinePaint,
    );
    canvas.drawLine(
      Offset(0, geometry.bottomMarginY),
      Offset(size.width, geometry.bottomMarginY),
      marginLinePaint,
    );
  }

  double _tickWidth(DocumentPageRulerTickKind kind) {
    return switch (kind) {
      DocumentPageRulerTickKind.inch => 18,
      DocumentPageRulerTickKind.halfInch => 13,
      DocumentPageRulerTickKind.quarterInch => 9,
      DocumentPageRulerTickKind.eighthInch => 5,
    };
  }

  @override
  bool shouldRepaint(covariant DocumentPageVerticalRulerPainter oldDelegate) {
    return geometry != oldDelegate.geometry ||
        colorScheme != oldDelegate.colorScheme;
  }
}

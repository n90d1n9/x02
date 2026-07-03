import 'package:flutter/material.dart';

class VerticalRuler extends StatelessWidget {
  final double height;
  final double cursorY;
  final double topMargin;
  final double bottomMargin;

  const VerticalRuler({
    super.key,
    required this.height,
    this.cursorY = 0,
    this.topMargin = 72,
    this.bottomMargin = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: CustomPaint(
        size: Size(30, height),
        painter: VerticalRulerPainter(
          topMargin: topMargin,
          bottomMargin: bottomMargin,
          pageHeight: height,
          cursorY: cursorY,
          color: Theme.of(context).colorScheme.onSurface,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class VerticalRulerPainter extends CustomPainter {
  final double topMargin;
  final double bottomMargin;
  final double pageHeight;
  final double cursorY;
  final Color color;
  final bool isDark;

  VerticalRulerPainter({
    required this.topMargin,
    required this.bottomMargin,
    required this.pageHeight,
    required this.cursorY,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Calculate pixels per inch (96 DPI standard)
    const pixelsPerInch = 96.0;
    final totalInches = (pageHeight / pixelsPerInch).ceil();

    // Draw ruler marks
    for (int i = 0; i <= totalInches * 8; i++) {
      final inches = i / 8.0;
      final y = inches * pixelsPerInch;

      if (y > size.height) break;

      final isInch = i % 8 == 0;
      final isHalfInch = i % 4 == 0;
      final isQuarterInch = i % 2 == 0;

      double lineWidth;
      if (isInch) {
        lineWidth = 20;
        if (i > 0) {
          // Rotate text for vertical ruler
          canvas.save();
          canvas.translate(15, y);
          canvas.rotate(-1.5708); // -90 degrees
          textPainter.text = TextSpan(
            text: '${i ~/ 8}',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(-textPainter.width / 2, -4));
          canvas.restore();
        }
      } else if (isHalfInch) {
        lineWidth = 14;
      } else if (isQuarterInch) {
        lineWidth = 10;
      } else {
        lineWidth = 6;
      }

      canvas.drawLine(
        Offset(size.width - lineWidth, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw margin indicators
    final marginPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Top margin (shaded area)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, topMargin), marginPaint);

    // Bottom margin (shaded area)
    if (pageHeight - bottomMargin < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(0, pageHeight - bottomMargin, size.width, bottomMargin),
        marginPaint,
      );
    }

    // Top margin line
    canvas.drawLine(
      Offset(0, topMargin),
      Offset(size.width, topMargin),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.5,
    );

    // Bottom margin line
    if (pageHeight - bottomMargin < size.height) {
      canvas.drawLine(
        Offset(0, pageHeight - bottomMargin),
        Offset(size.width, pageHeight - bottomMargin),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.5,
      );
    }

    // Draw cursor position indicator
    if (cursorY > 0 && cursorY < size.height) {
      final cursorPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 1;

      // Cursor line
      canvas.drawLine(
        Offset(0, cursorY),
        Offset(size.width, cursorY),
        cursorPaint,
      );

      // Cursor triangle indicator
      final path = Path()
        ..moveTo(0, cursorY - 4)
        ..lineTo(0, cursorY + 4)
        ..lineTo(6, cursorY)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );

      // Cursor position text
      final cursorInches = cursorY / pixelsPerInch;
      canvas.save();
      canvas.translate(15, cursorY);
      canvas.rotate(-1.5708);
      textPainter.text = TextSpan(
        text: '${cursorInches.toStringAsFixed(2)}"',
        style: TextStyle(
          color: Colors.red,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          backgroundColor: isDark ? Colors.black87 : Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 8));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(VerticalRulerPainter oldDelegate) {
    return oldDelegate.cursorY != cursorY ||
        oldDelegate.pageHeight != pageHeight;
  }
}

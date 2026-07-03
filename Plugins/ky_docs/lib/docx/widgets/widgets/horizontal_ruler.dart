import 'package:flutter/material.dart';

class HorizontalRuler extends StatelessWidget {
  final double width;
  final double cursorX;
  final double leftMargin;
  final double rightMargin;

  const HorizontalRuler({
    super.key,
    required this.width,
    this.cursorX = 0,
    this.leftMargin = 72,
    this.rightMargin = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, 30),
            painter: HorizontalRulerPainter(
              leftMargin: leftMargin,
              rightMargin: rightMargin,
              pageWidth: width,
              cursorX: cursorX,
              color: Theme.of(context).colorScheme.onSurface,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          );
        },
      ),
    );
  }
}

class HorizontalRulerPainter extends CustomPainter {
  final double leftMargin;
  final double rightMargin;
  final double pageWidth;
  final double cursorX;
  final Color color;
  final bool isDark;

  HorizontalRulerPainter({
    required this.leftMargin,
    required this.rightMargin,
    required this.pageWidth,
    required this.cursorX,
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
    final totalInches = (pageWidth / pixelsPerInch).ceil();

    // Draw ruler marks
    for (int i = 0; i <= totalInches * 8; i++) {
      final inches = i / 8.0;
      final x = inches * pixelsPerInch;

      if (x > size.width) break;

      final isInch = i % 8 == 0;
      final isHalfInch = i % 4 == 0;
      final isQuarterInch = i % 2 == 0;

      double lineHeight;
      if (isInch) {
        lineHeight = 20;
        if (i > 0) {
          textPainter.text = TextSpan(
            text: '${i ~/ 8}',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, 2));
        }
      } else if (isHalfInch) {
        lineHeight = 14;
      } else if (isQuarterInch) {
        lineHeight = 10;
      } else {
        lineHeight = 6;
      }

      canvas.drawLine(
        Offset(x, size.height - lineHeight),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw margin indicators
    final marginPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Left margin (shaded area)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, leftMargin, size.height),
      marginPaint..color = Colors.blue.withValues(alpha: 0.1),
    );

    // Right margin (shaded area)
    if (pageWidth - rightMargin < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(pageWidth - rightMargin, 0, rightMargin, size.height),
        marginPaint..color = Colors.blue.withValues(alpha: 0.1),
      );
    }

    // Left margin line
    canvas.drawLine(
      Offset(leftMargin, 0),
      Offset(leftMargin, size.height),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.5,
    );

    // Right margin line
    if (pageWidth - rightMargin < size.width) {
      canvas.drawLine(
        Offset(pageWidth - rightMargin, 0),
        Offset(pageWidth - rightMargin, size.height),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.5,
      );
    }

    // Draw cursor position indicator
    if (cursorX > 0 && cursorX < size.width) {
      final cursorPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 1;

      // Cursor line
      canvas.drawLine(
        Offset(cursorX, 0),
        Offset(cursorX, size.height),
        cursorPaint,
      );

      // Cursor triangle indicator
      final path = Path()
        ..moveTo(cursorX - 4, 0)
        ..lineTo(cursorX + 4, 0)
        ..lineTo(cursorX, 6)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill,
      );

      // Cursor position text
      final cursorInches = cursorX / pixelsPerInch;
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
      final textX = (cursorX + textPainter.width + 4 > size.width)
          ? cursorX - textPainter.width - 4
          : cursorX + 4;
      textPainter.paint(canvas, Offset(textX, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(HorizontalRulerPainter oldDelegate) {
    return oldDelegate.cursorX != cursorX || oldDelegate.pageWidth != pageWidth;
  }
}

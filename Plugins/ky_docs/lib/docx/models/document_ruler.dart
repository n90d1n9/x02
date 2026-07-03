import 'package:flutter/material.dart';

class DocumentRuler extends StatelessWidget {
  final double pageWidth;
  final double leftMargin;
  final double rightMargin;

  const DocumentRuler({
    super.key,
    this.pageWidth = 800,
    this.leftMargin = 72,
    this.rightMargin = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: CustomPaint(
        size: Size(pageWidth, 30),
        painter: RulerPainter(
          leftMargin: leftMargin,
          rightMargin: rightMargin,
          pageWidth: pageWidth,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class RulerPainter extends CustomPainter {
  final double leftMargin;
  final double rightMargin;
  final double pageWidth;
  final Color color;

  RulerPainter({
    required this.leftMargin,
    required this.rightMargin,
    required this.pageWidth,
    required this.color,
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

    // Draw ruler marks
    for (int i = 0; i <= pageWidth / 10; i++) {
      final x = i * 10.0;
      final isInch = i % 10 == 0;
      final isHalfInch = i % 5 == 0;

      double lineHeight;
      if (isInch) {
        lineHeight = 20;
        // Draw number
        if (i > 0) {
          textPainter.text = TextSpan(
            text: '${i ~/ 10}',
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, 2));
        }
      } else if (isHalfInch) {
        lineHeight = 12;
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
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    // Left margin
    canvas.drawLine(
      Offset(leftMargin, 0),
      Offset(leftMargin, size.height),
      marginPaint,
    );

    // Right margin
    canvas.drawLine(
      Offset(pageWidth - rightMargin, 0),
      Offset(pageWidth - rightMargin, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(RulerPainter oldDelegate) => false;
}

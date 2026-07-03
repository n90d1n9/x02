import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Horizontal measurement rail for the slide workspace.
class HorizontalRuler extends StatelessWidget {
  final double width;
  final double cursorX;

  const HorizontalRuler({super.key, required this.width, this.cursorX = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF181B20),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, 30),
            painter: HorizontalRulerPainter(pageWidth: width, cursorX: cursorX),
          );
        },
      ),
    );
  }
}

/// Painter for inch-based horizontal ruler ticks and cursor position.
class HorizontalRulerPainter extends CustomPainter {
  final double pageWidth;
  final double cursorX;

  HorizontalRulerPainter({required this.pageWidth, required this.cursorX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    const pixelsPerInch = 96.0;
    final totalInches = (size.width / pixelsPerInch).ceil();

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
            style: const TextStyle(
              color: Colors.white70,
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

    if (cursorX > 0 && cursorX < size.width) {
      final cursorPaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(cursorX, 0),
        Offset(cursorX, size.height),
        cursorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(HorizontalRulerPainter oldDelegate) {
    return oldDelegate.cursorX != cursorX || oldDelegate.pageWidth != pageWidth;
  }
}

@Preview(name: 'Horizontal ruler', size: Size(520, 80))
Widget horizontalRulerPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF101114),
      body: Center(child: HorizontalRuler(width: 960, cursorX: 160)),
    ),
  );
}

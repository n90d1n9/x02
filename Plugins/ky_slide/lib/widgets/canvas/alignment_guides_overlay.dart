import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/alignment_guide.dart';

/// Canvas overlay that paints active smart alignment guide lines.
class AlignmentGuidesOverlay extends StatelessWidget {
  final List<AlignmentGuide> guides;
  final Size slideSize;

  const AlignmentGuidesOverlay({
    super.key,
    required this.guides,
    required this.slideSize,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: slideSize.width,
        height: slideSize.height,
        child: CustomPaint(painter: _AlignmentGuidesPainter(guides)),
      ),
    );
  }
}

/// Painter for dashed horizontal and vertical smart guide lines.
class _AlignmentGuidesPainter extends CustomPainter {
  final List<AlignmentGuide> guides;

  const _AlignmentGuidesPainter(this.guides);

  @override
  void paint(Canvas canvas, Size size) {
    final slidePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.4;
    final objectPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 1.2;

    for (final guide in guides) {
      final paint = guide.source == AlignmentGuideSource.slide
          ? slidePaint
          : objectPaint;
      switch (guide.axis) {
        case AlignmentGuideAxis.vertical:
          _drawDashedLine(
            canvas,
            Offset(guide.position, 0),
            Offset(guide.position, size.height),
            paint,
          );
          break;
        case AlignmentGuideAxis.horizontal:
          _drawDashedLine(
            canvas,
            Offset(0, guide.position),
            Offset(size.width, guide.position),
            paint,
          );
          break;
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 9.0;
    const gap = 6.0;
    final delta = end - start;
    final distance = delta.distance;
    if (distance <= 0) return;

    final direction = delta / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final segmentEnd = (drawn + dash).clamp(0.0, distance);
      canvas.drawLine(
        start + direction * drawn,
        start + direction * segmentEnd,
        paint,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _AlignmentGuidesPainter oldDelegate) {
    return oldDelegate.guides != guides;
  }
}

@Preview(name: 'Alignment guides overlay', size: Size(420, 260))
Widget alignmentGuidesOverlayPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: Container(
          width: 360,
          height: 200,
          color: const Color(0xFF0F172A),
          child: AlignmentGuidesOverlay(
            slideSize: const Size(360, 200),
            guides: const [
              AlignmentGuide(
                axis: AlignmentGuideAxis.vertical,
                source: AlignmentGuideSource.slide,
                position: 180,
                label: 'Slide center',
              ),
              AlignmentGuide(
                axis: AlignmentGuideAxis.horizontal,
                source: AlignmentGuideSource.object,
                position: 92,
                label: 'Object alignment',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

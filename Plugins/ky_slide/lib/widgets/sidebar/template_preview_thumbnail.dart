import 'package:flutter/material.dart';

import '../../models/slide_template.dart';

class TemplatePreviewThumbnail extends StatelessWidget {
  final SlideTemplateType type;
  final Color accentColor;
  final Color secondaryColor;

  const TemplatePreviewThumbnail({
    super.key,
    required this.type,
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF020617),
              accentColor.withValues(alpha: 0.22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        ),
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    switch (type) {
      case SlideTemplateType.executiveCover:
        return Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.34,
                heightFactor: 0.76,
                child: _block(Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.58,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(widthFactor: 0.35, height: 3, color: accentColor),
                    const SizedBox(height: 3),
                    _line(widthFactor: 0.92, height: 4),
                    const SizedBox(height: 2),
                    _line(widthFactor: 0.72, height: 4),
                    const SizedBox(height: 3),
                    _line(widthFactor: 0.62, height: 2),
                  ],
                ),
              ),
            ),
          ],
        );
      case SlideTemplateType.agenda:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(widthFactor: 0.46, height: 4),
            const SizedBox(height: 4),
            ...List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: index == 3 ? 0 : 2),
                  child: Row(
                    children: [
                      _dot(index == 0 ? accentColor : secondaryColor),
                      const SizedBox(width: 3),
                      Expanded(
                        child: _block(Colors.white.withValues(alpha: 0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case SlideTemplateType.metricStory:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(widthFactor: 0.5, height: 4),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: index == 2 ? 0 : 3,
                            ),
                            child: _block(
                              (index == 0 ? accentColor : Colors.white)
                                  .withValues(alpha: index == 0 ? 0.22 : 0.1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: CustomPaint(
                      painter: _MiniChartPainter(
                        lineColor: accentColor,
                        fillColor: secondaryColor.withValues(alpha: 0.16),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case SlideTemplateType.comparison:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(widthFactor: 0.62, height: 4),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _comparisonColumn(accentColor)),
                  const SizedBox(width: 4),
                  Expanded(child: _comparisonColumn(secondaryColor)),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _comparisonColumn(Color color) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(widthFactor: 0.48, height: 2.5, color: color),
          const SizedBox(height: 1.5),
          _line(widthFactor: 0.86, height: 2),
          const SizedBox(height: 1.5),
          _line(widthFactor: 0.64, height: 2),
        ],
      ),
    );
  }

  Widget _line({
    required double widthFactor,
    required double height,
    Color? color,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: _block(
        color ?? Colors.white.withValues(alpha: 0.72),
        height: height,
      ),
    );
  }

  Widget _block(Color color, {double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;

  const _MiniChartPainter({required this.lineColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    final points = [
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.22, size.height * 0.58),
      Offset(size.width * 0.45, size.height * 0.68),
      Offset(size.width * 0.68, size.height * 0.34),
      Offset(size.width, size.height * 0.25),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

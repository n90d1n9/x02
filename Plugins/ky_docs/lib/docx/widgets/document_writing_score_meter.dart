import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/document_writing_insights.dart';

class DocumentWritingScoreMeter extends StatelessWidget {
  final DocumentWritingInsights insights;
  final double size;

  const DocumentWritingScoreMeter({
    super.key,
    required this.insights,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, insights.score);

    return Semantics(
      container: true,
      label:
          'Writing score ${insights.score} out of 100, ${insights.qualityLabel}',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _ScoreMeterPainter(
                  progress: insights.score.clamp(0, 100) / 100,
                  color: color,
                  trackColor: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.52),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${insights.score}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(BuildContext context, int score) {
    final colorScheme = Theme.of(context).colorScheme;
    if (score >= 88) return colorScheme.primary;
    if (score >= 72) return colorScheme.tertiary;
    return colorScheme.error;
  }
}

class _ScoreMeterPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ScoreMeterPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = math.max(5.0, size.width * 0.08);
    final rect = Offset.zero & size;
    final insetRect = rect.deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(insetRect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
      insetRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreMeterPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor;
  }
}

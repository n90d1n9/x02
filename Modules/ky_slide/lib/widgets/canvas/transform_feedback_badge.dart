import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/transform_feedback.dart';

/// Compact canvas badge that reports move, resize, or rotation measurements.
class TransformFeedbackBadge extends StatelessWidget {
  static const double _visualWidth = 178;
  static const double _visualHeight = 30;
  static const double _visualGap = 12;

  final TransformFeedback feedback;
  final Size slideSize;
  final double zoom;

  const TransformFeedbackBadge({
    super.key,
    required this.feedback,
    required this.slideSize,
    required this.zoom,
  });

  @override
  Widget build(BuildContext context) {
    final safeZoom = math.max(zoom, 0.1);
    final logicalPadding = 8 / safeZoom;
    final badgeLogicalWidth = _visualWidth / safeZoom;
    final badgeLogicalHeight = _visualHeight / safeZoom;
    final preferredTop = _preferredTop(safeZoom);
    final fallbackTop =
        feedback.position.dy + feedback.size.height + (_visualGap / safeZoom);
    final top = preferredTop >= logicalPadding
        ? preferredTop
        : math.min(
            math.max(logicalPadding, fallbackTop),
            math.max(logicalPadding, slideSize.height - badgeLogicalHeight),
          );
    final left =
        (feedback.position.dx +
                (feedback.size.width / 2) -
                (badgeLogicalWidth / 2))
            .clamp(
              logicalPadding,
              math.max(logicalPadding, slideSize.width - badgeLogicalWidth),
            );

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: IgnorePointer(
        child: Transform.scale(
          alignment: Alignment.topLeft,
          scale: 1 / safeZoom,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: _visualWidth,
              height: _visualHeight,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF020617).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_icon, color: _accentColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    _label,
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _preferredTop(double safeZoom) {
    final aboveObject =
        feedback.position.dy - ((_visualHeight + _visualGap) / safeZoom);
    if (feedback.mode != TransformFeedbackMode.rotate) return aboveObject;

    return aboveObject - (24 / safeZoom);
  }

  Color get _accentColor {
    return switch (feedback.mode) {
      TransformFeedbackMode.move => const Color(0xFF38BDF8),
      TransformFeedbackMode.resize => const Color(0xFF22C55E),
      TransformFeedbackMode.rotate => const Color(0xFF14B8A6),
    };
  }

  IconData get _icon {
    return switch (feedback.mode) {
      TransformFeedbackMode.move => Icons.open_with,
      TransformFeedbackMode.resize => Icons.aspect_ratio,
      TransformFeedbackMode.rotate => Icons.rotate_right,
    };
  }

  String get _label {
    return switch (feedback.mode) {
      TransformFeedbackMode.move => 'MOVE',
      TransformFeedbackMode.resize => 'SIZE',
      TransformFeedbackMode.rotate => 'ROTATE',
    };
  }

  String get _value {
    return switch (feedback.mode) {
      TransformFeedbackMode.move =>
        'X ${feedback.position.dx.round()}  Y ${feedback.position.dy.round()}',
      TransformFeedbackMode.resize =>
        'W ${feedback.size.width.round()}  H ${feedback.size.height.round()}',
      TransformFeedbackMode.rotate => '${feedback.rotation.round()} deg',
    };
  }
}

@Preview(name: 'Transform feedback badge', size: Size(420, 260))
Widget transformFeedbackBadgePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SizedBox(
          width: 360,
          height: 200,
          child: Stack(
            children: const [
              Positioned(
                left: 120,
                top: 76,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF1D4ED8)),
                  child: SizedBox(width: 110, height: 56),
                ),
              ),
              TransformFeedbackBadge(
                feedback: TransformFeedback(
                  mode: TransformFeedbackMode.resize,
                  position: Offset(120, 76),
                  size: Size(110, 56),
                  rotation: 0,
                ),
                slideSize: Size(360, 200),
                zoom: 1,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

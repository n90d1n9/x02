import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/presentation_component.dart';

class SlideSelectionMetricsBadge extends StatelessWidget {
  static const double _visualWidth = 250;
  static const double _visualHeight = 30;
  static const double _visualGap = 10;

  final PresentationComponent component;
  final Size slideSize;
  final double zoom;

  const SlideSelectionMetricsBadge({
    super.key,
    required this.component,
    required this.slideSize,
    required this.zoom,
  });

  @override
  Widget build(BuildContext context) {
    final safeZoom = math.max(zoom, 0.1);
    final logicalPadding = 8 / safeZoom;
    final badgeLogicalWidth = _visualWidth / safeZoom;
    final badgeLogicalHeight = _visualHeight / safeZoom;
    final preferredTop =
        component.position.dy + component.size.height + (_visualGap / safeZoom);
    final fallbackTop =
        component.position.dy - ((_visualHeight + _visualGap) / safeZoom);
    final top = (preferredTop + badgeLogicalHeight <= slideSize.height)
        ? preferredTop
        : math.max(logicalPadding, fallbackTop);
    final left =
        (component.position.dx + component.size.width - badgeLogicalWidth)
            .clamp(
              logicalPadding,
              math.max(logicalPadding, slideSize.width - badgeLogicalWidth),
            );

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: 1 / safeZoom,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _visualWidth,
            height: _visualHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF020617).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricText(label: 'X', value: component.position.dx),
                _MetricText(label: 'Y', value: component.position.dy),
                _MetricText(label: 'W', value: component.size.width),
                _MetricText(label: 'H', value: component.size.height),
                if (component.rotation.round() != 0)
                  _MetricText(label: 'R', value: component.rotation),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  final String label;
  final double value;

  const _MetricText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label ${value.round()}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: 0,
      ),
    );
  }
}

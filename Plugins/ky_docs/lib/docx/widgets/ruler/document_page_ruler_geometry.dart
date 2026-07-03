import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Describes the visual importance of one page ruler tick.
enum DocumentPageRulerTickKind { inch, halfInch, quarterInch, eighthInch }

/// Provides computed positions for print-layout ruler margins and tick marks.
class DocumentPageRulerGeometry {
  static const pointsPerInch = 72.0;
  static const minWritingWidth = 144.0;

  final double pageWidth;
  final double surfaceWidth;
  final double leftMargin;
  final double rightMargin;

  const DocumentPageRulerGeometry({
    required this.pageWidth,
    required this.surfaceWidth,
    required this.leftMargin,
    required this.rightMargin,
  });

  double get scale => pageWidth <= 0 ? 1.0 : surfaceWidth / pageWidth;

  double get leftMarginX => leftMargin * scale;

  double get rightMarginX => surfaceWidth - (rightMargin * scale);

  double get writingWidth => pageWidth - leftMargin - rightMargin;

  double pointsForPixels(double pixels) {
    return scale <= 0 ? pixels : pixels / scale;
  }

  EdgeInsets moveLeftMargin({
    required EdgeInsets margins,
    required double deltaPoints,
  }) {
    final maxLeft = math.max(0.0, pageWidth - margins.right - minWritingWidth);
    final nextLeft = (margins.left + deltaPoints).clamp(0.0, maxLeft);

    return EdgeInsets.fromLTRB(
      nextLeft.toDouble(),
      margins.top,
      margins.right,
      margins.bottom,
    );
  }

  EdgeInsets moveRightMargin({
    required EdgeInsets margins,
    required double deltaPoints,
  }) {
    final maxRight = math.max(0.0, pageWidth - margins.left - minWritingWidth);
    final nextRight = (margins.right - deltaPoints).clamp(0.0, maxRight);

    return EdgeInsets.fromLTRB(
      margins.left,
      margins.top,
      nextRight.toDouble(),
      margins.bottom,
    );
  }

  Iterable<DocumentPageRulerTick> ticks() sync* {
    final totalEighths = (pageWidth / (pointsPerInch / 8)).ceil();
    for (var index = 0; index <= totalEighths; index++) {
      final points = index * (pointsPerInch / 8);
      final x = points * scale;
      if (x > surfaceWidth) break;

      yield DocumentPageRulerTick(
        points: points,
        x: x,
        kind: _tickKindFor(index),
      );
    }
  }

  DocumentPageRulerTickKind _tickKindFor(int index) {
    if (index % 8 == 0) return DocumentPageRulerTickKind.inch;
    if (index % 4 == 0) return DocumentPageRulerTickKind.halfInch;
    if (index % 2 == 0) return DocumentPageRulerTickKind.quarterInch;
    return DocumentPageRulerTickKind.eighthInch;
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentPageRulerGeometry &&
        other.pageWidth == pageWidth &&
        other.surfaceWidth == surfaceWidth &&
        other.leftMargin == leftMargin &&
        other.rightMargin == rightMargin;
  }

  @override
  int get hashCode {
    return Object.hash(pageWidth, surfaceWidth, leftMargin, rightMargin);
  }
}

/// Represents one visible ruler tick after page units are mapped to pixels.
class DocumentPageRulerTick {
  final double points;
  final double x;
  final DocumentPageRulerTickKind kind;

  const DocumentPageRulerTick({
    required this.points,
    required this.x,
    required this.kind,
  });

  int get inchNumber => points ~/ DocumentPageRulerGeometry.pointsPerInch;

  @override
  bool operator ==(Object other) {
    return other is DocumentPageRulerTick &&
        other.points == points &&
        other.x == x &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(points, x, kind);
}

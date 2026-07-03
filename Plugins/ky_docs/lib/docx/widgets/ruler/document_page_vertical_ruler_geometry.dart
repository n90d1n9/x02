import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'document_page_ruler_geometry.dart';

/// Provides computed positions for print-layout vertical ruler margins.
class DocumentPageVerticalRulerGeometry {
  static const minWritingHeight = 144.0;

  final double pageHeight;
  final double surfaceHeight;
  final double topMargin;
  final double bottomMargin;

  const DocumentPageVerticalRulerGeometry({
    required this.pageHeight,
    required this.surfaceHeight,
    required this.topMargin,
    required this.bottomMargin,
  });

  double get scale => pageHeight <= 0 ? 1.0 : surfaceHeight / pageHeight;

  double get topMarginY => topMargin * scale;

  double get bottomMarginY => surfaceHeight - (bottomMargin * scale);

  double get writingHeight => pageHeight - topMargin - bottomMargin;

  double pointsForPixels(double pixels) {
    return scale <= 0 ? pixels : pixels / scale;
  }

  EdgeInsets moveTopMargin({
    required EdgeInsets margins,
    required double deltaPoints,
  }) {
    final maxTop = math.max(
      0.0,
      pageHeight - margins.bottom - minWritingHeight,
    );
    final nextTop = (margins.top + deltaPoints).clamp(0.0, maxTop);

    return EdgeInsets.fromLTRB(
      margins.left,
      nextTop.toDouble(),
      margins.right,
      margins.bottom,
    );
  }

  EdgeInsets moveBottomMargin({
    required EdgeInsets margins,
    required double deltaPoints,
  }) {
    final maxBottom = math.max(
      0.0,
      pageHeight - margins.top - minWritingHeight,
    );
    final nextBottom = (margins.bottom - deltaPoints).clamp(0.0, maxBottom);

    return EdgeInsets.fromLTRB(
      margins.left,
      margins.top,
      margins.right,
      nextBottom.toDouble(),
    );
  }

  Iterable<DocumentPageVerticalRulerTick> ticks() sync* {
    final totalEighths =
        (pageHeight / (DocumentPageRulerGeometry.pointsPerInch / 8)).ceil();
    for (var index = 0; index <= totalEighths; index++) {
      final points = index * (DocumentPageRulerGeometry.pointsPerInch / 8);
      final y = points * scale;
      if (y > surfaceHeight) break;

      yield DocumentPageVerticalRulerTick(
        points: points,
        y: y,
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
    return other is DocumentPageVerticalRulerGeometry &&
        other.pageHeight == pageHeight &&
        other.surfaceHeight == surfaceHeight &&
        other.topMargin == topMargin &&
        other.bottomMargin == bottomMargin;
  }

  @override
  int get hashCode {
    return Object.hash(pageHeight, surfaceHeight, topMargin, bottomMargin);
  }
}

/// Represents one visible vertical ruler tick after page units map to pixels.
class DocumentPageVerticalRulerTick {
  final double points;
  final double y;
  final DocumentPageRulerTickKind kind;

  const DocumentPageVerticalRulerTick({
    required this.points,
    required this.y,
    required this.kind,
  });

  int get inchNumber => points ~/ DocumentPageRulerGeometry.pointsPerInch;

  @override
  bool operator ==(Object other) {
    return other is DocumentPageVerticalRulerTick &&
        other.points == points &&
        other.y == y &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(points, y, kind);
}

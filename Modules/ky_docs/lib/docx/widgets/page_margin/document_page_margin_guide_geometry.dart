import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/page_settings.dart';

/// Maps point-based page margins into visible guide positions on the canvas.
class DocumentPageMarginGuideGeometry {
  static const minWritingWidth = 24.0;
  static const minWritingHeight = 32.0;

  final Size pageSize;
  final Size surfaceSize;
  final EdgeInsets margins;

  const DocumentPageMarginGuideGeometry({
    required this.pageSize,
    required this.surfaceSize,
    required this.margins,
  });

  factory DocumentPageMarginGuideGeometry.fromSettings({
    required PageSettings pageSettings,
    required Size surfaceSize,
  }) {
    return DocumentPageMarginGuideGeometry(
      pageSize: pageSettings.getPageSize(),
      surfaceSize: surfaceSize,
      margins: pageSettings.margins,
    );
  }

  double get scaleX =>
      pageSize.width <= 0 ? 1.0 : surfaceSize.width / pageSize.width;

  double get scaleY =>
      pageSize.height <= 0 ? 1.0 : surfaceSize.height / pageSize.height;

  double get leftGuideX {
    return _leadingPosition(
      rawPosition: margins.left * scaleX,
      extent: surfaceSize.width,
      minWritingExtent: minWritingWidth,
    );
  }

  double get rightGuideX {
    return _trailingPosition(
      rawPosition: surfaceSize.width - (margins.right * scaleX),
      extent: surfaceSize.width,
      leadingPosition: leftGuideX,
      minWritingExtent: minWritingWidth,
    );
  }

  double get topGuideY {
    return _leadingPosition(
      rawPosition: margins.top * scaleY,
      extent: surfaceSize.height,
      minWritingExtent: minWritingHeight,
    );
  }

  double get bottomGuideY {
    return _trailingPosition(
      rawPosition: surfaceSize.height - (margins.bottom * scaleY),
      extent: surfaceSize.height,
      leadingPosition: topGuideY,
      minWritingExtent: minWritingHeight,
    );
  }

  Rect get writingRect {
    return Rect.fromLTRB(leftGuideX, topGuideY, rightGuideX, bottomGuideY);
  }

  static double _leadingPosition({
    required double rawPosition,
    required double extent,
    required double minWritingExtent,
  }) {
    final safeExtent = math.max(0.0, extent);
    final maxLeading = math.max(0.0, safeExtent - minWritingExtent);
    return rawPosition.clamp(0.0, maxLeading).toDouble();
  }

  static double _trailingPosition({
    required double rawPosition,
    required double extent,
    required double leadingPosition,
    required double minWritingExtent,
  }) {
    final safeExtent = math.max(0.0, extent);
    final minTrailing = math.min(
      safeExtent,
      leadingPosition + math.min(minWritingExtent, safeExtent),
    );
    return rawPosition.clamp(minTrailing, safeExtent).toDouble();
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/presentation.dart';

class PptxSlideMetrics {
  static const int defaultCx = 12192000;

  final Size slideSize;
  final int slideCx;
  final int slideCy;

  const PptxSlideMetrics({
    required this.slideSize,
    required this.slideCx,
    required this.slideCy,
  });

  factory PptxSlideMetrics.fromPresentation(Presentation presentation) {
    return PptxSlideMetrics.fromSize(presentation.slideSize);
  }

  factory PptxSlideMetrics.fromSize(Size slideSize) {
    final ratio = slideSize.height / slideSize.width;
    return PptxSlideMetrics(
      slideSize: slideSize,
      slideCx: defaultCx,
      slideCy: math.max(1, (defaultCx * ratio).round()),
    );
  }

  int xEmu(double value) => (value / slideSize.width * slideCx).round();

  int yEmu(double value) => (value / slideSize.height * slideCy).round();

  double modelX(int value) => value / slideCx * slideSize.width;

  double modelY(int value) => value / slideCy * slideSize.height;
}

String pptxColorHex(Color color) {
  final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
  return value.substring(2).toUpperCase();
}

Color? pptxColorFromHex(String? value) {
  if (value == null || value.length != 6) return null;

  final rgb = int.tryParse(value, radix: 16);
  return rgb == null ? null : Color(0xFF000000 | rgb);
}

String pptxXmlText(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String pptxXmlAttr(String value) {
  return pptxXmlText(value).replaceAll('"', '&quot;').replaceAll("'", '&apos;');
}

String pptxResolvePartTarget(String partPath, String target) {
  if (target.startsWith('/')) {
    return target.substring(1);
  }

  final parts = partPath.split('/');
  if (parts.isNotEmpty) {
    parts.removeLast();
  }

  for (final segment in target.split('/')) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(segment);
    }
  }

  return parts.join('/');
}

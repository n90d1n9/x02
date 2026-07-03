import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../models/presentation_component.dart';
import 'pptx_open_xml_utils.dart';

class PptxComponentGeometry {
  final Offset position;
  final Size size;
  final double rotation;

  const PptxComponentGeometry({
    required this.position,
    required this.size,
    required this.rotation,
  });
}

class PptxGeometryMapper {
  static const int _rotationUnitsPerDegree = 60000;

  const PptxGeometryMapper();

  String transformXml(
    PresentationComponent component,
    PptxSlideMetrics metrics,
  ) {
    final offX = metrics.xEmu(component.position.dx);
    final offY = metrics.yEmu(component.position.dy);
    final extX = metrics.xEmu(component.size.width);
    final extY = metrics.yEmu(component.size.height);
    final rotationAttribute = _rotationAttribute(component.rotation);

    return '''
<a:xfrm$rotationAttribute>
  <a:off x="$offX" y="$offY"/>
  <a:ext cx="$extX" cy="$extY"/>
</a:xfrm>''';
  }

  PptxComponentGeometry fromElement(
    XmlElement element,
    PptxSlideMetrics metrics,
  ) {
    final xfrm = _firstElement(element, 'xfrm');
    final off = xfrm == null ? null : _firstElement(xfrm, 'off');
    final ext = xfrm == null ? null : _firstElement(xfrm, 'ext');
    final x = metrics.modelX(int.tryParse(off?.getAttribute('x') ?? '') ?? 96);
    final y = metrics.modelY(int.tryParse(off?.getAttribute('y') ?? '') ?? 96);
    final width = metrics.modelX(
      int.tryParse(ext?.getAttribute('cx') ?? '') ?? (metrics.slideCx ~/ 2),
    );
    final height = metrics.modelY(
      int.tryParse(ext?.getAttribute('cy') ?? '') ?? (metrics.slideCy ~/ 8),
    );

    return PptxComponentGeometry(
      position: Offset(x, y),
      size: Size(math.max(1, width), math.max(1, height)),
      rotation: _rotationFromAttribute(xfrm?.getAttribute('rot')),
    );
  }

  String _rotationAttribute(double degrees) {
    if (degrees.abs() < 0.001) return '';

    final rotation = (degrees * _rotationUnitsPerDegree).round();
    return ' rot="$rotation"';
  }

  double _rotationFromAttribute(String? value) {
    final rotation = int.tryParse(value ?? '');
    return rotation == null ? 0 : rotation / _rotationUnitsPerDegree;
  }

  XmlElement? _firstElement(XmlNode node, String localName) {
    return node.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == localName)
        .firstOrNull;
  }
}

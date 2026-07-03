import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

class PptxOpacityMapper {
  static const int _opaqueAlpha = 100000;

  const PptxOpacityMapper();

  String alphaXml(double opacity) {
    final alpha = alphaValue(opacity);
    return alpha >= _opaqueAlpha ? '' : '<a:alpha val="$alpha"/>';
  }

  String alphaModFixXml(double opacity) {
    final alpha = alphaValue(opacity);
    return alpha >= _opaqueAlpha ? '' : '<a:alphaModFix amt="$alpha"/>';
  }

  int alphaValue(double opacity) {
    return (_normalized(opacity) * _opaqueAlpha).round();
  }

  double effectiveOpacity(Color? color, double componentOpacity) {
    final colorOpacity = color == null
        ? 1.0
        : ((color.toARGB32() >> 24) & 0xFF) / 255;
    return _normalized(componentOpacity) * colorOpacity;
  }

  double textOpacity(XmlElement shape) {
    final runProperties = _firstElement(shape, 'rPr');
    final solidFill = runProperties == null
        ? null
        : _firstElement(runProperties, 'solidFill');

    return _opacityFromSolidFill(solidFill) ?? 1.0;
  }

  double shapeOpacity(XmlElement shape) {
    final shapeProperties = _firstElement(shape, 'spPr');
    final fillOpacity = _opacityFromSolidFill(
      shapeProperties == null
          ? null
          : _firstElement(shapeProperties, 'solidFill'),
    );
    if (fillOpacity != null) return fillOpacity;

    final line = shapeProperties == null
        ? null
        : _firstElement(shapeProperties, 'ln');
    return _opacityFromSolidFill(
          line == null ? null : _firstElement(line, 'solidFill'),
        ) ??
        1.0;
  }

  double pictureOpacity(XmlElement picture) {
    final blip = _firstElement(picture, 'blip');
    final alphaModFix = blip == null
        ? null
        : _firstElement(blip, 'alphaModFix');
    return _opacityFromValue(alphaModFix?.getAttribute('amt')) ?? 1.0;
  }

  double _normalized(double opacity) {
    return opacity.clamp(0.0, 1.0).toDouble();
  }

  double? _opacityFromSolidFill(XmlElement? solidFill) {
    if (solidFill == null) return null;

    final alpha = _firstElement(solidFill, 'alpha');
    return _opacityFromValue(alpha?.getAttribute('val'));
  }

  double? _opacityFromValue(String? value) {
    final alpha = int.tryParse(value ?? '');
    if (alpha == null) return null;

    return (alpha / _opaqueAlpha).clamp(0.0, 1.0).toDouble();
  }

  XmlElement? _firstElement(XmlNode node, String localName) {
    return node.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == localName)
        .firstOrNull;
  }
}

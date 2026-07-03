import 'package:flutter/material.dart';

import '../../models/component.dart';
import 'pptx_open_xml_utils.dart';
import 'pptx_opacity_mapper.dart';

class PptxShapeSpec {
  final ComponentType type;
  final String preset;
  final String name;

  const PptxShapeSpec({
    required this.type,
    required this.preset,
    required this.name,
  });
}

class PptxShapeMapper {
  static const _shapeSpecs = [
    PptxShapeSpec(type: ComponentType.shape, preset: 'rect', name: 'Rectangle'),
    PptxShapeSpec(
      type: ComponentType.circle,
      preset: 'ellipse',
      name: 'Ellipse',
    ),
    PptxShapeSpec(
      type: ComponentType.triangle,
      preset: 'triangle',
      name: 'Triangle',
    ),
  ];

  final PptxOpacityMapper opacityMapper;

  const PptxShapeMapper({this.opacityMapper = const PptxOpacityMapper()});

  PptxShapeSpec? forComponent(ComponentType type) {
    return _shapeSpecs.where((spec) => spec.type == type).firstOrNull;
  }

  PptxShapeSpec? forPreset(String? preset) {
    if (preset == null || preset.isEmpty) return null;

    return _shapeSpecs.where((spec) => spec.preset == preset).firstOrNull;
  }

  String fillXml(Color? color, {double opacity = 1}) {
    if (color == null) return '<a:noFill/>';

    final alphaXml = opacityMapper.alphaXml(
      opacityMapper.effectiveOpacity(color, opacity),
    );
    return '<a:solidFill><a:srgbClr val="${pptxColorHex(color)}">$alphaXml</a:srgbClr></a:solidFill>';
  }

  String lineXml(BorderSide? border, {double opacity = 1}) {
    if (border == null || border.width <= 0) {
      return '<a:ln><a:noFill/></a:ln>';
    }

    final width = (border.width * 12700).round();
    final alphaXml = opacityMapper.alphaXml(
      opacityMapper.effectiveOpacity(border.color, opacity),
    );
    return '<a:ln w="$width"><a:solidFill><a:srgbClr val="${pptxColorHex(border.color)}">$alphaXml</a:srgbClr></a:solidFill></a:ln>';
  }
}

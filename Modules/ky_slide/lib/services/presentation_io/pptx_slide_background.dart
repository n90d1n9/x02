import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import 'pptx_open_xml_utils.dart';

class PptxSlideBackground {
  const PptxSlideBackground();

  String xmlFor(Color? color) {
    if (color == null) return '';

    return '<p:bg><p:bgPr><a:solidFill><a:srgbClr val="${pptxColorHex(color)}"/></a:solidFill><a:effectLst/></p:bgPr></p:bg>';
  }

  Color? colorFromSlide(XmlDocument slideXml) {
    final background = _firstElement(slideXml, 'bg');
    if (background == null) return null;

    final solidFill = _firstElement(background, 'solidFill');
    final color = solidFill == null
        ? null
        : _firstElement(solidFill, 'srgbClr');
    return pptxColorFromHex(color?.getAttribute('val'));
  }

  XmlElement? _firstElement(XmlNode node, String localName) {
    for (final element in node.descendants.whereType<XmlElement>()) {
      if (element.name.local == localName) return element;
    }

    return null;
  }
}

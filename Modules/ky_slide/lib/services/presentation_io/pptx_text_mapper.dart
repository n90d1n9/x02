import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../models/rich_text_content.dart';
import 'pptx_open_xml_utils.dart';
import 'pptx_opacity_mapper.dart';
import 'pptx_text_paragraph_mapper.dart';

/// Converts editable text content to and from PPTX text body markup.
class PptxTextMapper {
  final PptxOpacityMapper opacityMapper;
  final PptxTextParagraphMapper paragraphMapper;

  const PptxTextMapper({
    this.opacityMapper = const PptxOpacityMapper(),
    this.paragraphMapper = const PptxTextParagraphMapper(),
  });

  String textBodyXml(RichTextContent richText, {double opacity = 1}) {
    final alignment = _alignmentValue(richText.alignment);
    final runPropertiesXml = _runPropertiesXml(richText, opacity: opacity);
    final paragraphsXml = paragraphMapper
        .fromPlainText(richText.text)
        .map(
          (paragraph) => paragraphMapper.paragraphXml(
            paragraph: paragraph,
            alignment: alignment,
            lineHeight: richText.style.height,
            runPropertiesXml: runPropertiesXml,
          ),
        )
        .join('\n');

    return '''
<p:txBody>
  <a:bodyPr wrap="square" rtlCol="0"/>
  <a:lstStyle/>
  $paragraphsXml
</p:txBody>''';
  }

  RichTextContent? contentFromShape(XmlElement shape) {
    final text = paragraphMapper.textFromShape(shape);
    if (text.trim().isEmpty) return null;

    final paragraphProperties = _firstElement(shape, 'pPr');
    final runProperties = _firstElement(shape, 'rPr');
    final color = _textColor(runProperties);
    final fontSize = _fontSizeFromRun(runProperties);
    final fontFamily = _fontFamilyFromRun(runProperties);
    final highlightColor = _textHighlightColor(runProperties);
    final letterSpacing = _letterSpacingFromRun(runProperties);
    final lineHeight = _lineHeightFromParagraph(paragraphProperties);

    return RichTextContent(
      text: text,
      style: TextStyle(
        color: color ?? Colors.black87,
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: lineHeight,
        letterSpacing: letterSpacing,
        backgroundColor: highlightColor,
      ),
      isBold: _isEnabled(runProperties?.getAttribute('b')),
      isItalic: _isEnabled(runProperties?.getAttribute('i')),
      isUnderline: _isUnderlined(runProperties?.getAttribute('u')),
      isStrikethrough: _isStrikethrough(runProperties?.getAttribute('strike')),
      alignment: _alignmentFromValue(paragraphProperties?.getAttribute('algn')),
    );
  }

  double opacityFromShape(XmlElement shape) {
    return opacityMapper.textOpacity(shape);
  }

  String _alignmentValue(TextAlign alignment) {
    switch (alignment) {
      case TextAlign.center:
        return 'ctr';
      case TextAlign.right:
        return 'r';
      case TextAlign.justify:
        return 'just';
      default:
        return 'l';
    }
  }

  TextAlign _alignmentFromValue(String? value) {
    switch (value) {
      case 'ctr':
        return TextAlign.center;
      case 'r':
        return TextAlign.right;
      case 'just':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  int _fontSizeValue(double? fontSize) {
    final size = fontSize ?? 18;
    return (size * 100).round();
  }

  double _fontSizeFromRun(XmlElement? runProperties) {
    final value = int.tryParse(runProperties?.getAttribute('sz') ?? '');
    return value == null || value <= 0 ? 24 : value / 100;
  }

  String _runPropertiesXml(
    RichTextContent richText, {
    required double opacity,
  }) {
    final fontSize = _fontSizeValue(richText.style.fontSize);
    final styleFlags = _styleFlags(richText);
    final spacingFlag = _letterSpacingFlag(richText.style.letterSpacing);
    final color = richText.style.color;
    final highlightColor = richText.style.backgroundColor;
    final fontFamilyXml = _fontFamilyXml(richText.style.fontFamily);
    final colorXml = color == null
        ? ''
        : '<a:solidFill><a:srgbClr val="${pptxColorHex(color)}">${opacityMapper.alphaXml(opacityMapper.effectiveOpacity(color, opacity))}</a:srgbClr></a:solidFill>';
    final highlightXml = highlightColor == null
        ? ''
        : '<a:highlight><a:srgbClr val="${pptxColorHex(highlightColor)}"/></a:highlight>';

    return '<a:rPr lang="en-US" sz="$fontSize"$styleFlags$spacingFlag>$colorXml$highlightXml$fontFamilyXml</a:rPr>';
  }

  String _styleFlags(RichTextContent richText) {
    final flags = <String>[];
    if (richText.isBold) flags.add('b="1"');
    if (richText.isItalic) flags.add('i="1"');
    if (richText.isUnderline) flags.add('u="sng"');
    if (richText.isStrikethrough) flags.add('strike="sngStrike"');
    return flags.isEmpty ? '' : ' ${flags.join(' ')}';
  }

  Color? _textColor(XmlElement? runProperties) {
    if (runProperties == null) return null;

    final solidFill = _firstElement(runProperties, 'solidFill');
    final color = solidFill == null
        ? null
        : _firstElement(solidFill, 'srgbClr');
    return pptxColorFromHex(color?.getAttribute('val'));
  }

  Color? _textHighlightColor(XmlElement? runProperties) {
    if (runProperties == null) return null;

    final highlight = _firstElement(runProperties, 'highlight');
    final color = highlight == null
        ? null
        : _firstElement(highlight, 'srgbClr');
    return pptxColorFromHex(color?.getAttribute('val'));
  }

  String? _fontFamilyFromRun(XmlElement? runProperties) {
    final latin = runProperties == null
        ? null
        : _firstElement(runProperties, 'latin');
    final typeface = latin?.getAttribute('typeface')?.trim();

    return typeface == null || typeface.isEmpty ? null : typeface;
  }

  double? _letterSpacingFromRun(XmlElement? runProperties) {
    final value = int.tryParse(runProperties?.getAttribute('spc') ?? '');

    return value == null ? null : value / 1000;
  }

  double? _lineHeightFromParagraph(XmlElement? paragraphProperties) {
    final spacing = paragraphProperties == null
        ? null
        : _firstElement(paragraphProperties, 'spcPct');
    final value = int.tryParse(spacing?.getAttribute('val') ?? '');

    return value == null || value <= 0 ? null : value / 100000;
  }

  String _fontFamilyXml(String? fontFamily) {
    final family = fontFamily?.trim();
    if (family == null || family.isEmpty) return '';

    return '<a:latin typeface="${pptxXmlAttr(family)}"/>';
  }

  String _letterSpacingFlag(double? letterSpacing) {
    if (letterSpacing == null || letterSpacing.abs() < 0.001) return '';

    final value = (letterSpacing.clamp(-2.0, 8.0) * 1000).round();
    return ' spc="$value"';
  }

  bool _isEnabled(String? value) {
    return value == '1' || value == 'true';
  }

  bool _isUnderlined(String? value) {
    return value != null && value != 'none';
  }

  bool _isStrikethrough(String? value) {
    return value == 'sngStrike' || value == 'dblStrike';
  }

  XmlElement? _firstElement(XmlNode node, String localName) {
    for (final element in node.descendants.whereType<XmlElement>()) {
      if (element.name.local == localName) return element;
    }

    return null;
  }
}

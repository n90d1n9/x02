import 'package:xml/xml.dart';

import 'pptx_open_xml_utils.dart';

enum PptxParagraphListType { none, bullet, numbered }

/// Single paragraph plus list metadata derived from editable text content.
class PptxTextParagraph {
  final String text;
  final PptxParagraphListType listType;
  final int? number;

  const PptxTextParagraph({
    required this.text,
    this.listType = PptxParagraphListType.none,
    this.number,
  });
}

/// Maps text paragraphs between Kaysir text content and OpenXML paragraphs.
class PptxTextParagraphMapper {
  static final RegExp _numberedPattern = RegExp(r'^(\d+)[.)]\s+(.+)$');
  static final RegExp _bulletPattern = RegExp('^[-*\\u2022]\\s+(.+)\$');

  const PptxTextParagraphMapper();

  List<PptxTextParagraph> fromPlainText(String text) {
    return text.split('\n').map((line) {
      final trimmedLine = line.trimLeft();
      final numberedMatch = _numberedPattern.firstMatch(trimmedLine);
      if (numberedMatch != null) {
        return PptxTextParagraph(
          text: numberedMatch.group(2) ?? '',
          listType: PptxParagraphListType.numbered,
          number: int.tryParse(numberedMatch.group(1) ?? ''),
        );
      }

      final bulletMatch = _bulletPattern.firstMatch(trimmedLine);
      if (bulletMatch != null) {
        return PptxTextParagraph(
          text: bulletMatch.group(1) ?? '',
          listType: PptxParagraphListType.bullet,
        );
      }

      return PptxTextParagraph(text: line);
    }).toList();
  }

  String paragraphXml({
    required PptxTextParagraph paragraph,
    required String alignment,
    required double? lineHeight,
    required String runPropertiesXml,
  }) {
    final paragraphProperties = _paragraphPropertiesXml(
      paragraph,
      alignment,
      lineHeight,
    );
    final text = pptxXmlText(paragraph.text);

    return '''
<a:p>
  $paragraphProperties
  <a:r>
    $runPropertiesXml
    <a:t>$text</a:t>
  </a:r>
  <a:endParaRPr lang="en-US"/>
</a:p>''';
  }

  String textFromShape(XmlElement shape) {
    final textBody = _firstElement(shape, 'txBody');
    if (textBody == null) {
      return shape.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 't')
          .map((element) => element.innerText)
          .join('\n');
    }

    var nextNumber = 1;
    return textBody.children
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'p')
        .map((paragraph) {
          final text = paragraph.descendants
              .whereType<XmlElement>()
              .where((element) => element.name.local == 't')
              .map((element) => element.innerText)
              .join();
          final listType = _listType(paragraph);
          if (listType == PptxParagraphListType.bullet) {
            return '- $text';
          }
          if (listType == PptxParagraphListType.numbered) {
            final paragraphNumber = _numberedStart(paragraph) ?? nextNumber;
            nextNumber = paragraphNumber + 1;
            return '$paragraphNumber. $text';
          }

          return text;
        })
        .join('\n');
  }

  String _paragraphPropertiesXml(
    PptxTextParagraph paragraph,
    String alignment,
    double? lineHeight,
  ) {
    final listXml = _listXml(paragraph);
    final lineSpacingXml = _lineSpacingXml(lineHeight);
    final bodyXml = '$lineSpacingXml$listXml';

    return bodyXml.isEmpty
        ? '<a:pPr algn="$alignment"/>'
        : '<a:pPr algn="$alignment">$bodyXml</a:pPr>';
  }

  String _lineSpacingXml(double? lineHeight) {
    if (lineHeight == null) return '';

    final value = (lineHeight.clamp(0.9, 2.2) * 100000).round();
    return '<a:lnSpc><a:spcPct val="$value"/></a:lnSpc>';
  }

  String _listXml(PptxTextParagraph paragraph) {
    switch (paragraph.listType) {
      case PptxParagraphListType.bullet:
        return '<a:buChar char="&#8226;"/>';
      case PptxParagraphListType.numbered:
        final startAt = paragraph.number == null
            ? ''
            : ' startAt="${paragraph.number}"';
        return '<a:buAutoNum type="arabicPeriod"$startAt/>';
      case PptxParagraphListType.none:
        return '';
    }
  }

  PptxParagraphListType _listType(XmlElement paragraph) {
    final paragraphProperties = _firstElement(paragraph, 'pPr');
    if (paragraphProperties == null) return PptxParagraphListType.none;
    if (_firstElement(paragraphProperties, 'buAutoNum') != null) {
      return PptxParagraphListType.numbered;
    }
    if (_firstElement(paragraphProperties, 'buChar') != null) {
      return PptxParagraphListType.bullet;
    }

    return PptxParagraphListType.none;
  }

  int? _numberedStart(XmlElement paragraph) {
    final paragraphProperties = _firstElement(paragraph, 'pPr');
    final autoNumber = paragraphProperties == null
        ? null
        : _firstElement(paragraphProperties, 'buAutoNum');

    return int.tryParse(autoNumber?.getAttribute('startAt') ?? '');
  }

  XmlElement? _firstElement(XmlNode node, String localName) {
    return node.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == localName)
        .firstOrNull;
  }
}

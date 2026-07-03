import 'dart:convert';

import '../models/document_import_status.dart';
import 'document_import_extractor.dart';

class WaraqPdfExtractionMapper {
  const WaraqPdfExtractionMapper();

  DocumentImportContent fromPdfCoreJson(
    String json, {
    required String fallbackTitle,
  }) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const FormatException('Expected pdf-core JSON object');
    }

    final title = _titleFrom(decoded['metadata'], fallbackTitle);
    final pages = decoded['pages'];
    final pageTexts = pages is List
        ? [
            for (final page in pages)
              if (_pageText(page).trim().isNotEmpty) _pageText(page).trim(),
          ]
        : const <String>[];
    final pageCount = pages is List ? pages.length : pageTexts.length;
    final text = pageTexts.join('\n\n');

    return DocumentImportContent.structured(
      text: text,
      docsEngineJson: jsonEncode({
        'title': title,
        'metadata': {'page_count': pageCount},
        'blocks': _blocksForPageTexts(pageTexts),
      }),
      method: DocumentImportMethod.waraqPdfCore,
    );
  }

  String _titleFrom(Object? metadata, String fallbackTitle) {
    if (metadata is Map) {
      final title = metadata['title'];
      if (title is String && title.trim().isNotEmpty) {
        return title.trim();
      }
    }

    return fallbackTitle.trim().isEmpty ? 'Untitled Document' : fallbackTitle;
  }

  String _pageText(Object? page) {
    if (page is! Map) return '';

    final text = page['text'];
    return text is String
        ? text.replaceAll('\r\n', '\n').replaceAll('\r', '\n')
        : '';
  }

  List<Map<String, Object?>> _blocksForPageTexts(List<String> pageTexts) {
    final paragraphs = [
      for (final text in pageTexts)
        ...text
            .split(RegExp(r'\n\s*\n'))
            .map((paragraph) => paragraph.trim())
            .where((paragraph) => paragraph.isNotEmpty),
    ];

    if (paragraphs.isEmpty) {
      return [_paragraphBlock(index: 0, text: '')];
    }

    return [
      for (var index = 0; index < paragraphs.length; index++)
        _paragraphBlock(index: index, text: paragraphs[index]),
    ];
  }

  Map<String, Object?> _paragraphBlock({
    required int index,
    required String text,
  }) {
    return {
      'id': 'block-$index',
      'block_type': 'Paragraph',
      'spans': [
        {'text': text, 'style': _defaultInlineStyle()},
      ],
    };
  }

  Map<String, Object?> _defaultInlineStyle() {
    return {
      'bold': false,
      'italic': false,
      'underline': false,
      'strikethrough': false,
      'font_family': null,
      'font_size': null,
      'color': null,
    };
  }
}

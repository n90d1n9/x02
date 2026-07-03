import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/services/waraq_pdf_extraction_mapper.dart';

void main() {
  group('WaraqPdfExtractionMapper', () {
    const mapper = WaraqPdfExtractionMapper();

    test('maps pdf-core JSON pages to text and docs_engine paragraphs', () {
      final content = mapper.fromPdfCoreJson(
        jsonEncode({
          'metadata': {'title': 'Native Report'},
          'pages': [
            {'page_number': 1, 'text': 'Executive summary\n\nFirst finding'},
            {'page_number': 2, 'text': 'Second page body'},
          ],
        }),
        fallbackTitle: 'Fallback',
      );

      final document =
          jsonDecode(content.docsEngineJson!) as Map<String, dynamic>;
      final blocks = document['blocks'] as List<dynamic>;

      expect(
        content.text,
        'Executive summary\n\nFirst finding\n\nSecond page body',
      );
      expect(content.method, DocumentImportMethod.waraqPdfCore);
      expect(document['title'], 'Native Report');
      expect(document['metadata']['page_count'], 2);
      expect(blocks, hasLength(3));
      expect(blocks[0]['block_type'], 'Paragraph');
      expect(blocks[0]['spans'].single['text'], 'Executive summary');
      expect(blocks[1]['spans'].single['text'], 'First finding');
      expect(blocks[2]['spans'].single['text'], 'Second page body');
      expect(blocks[0]['spans'].single['style']['bold'], isFalse);
    });

    test('uses fallback title and empty paragraph for empty extraction', () {
      final content = mapper.fromPdfCoreJson(
        jsonEncode({
          'metadata': {'title': '   '},
          'pages': [
            {'page_number': 1, 'text': '   '},
          ],
        }),
        fallbackTitle: 'Scanned Contract',
      );

      final document =
          jsonDecode(content.docsEngineJson!) as Map<String, dynamic>;
      final blocks = document['blocks'] as List<dynamic>;

      expect(content.text, isEmpty);
      expect(document['title'], 'Scanned Contract');
      expect(blocks, hasLength(1));
      expect(blocks.single['spans'].single['text'], '');
    });

    test('rejects invalid pdf-core JSON roots', () {
      expect(
        () => mapper.fromPdfCoreJson('[]', fallbackTitle: 'Draft'),
        throwsFormatException,
      );
    });
  });
}

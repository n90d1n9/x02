import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/services/document_import_preview_analyzer.dart';

void main() {
  group('DocumentImportPreviewAnalyzer', () {
    const analyzer = DocumentImportPreviewAnalyzer();

    test('detects docs_engine headings, lists, paragraphs, and pages', () {
      final summary = analyzer.analyzeStructure(
        text:
            'Executive summary for the regional performance report\n\n'
            'Revenue grew across every account segment\n\n'
            '- First action item',
        docsEngineJson: jsonEncode({
          'metadata': {'page_count': 3},
          'blocks': [
            {
              'id': 'block-0',
              'block_type': {'Heading': 1},
              'spans': [
                {
                  'text': 'Executive summary for the regional report',
                  'style': {},
                },
              ],
            },
            {
              'id': 'block-1',
              'block_type': 'Paragraph',
              'spans': [
                {
                  'text': 'Revenue grew across every account segment',
                  'style': {},
                },
              ],
            },
            {
              'id': 'block-2',
              'block_type': {
                'ListItem': {'level': 0},
              },
              'spans': [
                {'text': 'First action', 'style': {}},
              ],
            },
          ],
        }),
        hasStructuredContent: true,
        method: DocumentImportMethod.customExtractor,
      );

      expect(summary.pageCount, 3);
      expect(summary.headingCount, 1);
      expect(summary.paragraphCount, 1);
      expect(summary.listItemCount, 1);
      expect(summary.headings, ['Executive summary for the regional report']);
      expect(summary.qualitySignals, isEmpty);
    });

    test(
      'uses plain text heuristics and quality signals for fallback text',
      () {
        final summary = analyzer.analyzeStructure(
          text: 'AGENDA\n\n- Review progress\n- Confirm next steps',
          hasStructuredContent: false,
          method: DocumentImportMethod.fallbackExtractor,
        );

        expect(summary.pageCount, 1);
        expect(summary.headingCount, 1);
        expect(summary.listItemCount, 2);
        expect(summary.paragraphCount, 2);
        expect(summary.qualitySignals, contains('Fallback extraction used'));
        expect(
          summary.qualitySignals,
          contains('Plain text only; formatting may be limited'),
        );
      },
    );

    test('flags empty imports as likely scanned or image-only', () {
      final summary = analyzer.analyzeStructure(
        text: '',
        hasStructuredContent: false,
        method: DocumentImportMethod.dartExtractor,
      );

      expect(summary.likelyScanned, isTrue);
      expect(summary.qualitySignals, contains('No readable text detected'));
      expect(summary.qualitySignals, contains('May be scanned or image-only'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/services/document_change_service.dart';
import 'package:ky_docs/docx/services/document_pagination_service.dart';

void main() {
  group('DocumentChangeService', () {
    DocumentMetadata metadata() {
      return DocumentMetadata(
        id: 'doc-1',
        title: 'Proposal',
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026, 1, 2),
      );
    }

    test('updates metadata statistics and modified time from text', () {
      final service = DocumentChangeService(
        now: () => DateTime(2026, 2, 3, 4, 5),
      );

      final result = service.applyDocumentChange(
        text: 'Hello world\nSecond line.',
        metadata: metadata(),
        pageSettings: const PageSettings(),
      );

      expect(result.metadata.id, 'doc-1');
      expect(result.metadata.title, 'Proposal');
      expect(result.metadata.wordCount, 4);
      expect(
        result.metadata.characterCount,
        'Hello world\nSecond line.'.length,
      );
      expect(result.metadata.modifiedAt, DateTime(2026, 2, 3, 4, 5));
      expect(result.statistics.paragraphCount, 2);
      expect(result.totalPages, 1);
    });

    test('uses the configured pagination service for page estimates', () {
      const service = DocumentChangeService(
        paginationService: DocumentPaginationService(
          charactersPerLine: 1,
          maxPages: 2,
        ),
      );

      final totalPages = service.estimateTotalPages(
        text: List.filled(200, 'a').join(),
        pageSettings: const PageSettings(),
      );

      expect(totalPages, 2);
    });
  });
}

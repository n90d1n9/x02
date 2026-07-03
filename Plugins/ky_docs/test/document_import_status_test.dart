import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';

void main() {
  group('DocumentImportStatus', () {
    test('builds preview metrics from imported text', () {
      final preview = DocumentImportPreview.fromText(
        kind: DocumentImportKind.pdf,
        title: 'Report',
        sourceFileName: 'Report.pdf',
        text: 'Executive summary\n\nSecond page',
        method: DocumentImportMethod.waraqPdfCore,
        hasStructuredContent: true,
      );

      expect(preview.wordCount, 4);
      expect(preview.characterCount, 30);
      expect(preview.textPreview, 'Executive summary Second page');
      expect(preview.summaryLabel, '4 words, structured, 1 page');
    });

    test('describes completed fallback imports with details', () {
      final status = DocumentImportStatus.completed(
        DocumentImportPreview.fromText(
          kind: DocumentImportKind.pdf,
          title: 'Report',
          sourceFileName: 'Report.pdf',
          text: 'Fallback text',
          method: DocumentImportMethod.fallbackExtractor,
          hasStructuredContent: false,
          warningMessage: 'Native parser unavailable',
        ),
      );

      expect(status.message, 'PDF imported with fallback');
      expect(status.details, contains('Report.pdf'));
      expect(status.details, contains('Dart fallback'));
      expect(status.details, contains('Native parser unavailable'));
    });
  });
}

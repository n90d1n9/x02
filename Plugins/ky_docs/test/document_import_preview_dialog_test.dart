import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/models/document_import_structure.dart';
import 'package:ky_docs/docx/widgets/document_import_preview_dialog.dart';

void main() {
  group('DocumentImportPreviewDialog', () {
    testWidgets('shows import metadata and confirms import', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await DocumentImportPreviewDialog.show(
                    context,
                    preview: DocumentImportPreview.fromText(
                      kind: DocumentImportKind.pdf,
                      title: 'Quarterly Report',
                      sourceFileName: 'Quarterly.pdf',
                      text: 'Executive summary and financial notes',
                      method: DocumentImportMethod.waraqPdfCore,
                      hasStructuredContent: true,
                      structure: const DocumentImportStructureSummary(
                        pageCount: 2,
                        paragraphCount: 3,
                        headingCount: 1,
                        listItemCount: 1,
                        tableCount: 0,
                        headings: ['Financial overview'],
                        qualitySignals: [],
                        likelyScanned: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Review PDF Import'), findsOneWidget);
      expect(find.text('Quarterly Report'), findsOneWidget);
      expect(find.text('Quarterly.pdf'), findsOneWidget);
      expect(find.text('Waraq pdf-core'), findsOneWidget);
      expect(find.text('Structured'), findsOneWidget);
      expect(find.text('2 pages'), findsOneWidget);
      expect(find.text('1 heading'), findsOneWidget);
      expect(find.text('1 list item'), findsOneWidget);
      expect(find.text('Financial overview'), findsOneWidget);
      expect(
        find.text('Executive summary and financial notes'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false when cancelled', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await DocumentImportPreviewDialog.show(
                    context,
                    preview: DocumentImportPreview.fromText(
                      kind: DocumentImportKind.docx,
                      title: 'Draft',
                      sourceFileName: 'Draft.docx',
                      text: '',
                      method: DocumentImportMethod.dartExtractor,
                      hasStructuredContent: false,
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}

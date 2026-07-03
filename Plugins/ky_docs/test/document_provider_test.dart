import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/services/document_import_service.dart';
import 'package:ky_docs/docx/services/docx_service.dart';
import 'package:ky_docs/docx/services/pdf_service.dart';
import 'package:ky_docs/docx/services/waraq_pdf_import_extractor.dart';
import 'package:ky_docs/docx/states/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('document providers', () {
    test('build document imports with Waraq-preferred PDF extraction', () {
      final container = ProviderContainer(
        overrides: [
          docxServiceProvider.overrideWithValue(DocxService()),
          pdfServiceProvider.overrideWithValue(PdfService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(documentImportServiceProvider);

      expect(service.extractor, isA<WaraqPdfImportExtractor>());
    });

    test('wire the import service into the document notifier flow', () async {
      final importService = _FakeImportService(
        pdfDocument: const ImportedDocument(
          title: 'Provider PDF',
          text: 'Provider PDF body',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentImportServiceProvider.overrideWithValue(importService),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(documentProvider.notifier);

      await notifier.importFromPdf();

      final state = container.read(documentProvider);
      expect(importService.pdfImports, 1);
      expect(state.metadata.title, 'Provider PDF');
      expect(state.hasUnsavedChanges, isTrue);
      expect(state.importStatus.phase, DocumentImportPhase.completed);
      expect(state.importStatus.preview?.kind, DocumentImportKind.pdf);
      expect(
        state.controller.document.toPlainText(),
        contains('Provider PDF body'),
      );
    });
  });
}

class _FakeImportService extends DocumentImportService {
  final ImportedDocument? pdfDocument;
  var pdfImports = 0;

  _FakeImportService({required this.pdfDocument})
    : super(docxService: DocxService(), pdfService: PdfService());

  @override
  Future<ImportedDocument?> importPdf() async {
    pdfImports++;
    return pdfDocument;
  }
}

class _FakeStorage extends DocumentStorageService {
  @override
  Future<void> initialize() async {}
}

class _FakeCloudSyncService extends CloudSyncService {
  @override
  Future<void> syncDocument(
    String docId,
    String content,
    DocumentMetadata metadata,
  ) async {}
}

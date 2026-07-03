import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/services/document_import_extractor.dart';
import 'package:ky_docs/docx/services/document_import_service.dart';
import 'package:ky_docs/docx/services/docx_service.dart';
import 'package:ky_docs/docx/services/pdf_service.dart';
import 'package:ky_docs/docx/services/waraq_document_bridge.dart';

void main() {
  group('DocumentImportService', () {
    DocumentImportService service({
      PickedDocumentFile? pickedFile,
      _FakeDocxService? docxService,
      _FakePdfService? pdfService,
      DocumentImportExtractor? extractor,
    }) {
      return DocumentImportService(
        docxService: docxService ?? _FakeDocxService(),
        pdfService: pdfService ?? _FakePdfService(),
        extractor: extractor,
        filePicker: (_) async => pickedFile,
      );
    }

    test('derives readable document titles from picked file names', () {
      final importService = service();

      expect(
        importService.titleFromFileName('Quarterly.report.v2.docx'),
        'Quarterly.report.v2',
      );
      expect(importService.titleFromFileName('  Notes.pdf'), 'Notes');
      expect(importService.titleFromFileName('.docx'), 'Untitled Document');
    });

    test('imports DOCX text from the picked file bytes', () async {
      final docxService = _FakeDocxService(text: 'DOCX body');
      final importService = service(
        docxService: docxService,
        pickedFile: PickedDocumentFile(
          name: 'Meeting.docx',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );

      final imported = await importService.importDocx();

      expect(imported?.title, 'Meeting');
      expect(imported?.text, 'DOCX body');
      expect(imported?.sourceFileName, 'Meeting.docx');
      expect(imported?.kind, DocumentImportKind.docx);
      expect(imported?.method, DocumentImportMethod.dartExtractor);
      expect(docxService.lastBytes, [1, 2, 3]);
    });

    test('imports PDF text from the picked file bytes', () async {
      final pdfService = _FakePdfService(text: 'PDF body');
      final importService = service(
        pdfService: pdfService,
        pickedFile: PickedDocumentFile(
          name: 'Report.pdf',
          bytes: Uint8List.fromList([4, 5, 6]),
        ),
      );

      final imported = await importService.importPdf();

      expect(imported?.title, 'Report');
      expect(imported?.text, 'PDF body');
      expect(imported?.kind, DocumentImportKind.pdf);
      expect(
        imported?.preview(fallbackKind: DocumentImportKind.pdf).wordCount,
        2,
      );
      expect(
        imported
            ?.preview(fallbackKind: DocumentImportKind.pdf)
            .structure
            .qualitySignals,
        contains('Plain text only; formatting may be limited'),
      );
      expect(pdfService.lastBytes, [4, 5, 6]);
    });

    test('returns null when the picker is cancelled', () async {
      final imported = await service().importDocx();

      expect(imported, isNull);
    });

    test('forwards extraction failures to the caller', () async {
      final importService = service(
        docxService: _FakeDocxService(error: Exception('bad file')),
        pickedFile: PickedDocumentFile(
          name: 'Broken.docx',
          bytes: Uint8List.fromList([1]),
        ),
      );

      expect(importService.importDocx(), throwsException);
    });

    test('passes Waraq import requests to custom extractors', () async {
      final extractor = _RecordingImportExtractor(text: 'Extracted by Waraq');
      final importService = service(
        extractor: extractor,
        pickedFile: PickedDocumentFile(
          name: 'Report.pdf',
          bytes: Uint8List.fromList([7, 8, 9]),
        ),
      );

      final imported = await importService.importPdf();
      final request = extractor.lastRequest!;

      expect(imported?.text, 'Extracted by Waraq');
      expect(request.format, WaraqDocumentFormat.pdf);
      expect(request.fileName, 'Report.pdf');
      expect(request.bytes, [7, 8, 9]);
      expect(request.libraryPaths.docxCore, contains('/Waraq/docx-core'));
      expect(request.libraryPaths.pdfCore, contains('/Waraq/pdf-core'));
    });

    test(
      'carries structured docs_engine content from Waraq extractors',
      () async {
        final docsEngineJson = jsonEncode({
          'title': 'Report',
          'blocks': [
            {
              'id': 'block-0',
              'block_type': {'Heading': 1},
              'spans': [
                {'text': 'Structured report', 'style': {}},
              ],
            },
          ],
        });
        final extractor = _RecordingStructuredImportExtractor(
          content: DocumentImportContent.structured(
            text: 'Structured report',
            docsEngineJson: docsEngineJson,
          ),
        );
        final importService = service(
          extractor: extractor,
          pickedFile: PickedDocumentFile(
            name: 'Report.docx',
            bytes: Uint8List.fromList([1, 1, 2]),
          ),
        );

        final imported = await importService.importDocx();

        expect(imported?.text, 'Structured report');
        expect(imported?.docsEngineJson, docsEngineJson);
        expect(imported?.method, DocumentImportMethod.customExtractor);
        expect(
          imported
              ?.preview(fallbackKind: DocumentImportKind.docx)
              .hasStructuredContent,
          isTrue,
        );
        expect(
          imported?.preview(fallbackKind: DocumentImportKind.docx).structure,
          isNotNull,
        );
        expect(
          imported
              ?.preview(fallbackKind: DocumentImportKind.docx)
              .structure
              .headingCount,
          1,
        );
        expect(extractor.lastRequest?.format, WaraqDocumentFormat.docx);
      },
    );
  });
}

class _FakeDocxService extends DocxService {
  final String text;
  final Object? error;
  List<int>? lastBytes;

  _FakeDocxService({this.text = 'DOCX text', this.error});

  @override
  Future<String> extractTextFromDocx(Uint8List bytes) async {
    lastBytes = bytes;
    final error = this.error;
    if (error != null) throw error;
    return text;
  }
}

class _FakePdfService extends PdfService {
  final String text;
  List<int>? lastBytes;

  _FakePdfService({this.text = 'PDF text'});

  @override
  Future<String> extractTextFromPdf(Uint8List bytes) async {
    lastBytes = bytes;
    return text;
  }
}

class _RecordingImportExtractor implements DocumentImportExtractor {
  final String text;
  WaraqImportRequest? lastRequest;

  _RecordingImportExtractor({required this.text});

  @override
  Future<String> extractText(WaraqImportRequest request) async {
    lastRequest = request;
    return text;
  }
}

class _RecordingStructuredImportExtractor
    implements DocumentStructuredImportExtractor {
  final DocumentImportContent content;
  WaraqImportRequest? lastRequest;

  _RecordingStructuredImportExtractor({required this.content});

  @override
  Future<DocumentImportContent> extractContent(
    WaraqImportRequest request,
  ) async {
    lastRequest = request;
    return content;
  }

  @override
  Future<String> extractText(WaraqImportRequest request) async {
    lastRequest = request;
    return content.text;
  }
}

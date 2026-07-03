import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as d;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/export_options.dart';
import 'package:ky_docs/docx/services/document_export_renderer.dart';
import 'package:ky_docs/docx/services/document_export_service.dart';
import 'package:ky_docs/docx/services/docx_service.dart';
import 'package:ky_docs/docx/services/pdf_service.dart';
import 'package:ky_docs/docx/services/waraq_document_bridge.dart';

void main() {
  group('DocumentExportService', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('ky_docs_export_');
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    DocumentMetadata metadata({String title = 'Quarterly / Report:*?'}) {
      return DocumentMetadata(
        id: 'doc-1',
        title: title,
        createdAt: DateTime(2026),
        modifiedAt: DateTime(2026, 1, 2),
      );
    }

    DocumentExportService service({
      _FakeDocxService? docxService,
      _FakePdfService? pdfService,
    }) {
      return DocumentExportService(
        docxService: docxService ?? _FakeDocxService(),
        pdfService: pdfService ?? _FakePdfService(),
        directoryProvider: () async => tempDirectory,
      );
    }

    test('sanitizes export file names and falls back for empty titles', () {
      final exportService = service();

      expect(
        exportService.fileNameFor(metadata(), 'docx'),
        'Quarterly _ Report___.docx',
      );
      expect(
        exportService.fileNameFor(metadata(title: '///'), 'pdf'),
        '___.pdf',
      );
      expect(
        exportService.fileNameFor(metadata(title: '   '), 'txt'),
        'Untitled Document.txt',
      );
    });

    test(
      'exports docx, pdf, and txt files to the provided directory',
      () async {
        final exportService = service();
        final doc = metadata(title: 'Proposal');

        final docxPath = await exportService.exportDocx(
          text: 'Body',
          metadata: doc,
        );
        final pdfPath = await exportService.exportPdf(
          text: 'Body',
          metadata: doc,
        );
        final txtPath = await exportService.exportTxt(
          text: 'Body',
          metadata: doc,
        );

        expect(await File(docxPath).readAsBytes(), [1, 2, 3]);
        expect(await File(pdfPath).readAsBytes(), [4, 5, 6]);
        expect(await File(txtPath).readAsString(), 'Body');
      },
    );

    test('aggregates multi-format export successes and failures', () async {
      final exportService = service(
        docxService: _FakeDocxService(error: Exception('docx failed')),
      );

      final result = await exportService.exportMultiple(
        text: 'Body',
        metadata: metadata(title: 'Proposal'),
      );

      expect(result.exported(DocumentExportFormat.docx), isFalse);
      expect(result.exported(DocumentExportFormat.pdf), isTrue);
      expect(result.exported(DocumentExportFormat.txt), isTrue);
      expect(result.paths, hasLength(2));
      expect(result.errors.single, contains('DOCX: Exception: docx failed'));
      expect(result.errorMessage, contains('Some exports failed'));
    });

    test(
      'passes docs_engine payload and Waraq core paths to renderers',
      () async {
        final renderer = _RecordingRenderer();
        final exportService = service().copyWithRenderer(renderer);

        await exportService.exportDocx(
          text: 'Line 1\nLine 2',
          metadata: metadata(title: 'Proposal'),
        );

        final request = renderer.lastDocxRequest!;
        final document =
            jsonDecode(request.docsEngineJson) as Map<String, dynamic>;
        final blocks = document['blocks'] as List<dynamic>;

        expect(document['title'], 'Proposal');
        expect(blocks.first['spans'].single['text'], 'Line 1');
        expect(request.libraryPaths.docsEngine, contains('/Waraq/docs_engine'));
        expect(request.libraryPaths.docxCore, contains('/Waraq/docx-core'));
        expect(request.libraryPaths.pdfCore, contains('/Waraq/pdf-core'));
      },
    );

    test(
      'uses Quill document structure when rendering Waraq exports',
      () async {
        final renderer = _RecordingRenderer();
        final exportService = service().copyWithRenderer(renderer);
        final document = _documentFromDelta(
          d.Delta()
            ..insert('Launch Plan', {'bold': true})
            ..insert('\n', {'header': 2})
            ..insert('First item')
            ..insert('\n', {'list': 'ordered', 'indent': 1}),
        );

        await exportService.exportDocx(
          text: document.toPlainText(),
          metadata: metadata(title: 'Proposal'),
          document: document,
        );

        final request = renderer.lastDocxRequest!;
        final output =
            jsonDecode(request.docsEngineJson) as Map<String, dynamic>;
        final blocks = output['blocks'] as List<dynamic>;

        expect(blocks.first['block_type'], {'Heading': 2});
        expect(blocks.first['spans'].single['style']['bold'], isTrue);
        expect(blocks.last['block_type'], {'ListItem': 1});
        expect(blocks.last['spans'].single['text'], 'First item');
      },
    );
  });
}

quill.Document _documentFromDelta(d.Delta delta) {
  return quill.Document.fromDelta(delta);
}

extension on DocumentExportService {
  DocumentExportService copyWithRenderer(DocumentExportRenderer renderer) {
    return DocumentExportService(
      docxService: docxService,
      pdfService: pdfService,
      renderer: renderer,
      directoryProvider: directoryProvider,
      waraqBridge: waraqBridge,
    );
  }
}

class _FakeDocxService extends DocxService {
  final Object? error;

  _FakeDocxService({this.error});

  @override
  Future<Uint8List> createDocx(
    String plainText,
    DocumentMetadata metadata,
  ) async {
    final error = this.error;
    if (error != null) throw error;
    return Uint8List.fromList([1, 2, 3]);
  }
}

class _FakePdfService extends PdfService {
  @override
  Future<Uint8List> createAdvancedPdf(
    String plainText,
    DocumentMetadata metadata,
    ExportOptions options,
  ) async {
    return Uint8List.fromList([4, 5, 6]);
  }
}

class _RecordingRenderer implements DocumentExportRenderer {
  WaraqExportRequest? lastDocxRequest;

  @override
  Future<Uint8List> renderDocx(WaraqExportRequest request) async {
    lastDocxRequest = request;
    return Uint8List.fromList([7, 8, 9]);
  }

  @override
  Future<Uint8List> renderPdf(
    WaraqExportRequest request,
    ExportOptions options,
  ) async {
    return Uint8List.fromList([9, 8, 7]);
  }
}

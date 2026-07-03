import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_import_service.dart';
import 'package:ky_docs/docx/services/docx_service.dart';
import 'package:ky_docs/docx/services/pdf_service.dart';
import 'package:ky_docs/docx/services/waraq_document_import_service_factory.dart';
import 'package:ky_docs/docx/services/waraq_pdf_import_extractor.dart';

void main() {
  group('WaraqDocumentImportServiceFactory', () {
    test('prefers Waraq PDF import while preserving DOCX fallback', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'ky_docs_waraq_import_service_test_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runner = _RecordingPdfRunner(
        stdout: jsonEncode({
          'metadata': {'title': 'Native Report'},
          'pages': [
            {'page_number': 1, 'text': 'Native PDF body'},
          ],
        }),
      );
      final pdfService = _FakePdfService(text: 'Dart PDF body');
      final importService =
          WaraqDocumentImportServiceFactory(
            pdfImportConfiguration: WaraqPdfImportConfiguration.resilient(
              runner: runner,
              command: const WaraqPdfCliCommand(
                executable: 'waraq-pdf',
                argumentsBeforePath: ['extract'],
                outputFormat: 'json',
              ),
              workspaceProvider: () async => WaraqPdfImportWorkspace(
                directory: tempDirectory,
                deleteWhenDone: false,
              ),
            ),
          ).createPdfPreferred(
            docxService: _FakeDocxService(),
            pdfService: pdfService,
            filePicker: (_) async => PickedDocumentFile(
              name: 'Native.pdf',
              bytes: Uint8List.fromList([4, 5, 6]),
            ),
          );

      final imported = await importService.importPdf();

      expect(imported?.text, 'Native PDF body');
      expect(imported?.docsEngineJson, isNotNull);
      expect(runner.callCount, 1);
      expect(runner.executable, 'waraq-pdf');
      expect(runner.arguments.last, 'json');
      expect(runner.bytesRead, [4, 5, 6]);
      expect(pdfService.lastBytes, isNull);
    });

    test('falls back through the Dart extractor for DOCX files', () async {
      final runner = _RecordingPdfRunner(stdout: '{}');
      final docxService = _FakeDocxService(text: 'DOCX fallback body');
      final importService =
          WaraqDocumentImportServiceFactory(
            pdfImportConfiguration: WaraqPdfImportConfiguration.resilient(
              runner: runner,
            ),
          ).createPdfPreferred(
            docxService: docxService,
            pdfService: _FakePdfService(),
            filePicker: (_) async => PickedDocumentFile(
              name: 'Fallback.docx',
              bytes: Uint8List.fromList([8, 9]),
            ),
          );

      final imported = await importService.importDocx();

      expect(imported?.text, 'DOCX fallback body');
      expect(imported?.docsEngineJson, isNull);
      expect(docxService.lastBytes, [8, 9]);
      expect(runner.callCount, 0);
    });

    test('falls back through Dart PDF import when native PDF fails', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'ky_docs_waraq_import_service_fallback_test_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runner = _RecordingPdfRunner(
        exitCode: 2,
        stdout: '',
        stderr: 'native import unavailable',
      );
      final pdfService = _FakePdfService(text: 'Dart PDF fallback body');
      final importService =
          WaraqDocumentImportServiceFactory(
            pdfImportConfiguration: WaraqPdfImportConfiguration.resilient(
              runner: runner,
              workspaceProvider: () async => WaraqPdfImportWorkspace(
                directory: tempDirectory,
                deleteWhenDone: false,
              ),
            ),
          ).createPdfPreferred(
            docxService: _FakeDocxService(),
            pdfService: pdfService,
            filePicker: (_) async => PickedDocumentFile(
              name: 'Fallback.pdf',
              bytes: Uint8List.fromList([6, 7]),
            ),
          );

      final imported = await importService.importPdf();

      expect(imported?.text, 'Dart PDF fallback body');
      expect(imported?.docsEngineJson, isNull);
      expect(runner.callCount, 1);
      expect(runner.bytesRead, [6, 7]);
      expect(pdfService.lastBytes, [6, 7]);
    });
  });
}

class _FakeDocxService extends DocxService {
  final String text;
  List<int>? lastBytes;

  _FakeDocxService({this.text = 'DOCX text'});

  @override
  Future<String> extractTextFromDocx(Uint8List bytes) async {
    lastBytes = bytes;
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

class _RecordingPdfRunner implements WaraqProcessRunner {
  final int exitCode;
  final String stdout;
  final String stderr;
  var callCount = 0;
  var executable = '';
  var arguments = <String>[];
  List<int>? bytesRead;

  _RecordingPdfRunner({
    this.exitCode = 0,
    required this.stdout,
    this.stderr = '',
  });

  @override
  Future<WaraqProcessResult> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
  }) async {
    callCount++;
    this.executable = executable;
    this.arguments = arguments;
    bytesRead = await File(arguments[arguments.length - 2]).readAsBytes();

    return WaraqProcessResult(
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
    );
  }
}

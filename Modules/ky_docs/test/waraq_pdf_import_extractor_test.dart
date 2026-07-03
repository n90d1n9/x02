import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/services/document_import_extractor.dart';
import 'package:ky_docs/docx/services/waraq_document_bridge.dart';
import 'package:ky_docs/docx/services/waraq_pdf_import_extractor.dart';

void main() {
  group('WaraqPdfImportExtractor', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'ky_docs_waraq_pdf_import_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    WaraqPdfImportExtractor extractor({
      required _RecordingProcessRunner runner,
      DocumentImportExtractor? fallbackExtractor,
      WaraqPdfFailurePolicy failurePolicy = WaraqPdfFailurePolicy.fail,
    }) {
      return WaraqPdfImportExtractor(
        runner: runner,
        command: const WaraqPdfCliCommand(
          executable: 'waraq-pdf',
          argumentsBeforePath: ['extract', '--format'],
          outputFormat: 'json',
        ),
        workspaceProvider: () async => WaraqPdfImportWorkspace(
          directory: tempDirectory,
          deleteWhenDone: false,
        ),
        fallbackExtractor: fallbackExtractor,
        failurePolicy: failurePolicy,
      );
    }

    test(
      'runs pdf-core command and maps JSON output to structured content',
      () async {
        final runner = _RecordingProcessRunner(
          stdout: jsonEncode({
            'metadata': {'title': 'Native PDF'},
            'pages': [
              {'page_number': 1, 'text': 'PDF body'},
            ],
          }),
        );

        final content = await extractor(runner: runner).extractContent(
          _request(fileName: '../Quarterly Report.pdf', bytes: [1, 2, 3]),
        );

        expect(content.text, 'PDF body');
        expect(content.docsEngineJson, isNotNull);
        expect(content.method, DocumentImportMethod.waraqPdfCore);
        expect(runner.executable, 'waraq-pdf');
        expect(runner.workingDirectory, '/pdf-core');
        expect(runner.arguments.first, 'extract');
        expect(runner.arguments[1], '--format');
        expect(runner.arguments.last, 'json');
        expect(runner.bytesRead, [1, 2, 3]);
        expect(runner.inputPath, isNot(contains('/../')));
        expect(await File(runner.inputPath!).exists(), isFalse);
      },
    );

    test(
      'throws a descriptive exception when pdf-core exits non-zero',
      () async {
        final runner = _RecordingProcessRunner(
          exitCode: 7,
          stderr: 'unable to parse pdf',
        );

        await expectLater(
          extractor(runner: runner).extractContent(_request(bytes: [9])),
          throwsA(
            isA<WaraqPdfImportException>()
                .having((error) => error.exitCode, 'exitCode', 7)
                .having(
                  (error) => error.stderr,
                  'stderr',
                  'unable to parse pdf',
                ),
          ),
        );

        expect(await File(runner.inputPath!).exists(), isFalse);
      },
    );

    test('falls back when configured and pdf-core exits non-zero', () async {
      final runner = _RecordingProcessRunner(
        exitCode: 7,
        stderr: 'unable to parse pdf',
      );
      final content = await extractor(
        runner: runner,
        fallbackExtractor: _FallbackImportExtractor(text: 'Dart fallback'),
        failurePolicy: WaraqPdfFailurePolicy.fallbackToExtractor,
      ).extractContent(_request(bytes: [9]));

      expect(content.text, 'Dart fallback');
      expect(content.docsEngineJson, isNull);
      expect(content.method, DocumentImportMethod.fallbackExtractor);
      expect(content.warningMessage, contains('unable to parse pdf'));
      expect(await File(runner.inputPath!).exists(), isFalse);
    });

    test(
      'falls back when configured and pdf-core returns invalid JSON',
      () async {
        final runner = _RecordingProcessRunner(stdout: 'not json');
        final content = await extractor(
          runner: runner,
          fallbackExtractor: _FallbackImportExtractor(text: 'Parsed by Dart'),
          failurePolicy: WaraqPdfFailurePolicy.fallbackToExtractor,
        ).extractContent(_request(bytes: [5, 6]));

        expect(content.text, 'Parsed by Dart');
        expect(content.docsEngineJson, isNull);
        expect(content.method, DocumentImportMethod.fallbackExtractor);
        expect(content.warningMessage, contains('FormatException'));
        expect(await File(runner.inputPath!).exists(), isFalse);
      },
    );

    test('delegates non-PDF imports to the fallback extractor', () async {
      final runner = _RecordingProcessRunner(stdout: '{}');
      final content =
          await extractor(
            runner: runner,
            fallbackExtractor: _FallbackImportExtractor(text: 'DOCX fallback'),
          ).extractContent(
            _request(
              format: WaraqDocumentFormat.docx,
              fileName: 'Draft.docx',
              bytes: [4, 5, 6],
            ),
          );

      expect(content.text, 'DOCX fallback');
      expect(content.docsEngineJson, isNull);
      expect(content.method, DocumentImportMethod.dartExtractor);
      expect(runner.callCount, 0);
    });
  });

  group('WaraqPdfImportConfiguration', () {
    test('builds strict extractors by default', () async {
      final runner = _RecordingProcessRunner(exitCode: 2, stderr: 'bad pdf');
      final extractor =
          WaraqPdfImportConfiguration(
            runner: runner,
            command: const WaraqPdfCliCommand(
              executable: 'waraq-pdf',
              argumentsBeforePath: ['extract'],
              outputFormat: 'json',
            ),
            workspaceProvider: _workspaceProvider,
          ).createExtractor(
            fallbackExtractor: _FallbackImportExtractor(text: 'Fallback text'),
          );

      await expectLater(
        extractor.extractContent(_request(bytes: [1, 2])),
        throwsA(isA<WaraqPdfImportException>()),
      );
    });

    test(
      'builds resilient extractors that fall back on native failures',
      () async {
        final runner = _RecordingProcessRunner(exitCode: 2, stderr: 'bad pdf');
        final extractor =
            WaraqPdfImportConfiguration.resilient(
              runner: runner,
              command: const WaraqPdfCliCommand(
                executable: 'waraq-pdf',
                argumentsBeforePath: ['extract'],
                outputFormat: 'json',
              ),
              workspaceProvider: _workspaceProvider,
            ).createExtractor(
              fallbackExtractor: _FallbackImportExtractor(
                text: 'Fallback text',
              ),
            );

        final content = await extractor.extractContent(_request(bytes: [1, 2]));

        expect(content.text, 'Fallback text');
        expect(content.docsEngineJson, isNull);
        expect(content.method, DocumentImportMethod.fallbackExtractor);
        expect(runner.callCount, 1);
      },
    );
  });
}

Future<WaraqPdfImportWorkspace> _workspaceProvider() async {
  return WaraqPdfImportWorkspace(
    directory: await Directory.systemTemp.createTemp(
      'ky_docs_waraq_pdf_config_test_',
    ),
  );
}

WaraqImportRequest _request({
  WaraqDocumentFormat format = WaraqDocumentFormat.pdf,
  String fileName = 'Report.pdf',
  List<int> bytes = const [1],
}) {
  return WaraqImportRequest(
    format: format,
    fileName: fileName,
    bytes: Uint8List.fromList(bytes),
    libraryPaths: const WaraqLibraryPaths(
      docsEngine: '/docs-engine',
      docxCore: '/docx-core',
      pdfCore: '/pdf-core',
    ),
  );
}

class _RecordingProcessRunner implements WaraqProcessRunner {
  final int exitCode;
  final String stdout;
  final String stderr;
  var callCount = 0;
  var executable = '';
  var arguments = <String>[];
  var workingDirectory = '';
  String? inputPath;
  List<int>? bytesRead;

  _RecordingProcessRunner({
    this.exitCode = 0,
    this.stdout = '',
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
    this.workingDirectory = workingDirectory;
    inputPath = arguments[arguments.length - 2];
    bytesRead = await File(inputPath!).readAsBytes();

    return WaraqProcessResult(
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
    );
  }
}

class _FallbackImportExtractor implements DocumentImportExtractor {
  final String text;

  const _FallbackImportExtractor({required this.text});

  @override
  Future<String> extractText(WaraqImportRequest request) async {
    return text;
  }
}

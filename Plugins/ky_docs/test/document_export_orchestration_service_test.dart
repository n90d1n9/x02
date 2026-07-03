import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as d;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/models/export_options.dart';
import 'package:ky_docs/docx/services/document_export_orchestration_service.dart';
import 'package:ky_docs/docx/services/document_export_renderer.dart';
import 'package:ky_docs/docx/services/document_export_service.dart';
import 'package:ky_docs/docx/services/docx_service.dart';
import 'package:ky_docs/docx/services/pdf_service.dart';
import 'package:ky_docs/docx/services/waraq_document_bridge.dart';

void main() {
  group('DocumentExportOrchestrationService', () {
    late Directory tempDirectory;
    late _RecordingRenderer renderer;
    late DocumentExportOrchestrationService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'ky_docs_export_orchestration_',
      );
      renderer = _RecordingRenderer();
      service = DocumentExportOrchestrationService(
        exportService: DocumentExportService(
          docxService: DocxService(),
          pdfService: PdfService(),
          renderer: renderer,
          directoryProvider: () async => tempDirectory,
        ),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('exports docx and clears dirty state', () async {
      var currentState = _state(
        controller: _controllerWithText('Draft body'),
        hasUnsavedChanges: true,
      );
      final emitted = <DocumentState>[];

      final path = await service.exportDocx(
        readState: () => currentState,
        emitState: (state) {
          currentState = state;
          emitted.add(state);
        },
      );

      expect(emitted.first.isLoading, isTrue);
      expect(await File(path).readAsBytes(), [1, 2, 3]);
      expect(currentState.hasUnsavedChanges, isFalse);
      expect(renderer.lastDocxRequest?.plainText, contains('Draft body'));
    });

    test('passes editor document structure to Waraq renderers', () async {
      var currentState = _state(
        controller: _controllerFromDelta(
          d.Delta()
            ..insert('Structured title', {'bold': true})
            ..insert('\n', {'header': 1}),
        ),
      );

      await service.exportDocx(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      final output =
          jsonDecode(renderer.lastDocxRequest!.docsEngineJson)
              as Map<String, dynamic>;
      final blocks = output['blocks'] as List<dynamic>;

      expect(blocks.single['block_type'], {'Heading': 1});
      expect(blocks.single['spans'].single['style']['bold'], isTrue);
    });

    test('exports pdf without clearing document dirty state', () async {
      var currentState = _state(
        controller: _controllerWithText('PDF body'),
        hasUnsavedChanges: true,
      );

      final path = await service.exportPdf(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        options: const ExportOptions(fontSize: 14),
      );

      expect(await File(path).readAsBytes(), [4, 5, 6]);
      expect(currentState.hasUnsavedChanges, isTrue);
      expect(renderer.lastPdfOptions?.fontSize, 14);
    });

    test('exports multiple formats and exposes partial failures', () async {
      renderer.docxError = Exception('docx failed');
      var currentState = _state(
        controller: _controllerWithText('Multi body'),
        hasUnsavedChanges: true,
      );

      final paths = await service.exportMultiple(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      expect(paths, hasLength(2));
      expect(
        currentState.errorMessage,
        contains('DOCX: Exception: docx failed'),
      );
      expect(currentState.hasUnsavedChanges, isTrue);
    });
  });
}

DocumentState _state({
  required quill.QuillController controller,
  bool hasUnsavedChanges = false,
}) {
  addTearDown(controller.dispose);
  return DocumentState(
    controller: controller,
    metadata: DocumentMetadata(
      id: 'doc-1',
      title: 'Document',
      createdAt: DateTime(2026),
      modifiedAt: DateTime(2026, 1, 2),
    ),
    hasUnsavedChanges: hasUnsavedChanges,
  );
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  return controller;
}

quill.QuillController _controllerFromDelta(d.Delta delta) {
  return quill.QuillController(
    document: quill.Document.fromDelta(delta),
    selection: const TextSelection.collapsed(offset: 0),
  );
}

class _RecordingRenderer implements DocumentExportRenderer {
  WaraqExportRequest? lastDocxRequest;
  WaraqExportRequest? lastPdfRequest;
  ExportOptions? lastPdfOptions;
  Object? docxError;

  @override
  Future<Uint8List> renderDocx(WaraqExportRequest request) async {
    lastDocxRequest = request;
    final error = docxError;
    if (error != null) throw error;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<Uint8List> renderPdf(
    WaraqExportRequest request,
    ExportOptions options,
  ) async {
    lastPdfRequest = request;
    lastPdfOptions = options;
    return Uint8List.fromList([4, 5, 6]);
  }
}

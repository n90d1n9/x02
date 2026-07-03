import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/models/document_template.dart';
import 'package:ky_docs/docx/models/document_version.dart';
import 'package:ky_docs/docx/services/document_controller_factory.dart';
import 'package:ky_docs/docx/services/document_creation_service.dart';
import 'package:ky_docs/docx/services/document_import_extractor.dart';
import 'package:ky_docs/docx/services/document_import_service.dart';
import 'package:ky_docs/docx/services/document_lifecycle_orchestration_service.dart';
import 'package:ky_docs/docx/services/document_persistence_service.dart';
import 'package:ky_docs/docx/services/docx_service.dart';
import 'package:ky_docs/docx/services/pdf_service.dart';
import 'package:ky_docs/docx/services/waraq_document_bridge.dart';

void main() {
  group('DocumentLifecycleOrchestrationService', () {
    late _FakeStorage storage;
    late _FakeCloudSync cloudSync;
    late int idCounter;

    setUp(() {
      storage = _FakeStorage();
      cloudSync = _FakeCloudSync();
      idCounter = 0;
    });

    DocumentLifecycleOrchestrationService service({
      _FakeDocxService? docxService,
      _FakePdfService? pdfService,
      DocumentImportExtractor? extractor,
      Map<DocumentImportFormat, PickedDocumentFile?> pickedFiles = const {},
    }) {
      return DocumentLifecycleOrchestrationService(
        creationService: DocumentCreationService(
          createId: () => 'doc-${++idCounter}',
          now: () => DateTime(2026, 1, 2),
        ),
        persistenceService: DocumentPersistenceService(
          storage: storage,
          cloudSync: cloudSync,
          createId: () => 'version-${++idCounter}',
          now: () => DateTime(2026, 1, 3),
        ),
        importService: DocumentImportService(
          docxService: docxService ?? _FakeDocxService(),
          pdfService: pdfService ?? _FakePdfService(),
          extractor: extractor,
          filePicker: (format) async => pickedFiles[format],
        ),
      );
    }

    quill.QuillController activate(quill.QuillController controller) {
      addTearDown(controller.dispose);
      return controller;
    }

    test(
      'creates blank and template drafts with activated controllers',
      () async {
        var currentState = _state();

        await service().createNew(
          emitState: (state) => currentState = state,
          activateController: activate,
        );

        expect(
          currentState.metadata.title,
          DocumentCreationService.untitledTitle,
        );
        expect(currentState.hasUnsavedChanges, isFalse);
        expect(currentState.controller.document.toPlainText().trim(), isEmpty);

        await service().createFromTemplate(
          emitState: (state) => currentState = state,
          activateController: activate,
          template: const DocumentTemplate(
            id: 'tpl',
            name: 'Brief',
            description: 'Short document',
            category: 'Business',
            icon: Icons.description,
            content: 'Executive summary',
          ),
        );

        expect(currentState.metadata.title, 'Brief');
        expect(currentState.hasUnsavedChanges, isTrue);
        expect(
          currentState.controller.document.toPlainText(),
          contains('Executive summary'),
        );
      },
    );

    test('saves current content, versions, and sync state', () async {
      var currentState = _state(
        controller: _controllerWithText('Proposal body'),
        hasUnsavedChanges: true,
      );
      final emitted = <DocumentState>[];

      await service().save(
        readState: () => currentState,
        emitState: (state) {
          currentState = state;
          emitted.add(state);
        },
      );

      expect(emitted.first.isLoading, isTrue);
      expect(emitted.any((state) => state.isSyncing), isTrue);
      expect(currentState.isLoading, isFalse);
      expect(currentState.isSyncing, isFalse);
      expect(currentState.hasUnsavedChanges, isFalse);
      expect(currentState.versions, hasLength(1));
      expect(storage.documents[currentState.metadata.id], isNotNull);
      expect(cloudSync.syncedIds, [currentState.metadata.id]);
    });

    test('loads stored document content and version history', () async {
      final version = DocumentVersion(
        id: 'v1',
        timestamp: DateTime(2026),
        content: _deltaFor('Loaded body'),
      );
      storage.documents['doc-2'] = version.content;
      storage.metadataById['doc-2'] = _metadata(id: 'doc-2', title: 'Loaded');
      storage.versionsById['doc-2'] = [version];
      var currentState = _state();

      await service().load(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        activateController: activate,
        id: 'doc-2',
      );

      expect(currentState.metadata.title, 'Loaded');
      expect(currentState.hasUnsavedChanges, isFalse);
      expect(currentState.currentVersionIndex, 0);
      expect(
        currentState.controller.document.toPlainText(),
        contains('Loaded body'),
      );
    });

    test('imports docx drafts and clears loading when cancelled', () async {
      var currentState = _state();
      final emitted = <DocumentState>[];

      await service(
        docxService: _FakeDocxService(text: 'Imported body'),
        pickedFiles: {
          DocumentImportFormat.docx: PickedDocumentFile(
            name: 'Imported.docx',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        },
      ).importDocx(
        readState: () => currentState,
        emitState: (state) {
          currentState = state;
          emitted.add(state);
        },
        activateController: activate,
      );

      expect(emitted.map((state) => state.importStatus.phase), [
        DocumentImportPhase.picking,
        DocumentImportPhase.picking,
        DocumentImportPhase.importing,
        DocumentImportPhase.completed,
      ]);
      expect(currentState.metadata.title, 'Imported');
      expect(currentState.hasUnsavedChanges, isTrue);
      expect(
        currentState.importStatus.preview?.sourceFileName,
        'Imported.docx',
      );
      expect(currentState.importStatus.preview?.kind, DocumentImportKind.docx);
      expect(
        currentState.importStatus.preview?.method,
        DocumentImportMethod.dartExtractor,
      );
      expect(
        currentState.controller.document.toPlainText(),
        contains('Imported body'),
      );

      await service().importDocx(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        activateController: activate,
      );

      expect(currentState.isLoading, isFalse);
      expect(currentState.importStatus.phase, DocumentImportPhase.cancelled);
    });

    test(
      'imports structured Waraq docs_engine drafts with formatting',
      () async {
        var currentState = _state();
        final docsEngineJson = jsonEncode({
          'title': 'Imported',
          'blocks': [
            {
              'id': 'block-0',
              'block_type': {'Heading': 1},
              'spans': [
                {
                  'text': 'Imported title',
                  'style': {'bold': true},
                },
              ],
            },
            {
              'id': 'block-1',
              'block_type': {'ListItem': 1},
              'spans': [
                {'text': 'Follow-up item', 'style': {}},
              ],
            },
          ],
        });

        await service(
          extractor: _StructuredImportExtractor(
            content: DocumentImportContent.structured(
              text: 'Imported title\nFollow-up item\n',
              docsEngineJson: docsEngineJson,
            ),
          ),
          pickedFiles: {
            DocumentImportFormat.docx: PickedDocumentFile(
              name: 'Structured.docx',
              bytes: Uint8List.fromList([9, 9]),
            ),
          },
        ).importDocx(
          readState: () => currentState,
          emitState: (state) => currentState = state,
          activateController: activate,
        );

        final operations = currentState.controller.document.toDelta().toJson();
        final headingText = operations[0];
        final headingBreak = operations[1];
        final listBreak = operations[3];

        expect(currentState.metadata.title, 'Structured');
        expect(currentState.hasUnsavedChanges, isTrue);
        expect(headingText['attributes']['bold'], isTrue);
        expect(headingBreak['attributes']['header'], 1);
        expect(listBreak['attributes']['list'], 'bullet');
        expect(listBreak['attributes']['indent'], 1);
        expect(currentState.importStatus.preview?.hasStructuredContent, isTrue);
      },
    );

    test('reviews an import preview before replacing the document', () async {
      var currentState = _state();
      DocumentImportPreview? reviewedPreview;

      await service(
        pdfService: _FakePdfService(text: 'Previewed PDF body'),
        pickedFiles: {
          DocumentImportFormat.pdf: PickedDocumentFile(
            name: 'Preview.pdf',
            bytes: Uint8List.fromList([7, 7]),
          ),
        },
      ).importPdf(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        activateController: activate,
        reviewImport: (preview) async {
          reviewedPreview = preview;
          return true;
        },
      );

      expect(reviewedPreview?.sourceFileName, 'Preview.pdf');
      expect(reviewedPreview?.textPreview, 'Previewed PDF body');
      expect(currentState.metadata.title, 'Preview');
      expect(currentState.importStatus.phase, DocumentImportPhase.completed);
      expect(
        currentState.controller.document.toPlainText(),
        contains('Previewed PDF body'),
      );
    });

    test(
      'keeps the active document when import preview is cancelled',
      () async {
        var currentState = _state(
          controller: _controllerWithText('Original body'),
          metadata: _metadata(title: 'Original'),
        );

        await service(
          pdfService: _FakePdfService(text: 'Rejected PDF body'),
          pickedFiles: {
            DocumentImportFormat.pdf: PickedDocumentFile(
              name: 'Rejected.pdf',
              bytes: Uint8List.fromList([8, 8]),
            ),
          },
        ).importPdf(
          readState: () => currentState,
          emitState: (state) => currentState = state,
          activateController: activate,
          reviewImport: (_) async => false,
        );

        expect(currentState.metadata.title, 'Original');
        expect(currentState.importStatus.phase, DocumentImportPhase.cancelled);
        expect(
          currentState.controller.document.toPlainText(),
          contains('Original body'),
        );
      },
    );

    test('marks import status as failed when extraction fails', () async {
      var currentState = _state();

      await service(
        extractor: _FailingImportExtractor(),
        pickedFiles: {
          DocumentImportFormat.pdf: PickedDocumentFile(
            name: 'Broken.pdf',
            bytes: Uint8List.fromList([0]),
          ),
        },
      ).importPdf(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        activateController: activate,
      );

      expect(currentState.isLoading, isFalse);
      expect(currentState.importStatus.phase, DocumentImportPhase.failed);
      expect(currentState.importStatus.kind, DocumentImportKind.pdf);
      expect(currentState.importStatus.errorMessage, contains('bad import'));
      expect(currentState.errorMessage, contains('Failed to import PDF'));
    });

    test('duplicates the active document into a clean copy', () async {
      var currentState = _state(
        controller: _controllerWithText('Copy this'),
        metadata: _metadata(title: 'Proposal'),
        hasUnsavedChanges: true,
      );

      await service().duplicate(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        activateController: activate,
      );

      expect(currentState.metadata.id, startsWith('version-'));
      expect(currentState.metadata.title, 'Proposal (Copy)');
      expect(currentState.hasUnsavedChanges, isFalse);
      expect(
        currentState.controller.document.toPlainText(),
        contains('Copy this'),
      );
      expect(storage.documents[currentState.metadata.id], isNotNull);
    });

    test('restores valid versions and ignores invalid indexes', () {
      final restoredContent = _deltaFor('Restored body');
      var currentState = _state(
        versions: [
          DocumentVersion(
            id: 'v1',
            timestamp: DateTime(2026),
            content: restoredContent,
          ),
        ],
      );

      service().restoreVersion(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        activateController: activate,
        index: 0,
      );

      expect(currentState.currentVersionIndex, 0);
      expect(currentState.hasUnsavedChanges, isTrue);
      expect(
        currentState.controller.document.toPlainText(),
        contains('Restored body'),
      );

      final unchangedController = currentState.controller;
      service().restoreVersion(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        activateController: activate,
        index: 2,
      );

      expect(currentState.controller, same(unchangedController));
    });
  });
}

DocumentState _state({
  quill.QuillController? controller,
  DocumentMetadata? metadata,
  bool hasUnsavedChanges = false,
  List<DocumentVersion> versions = const [],
}) {
  final activeController = controller ?? quill.QuillController.basic();
  addTearDown(activeController.dispose);

  return DocumentState(
    controller: activeController,
    metadata: metadata ?? _metadata(),
    hasUnsavedChanges: hasUnsavedChanges,
    versions: versions,
    currentVersionIndex: versions.isEmpty ? -1 : versions.length - 1,
  );
}

DocumentMetadata _metadata({String id = 'doc-1', String title = 'Document'}) {
  return DocumentMetadata(
    id: id,
    title: title,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026, 1, 2),
  );
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  return controller;
}

String _deltaFor(String text) {
  const factory = DocumentControllerFactory();
  final controller = _controllerWithText(text);
  try {
    return factory.encodeDelta(controller);
  } finally {
    controller.dispose();
  }
}

class _FakeStorage extends DocumentStorageService {
  final documents = <String, String>{};
  final metadataById = <String, DocumentMetadata>{};
  final versionsById = <String, List<DocumentVersion>>{};
  var initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> saveDocument(
    String id,
    String content,
    DocumentMetadata metadata,
  ) async {
    documents[id] = content;
    metadataById[id] = metadata;
  }

  @override
  Future<String?> loadDocument(String id) async => documents[id];

  @override
  Future<DocumentMetadata?> loadMetadata(String id) async => metadataById[id];

  @override
  Future<void> saveVersions(
    String documentId,
    List<DocumentVersion> versions,
  ) async {
    versionsById[documentId] = versions;
  }

  @override
  Future<List<DocumentVersion>> loadVersions(String documentId) async {
    return versionsById[documentId] ?? [];
  }

  @override
  Future<void> deleteDocument(String id) async {
    documents.remove(id);
    metadataById.remove(id);
    versionsById.remove(id);
  }
}

class _FakeCloudSync extends CloudSyncService {
  final syncedIds = <String>[];

  @override
  Future<void> syncDocument(
    String docId,
    String content,
    DocumentMetadata metadata,
  ) async {
    syncedIds.add(docId);
  }
}

class _FakeDocxService extends DocxService {
  final String text;

  _FakeDocxService({this.text = 'DOCX text'});

  @override
  Future<String> extractTextFromDocx(Uint8List bytes) async => text;
}

class _FakePdfService extends PdfService {
  final String text;

  _FakePdfService({this.text = 'PDF text'});

  @override
  Future<String> extractTextFromPdf(Uint8List bytes) async => text;
}

class _StructuredImportExtractor implements DocumentStructuredImportExtractor {
  final DocumentImportContent content;

  const _StructuredImportExtractor({required this.content});

  @override
  Future<DocumentImportContent> extractContent(
    WaraqImportRequest request,
  ) async {
    return content;
  }

  @override
  Future<String> extractText(WaraqImportRequest request) async {
    return content.text;
  }
}

class _FailingImportExtractor implements DocumentImportExtractor {
  @override
  Future<String> extractText(WaraqImportRequest request) async {
    throw Exception('bad import');
  }
}

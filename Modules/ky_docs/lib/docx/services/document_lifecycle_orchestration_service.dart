import 'package:ky_docs/compat/flutter_quill_compat.dart' as quill;
import 'package:ky_docs/docx/models/document_stats.dart';

import '../models/document_import_status.dart';
import '../models/document_state.dart';
import '../models/document_template.dart';
import 'document_async_operation_service.dart';
import 'document_controller_factory.dart';
import 'document_creation_service.dart';
import 'document_import_service.dart';
import 'document_persistence_service.dart';
import 'document_state_mutation_service.dart';
import 'document_version_restore_service.dart';

typedef LifecycleStateReader = DocumentState Function();
typedef LifecycleStateEmitter = void Function(DocumentState state);
typedef DocumentControllerActivator =
    quill.QuillController Function(quill.QuillController controller);
typedef DocumentImportPreviewReviewer =
    Future<bool> Function(DocumentImportPreview preview);

class DocumentLifecycleOrchestrationService {
  final DocumentCreationService creationService;
  final DocumentPersistenceService persistenceService;
  final DocumentImportService importService;
  final DocumentControllerFactory controllerFactory;
  final DocumentVersionRestoreService versionRestoreService;
  final DocumentAsyncOperationService asyncOperationService;
  final DocumentStateMutationService stateMutationService;

  const DocumentLifecycleOrchestrationService({
    required this.creationService,
    required this.persistenceService,
    required this.importService,
    this.controllerFactory = const DocumentControllerFactory(),
    this.versionRestoreService = const DocumentVersionRestoreService(),
    this.asyncOperationService = const DocumentAsyncOperationService(),
    this.stateMutationService = const DocumentStateMutationService(),
  });

  static DocumentState initialState({
    required DocumentCreationIdProvider createId,
  }) {
    final draft = DocumentCreationService(createId: createId).blank();

    return DocumentState(
      controller: const DocumentControllerFactory().createBlank(),
      metadata: draft.metadata,
      hasUnsavedChanges: draft.hasUnsavedChanges,
      stats: DocumentStats(
        words: 0,
        characters: 0,
        charactersNoSpaces: 0,
        paragraphs: 0,
        readingTime: 0,
      ),
      title: '',
      lastModified: DateTime.now(),
      isSaved: true,
      documentId: '',
      currentUserId: '',
    );
  }

  Future<void> initializeStorage({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
  }) async {
    try {
      await persistenceService.initialize();
    } catch (error) {
      emitState(
        readState().copyWith(
          errorMessage: 'Failed to initialize storage: $error',
        ),
      );
    }
  }

  Future<void> createNew({
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
  }) async {
    _replaceWithDraft(
      emitState: emitState,
      activateController: activateController,
      draft: creationService.blank(),
    );
  }

  Future<void> createFromTemplate({
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
    required DocumentTemplate template,
  }) async {
    _replaceWithDraft(
      emitState: emitState,
      activateController: activateController,
      draft: creationService.fromTemplate(template),
    );
  }

  Future<void> save({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
  }) async {
    await asyncOperationService.run<void>(
      readState: readState,
      emitState: emitState,
      failureMessage: 'Failed to save document',
      clearSyncingOnError: true,
      operation: () async {
        final current = readState();
        final content = controllerFactory.encodeDelta(current.controller);
        final result = await persistenceService.save(
          content: content,
          metadata: current.metadata,
          existingVersions: current.versions,
          onSyncStarted: () {
            emitState(readState().copyWith(isSyncing: true));
          },
        );

        emitState(
          readState().copyWith(
            hasUnsavedChanges: false,
            isLoading: false,
            versions: result.versions,
            currentVersionIndex: result.currentVersionIndex,
            isSyncing: false,
            lastSyncTime: result.lastSyncTime,
          ),
        );
      },
    );
  }

  Future<void> load({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
    required String id,
  }) async {
    await asyncOperationService.run<void>(
      readState: readState,
      emitState: emitState,
      failureMessage: 'Failed to load document',
      operation: () async {
        final document = await persistenceService.load(id);

        final controller = activateController(
          controllerFactory.createFromDeltaJson(document.content),
        );

        emitState(
          DocumentState(
            controller: controller,
            metadata: document.metadata,
            hasUnsavedChanges: false,
            isLoading: false,
            versions: document.versions,
            currentVersionIndex: document.currentVersionIndex,
            title: '',
            lastModified: DateTime.now(),
            isSaved: true,
            documentId: '',
            currentUserId: '',
          ),
        );
      },
    );
  }

  Future<void> importDocx({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
    DocumentImportPreviewReviewer? reviewImport,
  }) {
    return _importDocument(
      readState: readState,
      emitState: emitState,
      activateController: activateController,
      kind: DocumentImportKind.docx,
      label: 'DOCX',
      import: importService.importDocx,
      reviewImport: reviewImport,
    );
  }

  Future<void> importPdf({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
    DocumentImportPreviewReviewer? reviewImport,
  }) {
    return _importDocument(
      readState: readState,
      emitState: emitState,
      activateController: activateController,
      kind: DocumentImportKind.pdf,
      label: 'PDF',
      import: importService.importPdf,
      reviewImport: reviewImport,
    );
  }

  Future<void> delete(String id) {
    return persistenceService.delete(id);
  }

  Future<void> duplicate({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
  }) async {
    await asyncOperationService.run<void>(
      readState: readState,
      emitState: emitState,
      failureMessage: 'Failed to duplicate document',
      operation: () async {
        final current = readState();
        final content = controllerFactory.encodeDelta(current.controller);
        final duplicated = await persistenceService.duplicate(
          content: content,
          metadata: current.metadata,
        );

        final controller = activateController(
          controllerFactory.createFromDeltaJson(duplicated.content),
        );

        emitState(
          DocumentState(
            controller: controller,
            metadata: duplicated.metadata,
            hasUnsavedChanges: false,
            isLoading: false,
            title: '',
            lastModified: DateTime.now(),
            isSaved: true,
            documentId: '',
            currentUserId: '',
          ),
        );
      },
    );
  }

  void restoreVersion({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
    required int index,
  }) {
    final plan = versionRestoreService.restorePlan(
      versions: readState().versions,
      index: index,
    );
    if (plan == null) return;

    final controller = activateController(
      controllerFactory.createFromDeltaJson(plan.content),
    );

    emitState(
      stateMutationService.markChanged(
        readState(),
        (current) => current.copyWith(
          controller: controller,
          currentVersionIndex: plan.index,
        ),
      ),
    );
  }

  Future<void> _importDocument({
    required LifecycleStateReader readState,
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
    required DocumentImportKind kind,
    required String label,
    required Future<ImportedDocument?> Function() import,
    DocumentImportPreviewReviewer? reviewImport,
  }) async {
    emitState(
      readState().copyWith(importStatus: DocumentImportStatus.picking(kind)),
    );

    await asyncOperationService.run<void>(
      readState: readState,
      emitState: emitState,
      failureMessage: 'Failed to import $label',
      failureStateBuilder: (failedState, error) {
        return failedState.copyWith(
          importStatus: DocumentImportStatus.failed(
            kind: kind,
            errorMessage: error.toString(),
          ),
        );
      },
      operation: () async {
        emitState(
          readState().copyWith(
            importStatus: DocumentImportStatus.importing(kind),
          ),
        );
        final imported = await import();

        if (imported != null) {
          final preview = imported.preview(fallbackKind: kind);
          final reviewer = reviewImport;
          if (reviewer != null) {
            emitState(
              readState().copyWith(
                isLoading: false,
                importStatus: DocumentImportStatus.previewing(preview),
              ),
            );

            final accepted = await reviewer(preview);
            if (!accepted) {
              emitState(
                readState().copyWith(
                  isLoading: false,
                  importStatus: DocumentImportStatus.cancelled(kind),
                ),
              );
              return;
            }
          }

          final draft = creationService.imported(
            title: imported.title,
            content: imported.text,
          );
          final docsEngineJson = imported.docsEngineJson;

          _replaceWithDraft(
            emitState: emitState,
            activateController: activateController,
            draft: draft,
            importStatus: DocumentImportStatus.completed(preview),
            controller: docsEngineJson == null
                ? null
                : controllerFactory.createFromWaraqDocsEngineJson(
                    docsEngineJson,
                  ),
          );
        } else {
          emitState(
            readState().copyWith(
              isLoading: false,
              importStatus: DocumentImportStatus.cancelled(kind),
            ),
          );
        }
      },
    );
  }

  void _replaceWithDraft({
    required LifecycleStateEmitter emitState,
    required DocumentControllerActivator activateController,
    required DocumentDraft draft,
    quill.QuillController? controller,
    DocumentImportStatus importStatus = const DocumentImportStatus.idle(),
  }) {
    emitState(
      DocumentState(
        controller: activateController(
          controller ?? _controllerForDraft(draft),
        ),
        metadata: draft.metadata,
        hasUnsavedChanges: draft.hasUnsavedChanges,
        importStatus: importStatus,
        title: '',
        lastModified: DateTime.now(),
        isSaved: true,
        documentId: '',
        currentUserId: '',
      ),
    );
  }

  quill.QuillController _controllerForDraft(DocumentDraft draft) {
    if (draft.content.isEmpty) return controllerFactory.createBlank();
    return controllerFactory.createFromPlainText(draft.content);
  }
}

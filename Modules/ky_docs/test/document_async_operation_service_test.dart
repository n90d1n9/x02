import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:ky_docs/docx/models/document_import_status.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/services/document_async_operation_service.dart';

void main() {
  group('DocumentAsyncOperationService', () {
    const service = DocumentAsyncOperationService();

    late quill.QuillController controller;
    late DocumentState currentState;
    late List<DocumentState> emittedStates;

    setUp(() {
      controller = quill.QuillController.basic();
      currentState = DocumentState(
        controller: controller,
        metadata: DocumentMetadata(
          id: 'doc-1',
          title: 'Proposal',
          createdAt: DateTime(2026),
          modifiedAt: DateTime(2026, 1, 2),
        ),
        errorMessage: 'Previous error',
      );
      emittedStates = [];
    });

    tearDown(() {
      controller.dispose();
    });

    DocumentState readState() => currentState;

    void emitState(DocumentState state) {
      currentState = state;
      emittedStates.add(state);
    }

    test('sets loading and clears previous errors before running', () async {
      final result = await service.run<String>(
        readState: readState,
        emitState: emitState,
        failureMessage: 'Failed',
        operation: () async => 'done',
      );

      expect(result, 'done');
      expect(emittedStates.first.isLoading, isTrue);
      expect(emittedStates.first.errorMessage, isNull);
    });

    test('emits failure state and fallback when operation fails', () async {
      final result = await service.run<List<String>>(
        readState: readState,
        emitState: emitState,
        failureMessage: 'Failed to export',
        fallback: const [],
        operation: () async => throw Exception('boom'),
      );

      expect(result, isEmpty);
      expect(currentState.isLoading, isFalse);
      expect(currentState.errorMessage, 'Failed to export: Exception: boom');
    });

    test('clears syncing on failure when requested', () async {
      currentState = currentState.copyWith(isSyncing: true);

      await service.run<void>(
        readState: readState,
        emitState: emitState,
        failureMessage: 'Failed to save',
        clearSyncingOnError: true,
        operation: () async => throw Exception('offline'),
      );

      expect(currentState.isLoading, isFalse);
      expect(currentState.isSyncing, isFalse);
    });

    test('allows callers to enrich failure state', () async {
      await service.run<void>(
        readState: readState,
        emitState: emitState,
        failureMessage: 'Failed to import',
        failureStateBuilder: (failedState, error) {
          return failedState.copyWith(
            importStatus: DocumentImportStatus.failed(
              kind: DocumentImportKind.pdf,
              errorMessage: error.toString(),
            ),
          );
        },
        operation: () async => throw Exception('broken pdf'),
      );

      expect(
        currentState.errorMessage,
        'Failed to import: Exception: broken pdf',
      );
      expect(currentState.importStatus.phase, DocumentImportPhase.failed);
      expect(currentState.importStatus.errorMessage, 'Exception: broken pdf');
    });

    test('rethrows after emitting failure state when requested', () async {
      await expectLater(
        service.run<void>(
          readState: readState,
          emitState: emitState,
          failureMessage: 'Failed to export',
          rethrowOnError: true,
          operation: () async => throw Exception('nope'),
        ),
        throwsException,
      );

      expect(currentState.isLoading, isFalse);
      expect(currentState.errorMessage, 'Failed to export: Exception: nope');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/aiaction.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/services/document_ai_controller.dart';
import 'package:ky_docs/docx/services/document_ai_orchestration_service.dart';

void main() {
  group('DocumentAiOrchestrationService', () {
    quill.QuillController controllerWithText(String text, {int? selection}) {
      final controller = quill.QuillController.basic();
      controller.document.insert(0, text);
      controller.updateSelection(
        TextSelection.collapsed(offset: selection ?? text.length),
        quill.ChangeSource.local,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('emits processing and result states for AI actions', () async {
      String? processedText;
      AIAction? processedAction;
      final service = DocumentAiOrchestrationService(
        aiController: DocumentAiController(
          processText: (text, action) async {
            processedText = text;
            processedAction = action;
            return 'Better $text';
          },
        ),
      );
      var currentState = _state(
        controller: controllerWithText('rough draft', selection: 5),
        aiResult: 'old result',
        errorMessage: 'old error',
      );
      final emitted = <DocumentState>[];

      await service.applyAction(
        readState: () => currentState,
        emitState: (state) {
          currentState = state;
          emitted.add(state);
        },
        action: AIAction.improve,
      );

      expect(emitted.first.isAIProcessing, isTrue);
      expect(emitted.first.aiResult, isNull);
      expect(emitted.first.errorMessage, isNull);
      expect(processedText, 'rough draft\n');
      expect(processedAction, AIAction.improve);
      expect(currentState.isAIProcessing, isFalse);
      expect(currentState.aiResult, 'Better rough draft\n');
    });

    test('emits a failed state when AI processing throws', () async {
      final service = DocumentAiOrchestrationService(
        aiController: DocumentAiController(
          processText: (text, action) async => throw Exception('offline'),
        ),
      );
      var currentState = _state(controller: controllerWithText('draft'));

      await service.applyAction(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        action: AIAction.improve,
      );

      expect(currentState.isAIProcessing, isFalse);
      expect(currentState.errorMessage, 'Exception: offline');
    });

    test('replaces selected text with the AI result and clears it', () {
      final service = _echoService();
      final controller = controllerWithText('hello world');
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        quill.ChangeSource.local,
      );
      var currentState = _state(controller: controller, aiResult: 'hi');

      service.replaceResult(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      expect(controller.document.toPlainText(), contains('hi world'));
      expect(currentState.aiResult, isNull);
    });

    test('inserts AI result at the current cursor and clears it', () {
      final service = _echoService();
      final controller = controllerWithText('hello', selection: 5);
      var currentState = _state(controller: controller, aiResult: 'there');

      service.insertResult(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      expect(controller.document.toPlainText(), contains('hello\n\nthere\n\n'));
      expect(currentState.aiResult, isNull);
    });

    test('does not mutate the document when there is no AI result', () {
      final service = _echoService();
      final controller = controllerWithText('hello');
      var currentState = _state(controller: controller);
      var emitCount = 0;

      service.replaceResult(
        readState: () => currentState,
        emitState: (state) {
          currentState = state;
          emitCount++;
        },
      );
      service.insertResult(
        readState: () => currentState,
        emitState: (state) {
          currentState = state;
          emitCount++;
        },
      );

      expect(controller.document.toPlainText(), contains('hello'));
      expect(emitCount, 0);
    });

    test('clears existing AI results', () {
      final service = _echoService();
      var currentState = _state(
        controller: controllerWithText('hello'),
        aiResult: 'result',
      );

      service.clearResult(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      expect(currentState.aiResult, isNull);
    });
  });
}

DocumentAiOrchestrationService _echoService() {
  return DocumentAiOrchestrationService(
    aiController: DocumentAiController(
      processText: (text, action) async => text,
    ),
  );
}

DocumentState _state({
  required quill.QuillController controller,
  String? aiResult,
  String? errorMessage,
}) {
  final now = DateTime(2026);
  return DocumentState(
    controller: controller,
    metadata: DocumentMetadata(
      id: 'doc-1',
      title: 'Document',
      createdAt: now,
      modifiedAt: now,
    ),
    aiResult: aiResult,
    errorMessage: errorMessage,
  );
}

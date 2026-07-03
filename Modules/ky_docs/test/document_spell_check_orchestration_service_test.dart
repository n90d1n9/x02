import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/models/spell_check_error.dart';
import 'package:ky_docs/docx/models/spell_check_service.dart';
import 'package:ky_docs/docx/services/document_spell_check_controller.dart';
import 'package:ky_docs/docx/services/document_spell_check_orchestration_service.dart';

void main() {
  group('DocumentSpellCheckOrchestrationService', () {
    late DocumentSpellCheckOrchestrationService service;

    setUp(() {
      service = DocumentSpellCheckOrchestrationService(
        spellCheckController: DocumentSpellCheckController(
          SpellCheckService(),
          interval: const Duration(hours: 1),
        ),
      );
    });

    tearDown(() {
      service.dispose();
    });

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

    test('enables spell check and runs immediately', () {
      var currentState = _state(controller: controllerWithText('write wrte'));

      service.toggle(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      expect(currentState.spellCheckEnabled, isTrue);
      expect(currentState.spellErrors, hasLength(1));
      expect(currentState.spellErrors.single.word, 'wrte');
    });

    test('disables spell check and clears existing errors', () {
      var currentState = _state(
        controller: controllerWithText('write wrte'),
        spellCheckEnabled: true,
        spellErrors: [
          SpellCheckError(word: 'wrte', offset: 6, suggestions: ['write']),
        ],
      );

      service.toggle(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );

      expect(currentState.spellCheckEnabled, isFalse);
      expect(currentState.spellErrors, isEmpty);
    });

    test('adds dictionary words and reruns only when enabled', () {
      var currentState = _state(
        controller: controllerWithText('wrte'),
        spellCheckEnabled: true,
      );
      service.runIfEnabled(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );
      expect(currentState.spellErrors, isNotEmpty);

      service.addToDictionary(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        word: 'wrte',
      );
      expect(currentState.spellErrors, isEmpty);

      currentState = currentState.copyWith(
        spellCheckEnabled: false,
        spellErrors: [
          SpellCheckError(word: 'typo', offset: 0, suggestions: []),
        ],
      );
      service.addToDictionary(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        word: 'another',
      );

      expect(currentState.spellErrors.single.word, 'typo');
    });

    test('ignores words and reruns spell check', () {
      var currentState = _state(
        controller: controllerWithText('wrte'),
        spellCheckEnabled: true,
      );
      service.runIfEnabled(
        readState: () => currentState,
        emitState: (state) => currentState = state,
      );
      expect(currentState.spellErrors, isNotEmpty);

      service.ignoreWord(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        word: 'wrte',
      );

      expect(currentState.spellErrors, isEmpty);
    });

    test('replaces suggestions and reruns spell check when enabled', () {
      final controller = controllerWithText('write wrte');
      var currentState = _state(
        controller: controller,
        spellCheckEnabled: true,
      );

      service.replaceWithSuggestion(
        readState: () => currentState,
        emitState: (state) => currentState = state,
        error: SpellCheckError(word: 'wrte', offset: 6, suggestions: ['write']),
        suggestion: 'write',
      );

      expect(controller.document.toPlainText(), contains('write write'));
      expect(currentState.spellErrors, isEmpty);
    });
  });
}

DocumentState _state({
  required quill.QuillController controller,
  bool spellCheckEnabled = false,
  List<SpellCheckError> spellErrors = const [],
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
    spellCheckEnabled: spellCheckEnabled,
    spellErrors: spellErrors,
  );
}

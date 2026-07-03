import 'package:flutter/services.dart' show TextSelection;

import '../models/document_state.dart';
import '../models/spell_check_error.dart';
import '../models/spell_check_service.dart';
import 'document_spell_check_controller.dart';

typedef SpellCheckStateReader = DocumentState Function();
typedef SpellCheckStateEmitter = void Function(DocumentState state);

class DocumentSpellCheckOrchestrationService {
  final DocumentSpellCheckController spellCheckController;

  DocumentSpellCheckOrchestrationService({required this.spellCheckController});

  factory DocumentSpellCheckOrchestrationService.fromSpellCheck(
    SpellCheckService spellCheck,
  ) {
    return DocumentSpellCheckOrchestrationService(
      spellCheckController: DocumentSpellCheckController(spellCheck),
    );
  }

  void toggle({
    required SpellCheckStateReader readState,
    required SpellCheckStateEmitter emitState,
  }) {
    final enabled = !readState().spellCheckEnabled;
    emitState(readState().copyWith(spellCheckEnabled: enabled));

    if (enabled) {
      _start(readState: readState, emitState: emitState);
    } else {
      spellCheckController.stop(
        onErrors: (errors) => _emitErrors(
          readState: readState,
          emitState: emitState,
          errors: errors,
        ),
      );
    }
  }

  void addToDictionary({
    required SpellCheckStateReader readState,
    required SpellCheckStateEmitter emitState,
    required String word,
  }) {
    spellCheckController.addToDictionary(word);
    runIfEnabled(readState: readState, emitState: emitState);
  }

  void ignoreWord({
    required SpellCheckStateReader readState,
    required SpellCheckStateEmitter emitState,
    required String word,
  }) {
    spellCheckController.ignoreWord(word);
    runIfEnabled(readState: readState, emitState: emitState);
  }

  void replaceWithSuggestion({
    required SpellCheckStateReader readState,
    required SpellCheckStateEmitter emitState,
    required SpellCheckError error,
    required String suggestion,
  }) {
    final current = readState();
    current.controller.replaceText(
      error.offset,
      error.word.length,
      suggestion,
      TextSelection.collapsed(offset: error.offset + suggestion.length),
    );
    runIfEnabled(readState: readState, emitState: emitState);
  }

  void runIfEnabled({
    required SpellCheckStateReader readState,
    required SpellCheckStateEmitter emitState,
  }) {
    if (!readState().spellCheckEnabled) return;

    spellCheckController.run(
      readText: () => _plainText(readState),
      onErrors: (errors) => _emitErrors(
        readState: readState,
        emitState: emitState,
        errors: errors,
      ),
    );
  }

  void dispose() {
    spellCheckController.dispose();
  }

  void _start({
    required SpellCheckStateReader readState,
    required SpellCheckStateEmitter emitState,
  }) {
    spellCheckController.start(
      readText: () => _plainText(readState),
      onErrors: (errors) => _emitErrors(
        readState: readState,
        emitState: emitState,
        errors: errors,
      ),
    );
  }

  String _plainText(SpellCheckStateReader readState) {
    return readState().controller.document.toPlainText();
  }

  void _emitErrors({
    required SpellCheckStateReader readState,
    required SpellCheckStateEmitter emitState,
    required List<SpellCheckError> errors,
  }) {
    emitState(readState().copyWith(spellErrors: errors));
  }
}

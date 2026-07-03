import 'package:flutter/services.dart';

import '../models/aiaction.dart';
import '../models/document_state.dart';
import 'document_ai_controller.dart';

typedef AiDocumentStateReader = DocumentState Function();
typedef AiDocumentStateEmitter = void Function(DocumentState state);

class DocumentAiOrchestrationService {
  final DocumentAiController aiController;

  const DocumentAiOrchestrationService({required this.aiController});

  factory DocumentAiOrchestrationService.fromProcessor(
    AiTextProcessor processText,
  ) {
    return DocumentAiOrchestrationService(
      aiController: DocumentAiController(processText: processText),
    );
  }

  Future<void> applyAction({
    required AiDocumentStateReader readState,
    required AiDocumentStateEmitter emitState,
    required AIAction action,
  }) async {
    emitState(
      readState().copyWith(
        isAIProcessing: true,
        clearError: true,
        clearAIResult: true,
      ),
    );

    try {
      final current = readState();
      final selection = current.controller.selection;
      final result = await aiController.processAction(
        documentText: current.controller.document.toPlainText(),
        selectionBaseOffset: selection.baseOffset,
        selectionExtentOffset: selection.extentOffset,
        action: action,
      );

      emitState(readState().copyWith(isAIProcessing: false, aiResult: result));
    } catch (error) {
      emitState(
        readState().copyWith(
          isAIProcessing: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void replaceResult({
    required AiDocumentStateReader readState,
    required AiDocumentStateEmitter emitState,
  }) {
    final current = readState();
    final result = current.aiResult;
    if (result == null) return;

    final selection = current.controller.selection;
    final plan = aiController.replacementPlan(
      selectionBaseOffset: selection.baseOffset,
      selectionExtentOffset: selection.extentOffset,
      documentLength: current.controller.document.length,
      result: result,
    );

    current.controller.replaceText(
      plan.start,
      plan.length,
      result,
      TextSelection.collapsed(offset: plan.cursorOffset),
    );

    emitState(readState().copyWith(clearAIResult: true));
  }

  void insertResult({
    required AiDocumentStateReader readState,
    required AiDocumentStateEmitter emitState,
  }) {
    final current = readState();
    final result = current.aiResult;
    if (result == null) return;

    final offset = current.controller.selection.baseOffset;
    current.controller.document.insert(
      offset,
      aiController.insertionText(result),
    );
    emitState(readState().copyWith(clearAIResult: true));
  }

  void clearResult({
    required AiDocumentStateReader readState,
    required AiDocumentStateEmitter emitState,
  }) {
    emitState(readState().copyWith(clearAIResult: true));
  }
}

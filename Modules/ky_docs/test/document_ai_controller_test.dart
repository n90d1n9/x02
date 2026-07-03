import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/aiaction.dart';
import 'package:ky_docs/docx/services/document_ai_controller.dart';

void main() {
  group('DocumentAiController', () {
    test('uses selected text when selection is expanded', () {
      final controller = DocumentAiController(
        processText: (text, action) async => text,
      );

      final text = controller.textForProcessing(
        documentText: 'hello thoughtful world',
        selectionBaseOffset: 6,
        selectionExtentOffset: 16,
      );

      expect(text, 'thoughtful');
    });

    test('uses full document when selection is collapsed', () {
      final controller = DocumentAiController(
        processText: (text, action) async => text,
      );

      final text = controller.textForProcessing(
        documentText: 'hello world',
        selectionBaseOffset: 5,
        selectionExtentOffset: 5,
      );

      expect(text, 'hello world');
    });

    test('rejects empty document text without a selection', () {
      final controller = DocumentAiController(
        processText: (text, action) async => text,
      );

      expect(
        () => controller.textForProcessing(
          documentText: '   ',
          selectionBaseOffset: 0,
          selectionExtentOffset: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('invokes processor with selected text and action', () async {
      String? processedText;
      AIAction? processedAction;
      final controller = DocumentAiController(
        processText: (text, action) async {
          processedText = text;
          processedAction = action;
          return 'processed';
        },
      );

      final result = await controller.processAction(
        documentText: 'Please improve this sentence',
        selectionBaseOffset: 7,
        selectionExtentOffset: 14,
        action: AIAction.improve,
      );

      expect(result, 'processed');
      expect(processedText, 'improve');
      expect(processedAction, AIAction.improve);
    });

    test('builds replacement plan for selected text', () {
      final controller = DocumentAiController(
        processText: (text, action) async => text,
      );

      final plan = controller.replacementPlan(
        selectionBaseOffset: 14,
        selectionExtentOffset: 7,
        documentLength: 25,
        result: 'better',
      );

      expect(plan.start, 7);
      expect(plan.length, 7);
      expect(plan.cursorOffset, 13);
    });

    test('builds replacement plan for full document replacement', () {
      final controller = DocumentAiController(
        processText: (text, action) async => text,
      );

      final plan = controller.replacementPlan(
        selectionBaseOffset: 5,
        selectionExtentOffset: 5,
        documentLength: 12,
        result: 'new text',
      );

      expect(plan.start, 0);
      expect(plan.length, 11);
      expect(plan.cursorOffset, 8);
    });

    test('formats inserted AI result with surrounding whitespace', () {
      final controller = DocumentAiController(
        processText: (text, action) async => text,
      );

      expect(controller.insertionText('result'), '\n\nresult\n\n');
    });
  });
}

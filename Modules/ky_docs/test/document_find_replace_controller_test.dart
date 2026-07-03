import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/find_replace/find_replace_controller.dart';

void main() {
  group('DocxFindReplaceController', () {
    test('searches case-insensitively by default and navigates matches', () {
      final editorController = _controllerWithText(
        'Budget budget budgeting Budget.',
      );
      final controller = DocxFindReplaceController(
        editorController: editorController,
      );
      addTearDown(controller.dispose);
      addTearDown(editorController.dispose);

      controller.performSearch('budget');

      expect(controller.matchCount, 4);
      expect(controller.matchLabel, '1 of 4');
      expect(editorController.selection.baseOffset, 0);

      controller.goToNextMatch();

      expect(controller.currentMatchIndex, 1);
      expect(controller.matchLabel, '2 of 4');
      expect(editorController.selection.baseOffset, 7);
    });

    test('narrows results with match case and whole word options', () {
      final editorController = _controllerWithText(
        'Budget budget budgeting Budget.',
      );
      final controller = DocxFindReplaceController(
        editorController: editorController,
      );
      addTearDown(controller.dispose);
      addTearDown(editorController.dispose);

      controller.performSearch('Budget');
      expect(controller.matchCount, 4);

      controller.setMatchCase(true);
      expect(controller.matchCount, 2);

      controller.setMatchCase(false);
      controller.setWholeWord(true);
      expect(controller.matchCount, 3);
    });

    test('replaces only whole-word matches when whole word is enabled', () {
      final editorController = _controllerWithText('plan planning plan');
      final controller = DocxFindReplaceController(
        editorController: editorController,
      );
      addTearDown(controller.dispose);
      addTearDown(editorController.dispose);

      controller.performSearch('plan');
      controller.setWholeWord(true);
      controller.replaceTextController.text = 'draft';

      final replacements = controller.replaceAllMatches();

      expect(replacements, 2);
      expect(
        editorController.document.toPlainText(),
        contains('draft planning draft'),
      );
      expect(controller.matchLabel, 'No matches');
    });

    test('does not replace text while the editor is read-only', () {
      final editorController = _controllerWithText('alpha beta alpha')
        ..readOnly = true;
      final controller = DocxFindReplaceController(
        editorController: editorController,
      );
      addTearDown(controller.dispose);
      addTearDown(editorController.dispose);

      controller.performSearch('alpha');
      controller.replaceTextController.text = 'omega';

      expect(controller.replaceCurrentMatch(), isFalse);
      expect(controller.replaceAllMatches(), 0);
      expect(
        editorController.document.toPlainText(),
        contains('alpha beta alpha'),
      );
    });

    test('notifies listeners when replacement preview text changes', () {
      final editorController = _controllerWithText('alpha beta alpha');
      final controller = DocxFindReplaceController(
        editorController: editorController,
      );
      addTearDown(controller.dispose);
      addTearDown(editorController.dispose);
      var notificationCount = 0;
      controller.addListener(() => notificationCount += 1);

      controller.replaceTextController.text = 'omega';

      expect(notificationCount, 1);
    });
  });
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  return controller;
}

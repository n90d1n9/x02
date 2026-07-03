import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/blank_document/blank_document_starter_host.dart';
import 'package:ky_docs/docx/widgets/blank_document/blank_document_starter_panel.dart';

void main() {
  group('BlankDocumentStarterHost', () {
    testWidgets('shows starter panel for blank documents', (tester) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await _pumpHost(tester, controller: controller);

      expect(find.byKey(BlankDocumentStarterPanel.panelKey), findsOneWidget);
    });

    testWidgets('inserts a selected starter and requests editor focus', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      var focusRequested = false;

      await _pumpHost(
        tester,
        controller: controller,
        onRequestEditorFocus: () => focusRequested = true,
      );

      await tester.tap(
        find.byKey(const Key('blank-document-starter-template-meetingNotes')),
      );
      await tester.pump();

      expect(controller.document.toPlainText(), contains('# Meeting notes'));
      expect(controller.document.toPlainText(), contains('## Decisions'));
      expect(find.byKey(BlankDocumentStarterPanel.panelKey), findsNothing);
      expect(focusRequested, isTrue);
    });

    testWidgets('stays hidden for existing document content', (tester) async {
      final controller = _controllerWithText('Existing draft');
      addTearDown(controller.dispose);

      await _pumpHost(tester, controller: controller);

      expect(find.byKey(BlankDocumentStarterPanel.panelKey), findsNothing);
    });

    testWidgets('allows users to dismiss starter options', (tester) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await _pumpHost(tester, controller: controller);

      await tester.tap(find.byKey(BlankDocumentStarterPanel.dismissKey));
      await tester.pump();

      expect(find.byKey(BlankDocumentStarterPanel.panelKey), findsNothing);
      expect(controller.document.toPlainText().trim(), isEmpty);
    });
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required quill.QuillController controller,
  VoidCallback? onRequestEditorFocus,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 760,
          height: 420,
          child: BlankDocumentStarterHost(
            controller: controller,
            onRequestEditorFocus: onRequestEditorFocus,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  controller.updateSelection(
    TextSelection.collapsed(offset: text.length),
    quill.ChangeSource.local,
  );
  return controller;
}

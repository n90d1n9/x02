import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/find_replace/find_replace_panel.dart';

void main() {
  group('DocxFindReplacePanel', () {
    testWidgets('shows match state and applies search options', (tester) async {
      final controller = _controllerWithText('Alpha alpha beta');
      addTearDown(controller.dispose);

      await _pumpPanel(tester, controller: controller);

      expect(find.text('Ready'), findsOneWidget);

      await tester.enterText(
        find.byKey(DocxFindReplacePanel.findFieldKey),
        'Alpha',
      );
      await tester.pump();

      expect(find.text('1 of 2'), findsOneWidget);

      await tester.tap(find.byKey(DocxFindReplacePanel.matchCaseKey));
      await tester.pump();

      expect(find.text('1 of 1'), findsOneWidget);
    });

    testWidgets('replaces all matches and reports the result', (tester) async {
      final controller = _controllerWithText('alpha beta alpha');
      addTearDown(controller.dispose);

      await _pumpPanel(tester, controller: controller);
      await tester.enterText(
        find.byKey(DocxFindReplacePanel.findFieldKey),
        'alpha',
      );
      await tester.enterText(
        find.byKey(DocxFindReplacePanel.replaceFieldKey),
        'omega',
      );
      await tester.tap(find.text('All'));
      await tester.pump();

      expect(controller.document.toPlainText(), contains('omega beta omega'));
      expect(find.text('Replaced 2 occurrence(s)'), findsOneWidget);
    });

    testWidgets('previews pending replacements as replacement text changes', (
      tester,
    ) async {
      final controller = _controllerWithText('alpha beta alpha');
      addTearDown(controller.dispose);

      await _pumpPanel(tester, controller: controller);
      await tester.enterText(
        find.byKey(DocxFindReplacePanel.findFieldKey),
        'alpha',
      );
      await tester.pump();

      expect(
        find.byKey(DocxFindReplacePanel.replacementPreviewKey),
        findsOneWidget,
      );
      expect(find.text('Replace 2 matches with empty text'), findsOneWidget);

      await tester.enterText(
        find.byKey(DocxFindReplacePanel.replaceFieldKey),
        'omega',
      );
      await tester.pump();

      expect(find.text('Replace 2 matches with "omega"'), findsOneWidget);
      expect(find.text('Current matches will become "omega".'), findsOneWidget);
    });

    testWidgets('uses find-only controls in viewing mode', (tester) async {
      final controller = _controllerWithText('alpha beta alpha');
      addTearDown(controller.dispose);

      await _pumpPanel(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.viewing,
      );

      expect(find.text('Find'), findsWidgets);
      expect(find.text('Find & Replace'), findsNothing);
      expect(find.byKey(DocxFindReplacePanel.modeBadgeKey), findsOneWidget);
      expect(find.text('Find only'), findsOneWidget);
      expect(find.byKey(DocxFindReplacePanel.replaceFieldKey), findsNothing);
      expect(find.text('All'), findsNothing);

      await tester.enterText(
        find.byKey(DocxFindReplacePanel.findFieldKey),
        'alpha',
      );
      await tester.pump();

      expect(find.text('1 of 2'), findsOneWidget);
      expect(controller.document.toPlainText(), contains('alpha beta alpha'));
    });

    testWidgets('routes close action to the editor shell', (tester) async {
      final controller = _controllerWithText('Draft');
      addTearDown(controller.dispose);
      var closed = false;

      await _pumpPanel(
        tester,
        controller: controller,
        onClose: () => closed = true,
      );

      await tester.tap(find.byKey(DocxFindReplacePanel.closeButtonKey));

      expect(closed, isTrue);
    });

    testWidgets('supports embedded dock mode without duplicate title', (
      tester,
    ) async {
      final controller = _controllerWithText('Alpha beta');
      addTearDown(controller.dispose);

      await _pumpPanel(tester, controller: controller, showHeader: false);

      expect(find.text('Find & Replace'), findsNothing);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byKey(DocxFindReplacePanel.matchCaseKey), findsOneWidget);
      expect(find.byKey(DocxFindReplacePanel.findFieldKey), findsOneWidget);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required quill.QuillController controller,
  DocumentEditingMode editingMode = DocumentEditingMode.editing,
  VoidCallback? onClose,
  bool showHeader = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 900,
          child: DocxFindReplacePanel(
            controller: controller,
            editingMode: editingMode,
            onClose: onClose,
            showHeader: showHeader,
          ),
        ),
      ),
    ),
  );
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  return controller;
}

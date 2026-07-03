import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_text_style_status_chip.dart';

void main() {
  group('DocumentTextStyleStatusChip', () {
    testWidgets('updates when selection style changes', (tester) async {
      final controller = _controllerWithText('Styled heading');
      addTearDown(controller.dispose);

      await _pumpChip(tester, controller: controller);

      expect(find.byKey(DocumentTextStyleStatusChip.chipKey), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);

      controller.formatSelection(quill.Attribute.h2);
      controller.formatSelection(quill.Attribute.bold);
      await tester.pump();

      expect(find.text('Heading 2 - Bold'), findsOneWidget);
    });

    testWidgets('reflects list style changes from the controller', (
      tester,
    ) async {
      final controller = _controllerWithText('Styled list item');
      addTearDown(controller.dispose);

      await _pumpChip(tester, controller: controller);

      controller.formatSelection(quill.Attribute.ul);
      await tester.pump();

      expect(find.text('Bulleted list'), findsOneWidget);
    });

    testWidgets('opens current style details popover', (tester) async {
      final controller = _controllerWithText('Styled heading');
      addTearDown(controller.dispose);

      await _pumpChip(tester, controller: controller);

      controller.formatSelection(quill.Attribute.h2);
      controller.formatSelection(quill.Attribute.bold);
      controller.formatSelection(quill.Attribute.underline);
      await tester.pump();

      await tester.tap(find.byKey(DocumentTextStyleStatusChip.chipKey));
      await tester.pumpAndSettle();

      expect(find.byKey(DocumentTextStyleStatusChip.menuKey), findsOneWidget);
      expect(find.text('Text style'), findsOneWidget);
      expect(find.text('Paragraph'), findsOneWidget);
      expect(find.text('Heading 2'), findsOneWidget);
      expect(find.text('Inline marks'), findsOneWidget);
      expect(find.text('Bold, Underline'), findsOneWidget);
    });
  });
}

Future<void> _pumpChip(
  WidgetTester tester, {
  required quill.QuillController controller,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: DocumentTextStyleStatusChip(controller: controller),
        ),
      ),
    ),
  );
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  controller.updateSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
    quill.ChangeSource.local,
  );
  return controller;
}

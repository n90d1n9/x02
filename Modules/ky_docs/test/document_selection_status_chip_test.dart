import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_selection_status_chip.dart';

void main() {
  group('DocumentSelectionStatusChip', () {
    testWidgets('appears only while text is selected', (tester) async {
      final controller = _controllerWithText('Selected words here');
      addTearDown(controller.dispose);

      await _pumpChip(tester, controller: controller);

      expect(find.byKey(DocumentSelectionStatusChip.chipKey), findsNothing);

      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 14),
        quill.ChangeSource.local,
      );
      await tester.pump();

      expect(find.byKey(DocumentSelectionStatusChip.chipKey), findsOneWidget);
      expect(find.text('2 words selected'), findsOneWidget);
      expect(
        find.byTooltip('Selected: 2 words, 14 characters'),
        findsOneWidget,
      );

      controller.updateSelection(
        const TextSelection.collapsed(offset: 4),
        quill.ChangeSource.local,
      );
      await tester.pump();

      expect(find.byKey(DocumentSelectionStatusChip.chipKey), findsNothing);
    });

    testWidgets('opens selected text details popover', (tester) async {
      final controller = _controllerWithText('One\n\nTwo three');
      addTearDown(controller.dispose);

      await _pumpChip(tester, controller: controller);

      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 14),
        quill.ChangeSource.local,
      );
      await tester.pump();

      await tester.tap(find.byKey(DocumentSelectionStatusChip.chipKey));
      await tester.pumpAndSettle();

      expect(find.byKey(DocumentSelectionStatusChip.menuKey), findsOneWidget);
      expect(find.text('Selection details'), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Lines'), findsOneWidget);
      expect(find.text('Paragraphs'), findsOneWidget);
      expect(find.text('3 words'), findsOneWidget);
      expect(find.text('14 characters'), findsOneWidget);
      expect(find.text('3 lines'), findsOneWidget);
      expect(find.text('2 paragraphs'), findsOneWidget);
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
          child: DocumentSelectionStatusChip(controller: controller),
        ),
      ),
    ),
  );
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  controller.updateSelection(
    const TextSelection.collapsed(offset: 0),
    quill.ChangeSource.local,
  );
  return controller;
}

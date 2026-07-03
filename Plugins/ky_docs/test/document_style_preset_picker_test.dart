import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/formatting/document_style_preset.dart';
import 'package:ky_docs/docx/widgets/formatting/document_style_preset_picker.dart';

void main() {
  group('DocumentStylePresetPicker', () {
    testWidgets('shows current style and opens preset options', (tester) async {
      final controller = _controllerWithText('Selected paragraph');
      addTearDown(controller.dispose);

      await _pumpPicker(tester, controller: controller);

      expect(find.byKey(DocumentStylePresetPicker.pickerKey), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);

      await tester.tap(find.byKey(DocumentStylePresetPicker.pickerKey));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          DocumentStylePresetPicker.optionKey(DocumentStylePresetId.heading3),
        ),
        findsOneWidget,
      );
      expect(find.text('Heading 3'), findsOneWidget);
    });

    testWidgets('applies selected style to the editor selection', (
      tester,
    ) async {
      final controller = _controllerWithText('Selected paragraph');
      addTearDown(controller.dispose);

      await _pumpPicker(tester, controller: controller);
      await tester.tap(find.byKey(DocumentStylePresetPicker.pickerKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          DocumentStylePresetPicker.optionKey(DocumentStylePresetId.heading3),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        controller
            .getSelectionStyle()
            .attributes[quill.Attribute.header.key]
            ?.value,
        3,
      );
      expect(find.text('Heading 3'), findsOneWidget);
    });
  });
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required quill.QuillController controller,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: DocumentStylePresetPicker(
            controller: controller,
            expanded: true,
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
    TextSelection(baseOffset: 0, extentOffset: text.length),
    quill.ChangeSource.local,
  );
  return controller;
}

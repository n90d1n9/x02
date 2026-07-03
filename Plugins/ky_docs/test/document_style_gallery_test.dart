import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/formatting/document_style_gallery.dart';

void main() {
  group('DocumentStyleGallery', () {
    testWidgets('renders common document style presets', (tester) async {
      final controller = _controllerWithText('Selected heading');
      addTearDown(controller.dispose);

      await _pumpGallery(tester, controller: controller);

      expect(find.byKey(DocumentStyleGallery.galleryKey), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Heading 3'), findsOneWidget);
      expect(find.text('Quote'), findsOneWidget);
    });

    testWidgets('applies tapped presets to the editor selection', (
      tester,
    ) async {
      final controller = _controllerWithText('Selected heading');
      addTearDown(controller.dispose);

      await _pumpGallery(tester, controller: controller);

      await tester.tap(find.byKey(const Key('document-style-preset-heading2')));
      await tester.pump();

      expect(
        controller
            .getSelectionStyle()
            .attributes[quill.Attribute.header.key]
            ?.value,
        2,
      );

      await tester.tap(find.byKey(const Key('document-style-preset-normal')));
      await tester.pump();

      expect(
        controller.getSelectionStyle().attributes.containsKey(
          quill.Attribute.header.key,
        ),
        isFalse,
      );
    });
  });
}

Future<void> _pumpGallery(
  WidgetTester tester, {
  required quill.QuillController controller,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 980,
          child: DocumentStyleGallery(controller: controller),
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

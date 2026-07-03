import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/document_formatting_toolbar.dart';
import 'package:ky_docs/docx/widgets/formatting/document_style_gallery.dart';
import 'package:ky_docs/docx/widgets/formatting/document_style_preset_picker.dart';

void main() {
  group('DocumentFormattingToolbar', () {
    testWidgets('keeps advanced formatting available on wide surfaces', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await _pumpToolbar(tester, controller: controller, width: 960);

      final toolbar = tester.widget<quill.QuillSimpleToolbar>(
        find.byKey(DocumentFormattingToolbar.toolbarKey),
      );

      expect(find.byKey(DocumentFormattingToolbar.surfaceKey), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Paragraph'), findsOneWidget);
      expect(find.byKey(DocumentStyleGallery.galleryKey), findsOneWidget);
      expect(find.byKey(DocumentStylePresetPicker.pickerKey), findsNothing);
      expect(find.text('Heading 1'), findsOneWidget);
      expect(toolbar.config.showAlignmentButtons, isTrue);
      expect(toolbar.config.showCodeBlock, isTrue);
      expect(toolbar.config.showHeaderStyle, isTrue);
      expect(toolbar.config.showSubscript, isTrue);
    });

    testWidgets('prioritizes core formatting on compact surfaces', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await _pumpToolbar(tester, controller: controller, width: 520);

      final toolbar = tester.widget<quill.QuillSimpleToolbar>(
        find.byKey(DocumentFormattingToolbar.toolbarKey),
      );

      expect(find.text('Home'), findsNothing);
      expect(find.byKey(DocumentStyleGallery.galleryKey), findsNothing);
      expect(find.byKey(DocumentStylePresetPicker.pickerKey), findsOneWidget);
      expect(toolbar.config.showColorButton, isTrue);
      expect(toolbar.config.showLink, isTrue);
      expect(toolbar.config.showAlignmentButtons, isFalse);
      expect(toolbar.config.showCodeBlock, isFalse);
      expect(toolbar.config.showHeaderStyle, isFalse);
      expect(toolbar.config.showSubscript, isFalse);
    });
  });
}

Future<void> _pumpToolbar(
  WidgetTester tester, {
  required quill.QuillController controller,
  required double width,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        quill.FlutterQuillLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: DocumentFormattingToolbar(controller: controller),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1));
}

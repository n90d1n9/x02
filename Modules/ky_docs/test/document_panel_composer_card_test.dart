import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_composer_card.dart';

void main() {
  group('DocumentPanelComposerCard', () {
    testWidgets('renders draft field and disables submit without draft', (
      tester,
    ) async {
      var submitted = false;
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpComposer(
        tester,
        controller: controller,
        hasDraft: false,
        onSubmit: () => submitted = true,
      );

      expect(find.widgetWithText(TextField, 'Write update'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      expect(_submitButton(tester).onPressed, isNull);

      await tester.tap(find.text('Post'));

      expect(submitted, isFalse);
    });

    testWidgets('routes submit when draft is available', (tester) async {
      var submitted = false;
      final controller = TextEditingController(text: 'Ready to post.');
      addTearDown(controller.dispose);

      await _pumpComposer(
        tester,
        controller: controller,
        hasDraft: true,
        onSubmit: () => submitted = true,
      );

      expect(_submitButton(tester).onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('composer-submit')));

      expect(submitted, isTrue);
    });
  });
}

Future<void> _pumpComposer(
  WidgetTester tester, {
  required TextEditingController controller,
  required bool hasDraft,
  required VoidCallback onSubmit,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DocumentPanelComposerCard(
          fieldKey: const Key('composer-field'),
          actionKey: const Key('composer-submit'),
          controller: controller,
          fieldLabel: 'Write update',
          actionLabel: 'Post',
          actionIcon: Icons.send_outlined,
          hasDraft: hasDraft,
          onSubmit: onSubmit,
        ),
      ),
    ),
  );
}

FilledButton _submitButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byKey(const Key('composer-submit')));
}

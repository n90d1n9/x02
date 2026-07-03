import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_text_field.dart';

void main() {
  group('DocumentPanelTextField', () {
    testWidgets('renders decorated text input and routes changes', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var latestValue = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelTextField(
              controller: controller,
              labelText: 'Header Text',
              hintText: 'Confidential',
              helperText: 'Shown above each exported page.',
              prefixIcon: Icons.short_text,
              suffixText: 'txt',
              onChanged: (value) => latestValue = value,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.short_text), findsOneWidget);
      expect(find.text('Header Text'), findsOneWidget);
      expect(find.text('Shown above each exported page.'), findsOneWidget);
      expect(find.text('txt'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Draft');
      await tester.pump();

      expect(controller.text, 'Draft');
      expect(latestValue, 'Draft');
    });

    testWidgets('applies input formatters', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelTextField(
              controller: controller,
              labelText: 'Margin',
              suffixText: 'pt',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '12pt');
      await tester.pump();

      expect(controller.text, '12');
    });

    testWidgets('renders suffix action when provided', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var added = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelTextField(
              controller: controller,
              labelText: 'Add Tag',
              suffixIcon: IconButton(
                tooltip: 'Add tag',
                icon: const Icon(Icons.add),
                onPressed: () => added = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Add tag'));

      expect(added, isTrue);
    });
  });
}

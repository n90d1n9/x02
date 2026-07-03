import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_theme.dart';
import 'package:ky_docs/docx/widgets/theme/document_theme_picker.dart';

void main() {
  group('DocumentThemePicker', () {
    testWidgets('renders theme previews and selected state', (tester) async {
      await _pumpPicker(tester, selectedThemeName: 'Modern');

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
      expect(find.text('Modern'), findsOneWidget);
      expect(find.text('Elegant'), findsOneWidget);
      expect(find.text('Font: Arial'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('invokes selection callback with tapped theme', (tester) async {
      DocumentTheme? selectedTheme;

      await _pumpPicker(
        tester,
        selectedThemeName: 'Default',
        onThemeSelected: (theme) => selectedTheme = theme,
      );

      await tester.tap(find.byKey(DocumentThemePicker.themeTileKey('Elegant')));
      await tester.pump();

      expect(selectedTheme?.name, 'Elegant');
    });

    testWidgets('keeps theme details readable in narrow layouts', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: DocumentThemePicker(
                themes: DocumentTheme.predefinedThemes,
                selectedThemeName: 'Default',
                onThemeSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Font: Roboto'), findsOneWidget);
    });
  });
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required String selectedThemeName,
  ValueChanged<DocumentTheme>? onThemeSelected,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 640,
            child: DocumentThemePicker(
              themes: DocumentTheme.predefinedThemes,
              selectedThemeName: selectedThemeName,
              onThemeSelected: onThemeSelected ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

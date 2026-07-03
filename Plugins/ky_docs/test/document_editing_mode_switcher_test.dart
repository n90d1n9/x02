import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_switcher.dart';

void main() {
  group('DocumentEditingMode', () {
    test('exposes stable labels and descriptions', () {
      expect(DocumentEditingMode.editing.label, 'Editing');
      expect(DocumentEditingMode.suggesting.description, contains('review'));
      expect(DocumentEditingMode.viewing.label, 'Viewing');
      expect(DocumentEditingMode.viewing.isReadOnly, isTrue);
      expect(DocumentEditingMode.viewing.showsFormattingToolbar, isFalse);
      expect(DocumentEditingMode.suggesting.showsWorkspaceBanner, isTrue);
    });
  });

  group('DocumentEditingModeSwitcher', () {
    testWidgets('renders current mode and routes selected modes', (
      tester,
    ) async {
      DocumentEditingMode? selectedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentEditingModeSwitcher(
                currentMode: DocumentEditingMode.editing,
                onModeChanged: (mode) => selectedMode = mode,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentEditingModeSwitcher.buttonKey), findsOneWidget);
      expect(find.text('Editing'), findsOneWidget);

      await tester.tap(find.byKey(DocumentEditingModeSwitcher.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suggesting'));
      await tester.pumpAndSettle();

      expect(selectedMode, DocumentEditingMode.suggesting);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/footnotes/footnote_text_dialog.dart';

void main() {
  group('FootnoteTextDialog', () {
    testWidgets(
      'disables action until text is entered and returns trimmed text',
      (tester) async {
        String? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () async {
                      result = await FootnoteTextDialog.show(
                        context,
                        title: 'Add Footnote',
                        actionLabel: 'Add',
                      );
                    },
                    child: const Text('Open footnote dialog'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open footnote dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Add Footnote'), findsOneWidget);
        expect(find.text('Footnote text'), findsOneWidget);
        expect(find.byIcon(Icons.notes_outlined), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add'))
              .onPressed,
          isNull,
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Footnote text'),
          '  Source details  ',
        );
        await tester.pump();

        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add'))
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(result, 'Source details');
      },
    );

    testWidgets('preloads initial text for editing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FootnoteTextDialog(
              title: 'Edit Footnote',
              actionLabel: 'Save',
              initialText: 'Existing note',
            ),
          ),
        ),
      );

      expect(find.text('Edit Footnote'), findsOneWidget);
      expect(find.text('Existing note'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNotNull,
      );
    });
  });
}

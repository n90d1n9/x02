import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/document_title_dialog.dart';

void main() {
  group('DocumentTitleDialog', () {
    testWidgets('returns trimmed title and disables blank saves', (
      tester,
    ) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await DocumentTitleDialog.show(context, title: '');
                  },
                  child: const Text('Open title dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open title dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Document Title'), findsOneWidget);
      expect(find.byIcon(Icons.drive_file_rename_outline), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        '  Plan ',
      );
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, 'Plan');
    });

    testWidgets('prefills the current document title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentTitleDialog(initialTitle: 'Existing Proposal'),
          ),
        ),
      );

      expect(find.text('Existing Proposal'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
            .onPressed,
        isNotNull,
      );
    });
  });
}

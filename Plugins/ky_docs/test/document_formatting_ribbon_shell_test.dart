import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/formatting/document_formatting_ribbon_shell.dart';

void main() {
  group('DocumentFormattingRibbonShell', () {
    testWidgets('renders a full ribbon header on wide surfaces', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              child: DocumentFormattingRibbonShell(
                compact: false,
                sections: [
                  DocumentFormattingRibbonSection(
                    icon: Icons.text_fields,
                    label: 'Text',
                  ),
                  DocumentFormattingRibbonSection(
                    icon: Icons.format_align_left,
                    label: 'Paragraph',
                  ),
                ],
                child: SizedBox(height: 32, child: Text('Toolbar slot')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Paragraph'), findsOneWidget);
      expect(
        find.byKey(DocumentFormattingRibbonShell.toolbarSlotKey),
        findsOneWidget,
      );
      expect(find.text('Toolbar slot'), findsOneWidget);
    });

    testWidgets('keeps compact mode focused on the toolbar slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: DocumentFormattingRibbonShell(
                compact: true,
                sections: [
                  DocumentFormattingRibbonSection(
                    icon: Icons.text_fields,
                    label: 'Text',
                  ),
                ],
                child: SizedBox(height: 32, child: Text('Toolbar slot')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsNothing);
      expect(find.text('Text'), findsNothing);
      expect(find.text('Toolbar slot'), findsOneWidget);
    });
  });
}

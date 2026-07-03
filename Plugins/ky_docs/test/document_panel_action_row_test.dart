import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_action_row.dart';

void main() {
  group('DocumentPanelActionRow', () {
    testWidgets('renders wrapped action children', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelActionRow(
              children: [
                OutlinedButton(
                  onPressed: () => tapped = true,
                  child: const Text('Jump'),
                ),
                const FilledButton(onPressed: null, child: Text('Accept')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Jump'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      await tester.tap(find.text('Jump'));

      expect(tapped, isTrue);
    });

    testWidgets('collapses when no children are provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DocumentPanelActionRow(children: [])),
        ),
      );

      expect(find.byType(Wrap), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}

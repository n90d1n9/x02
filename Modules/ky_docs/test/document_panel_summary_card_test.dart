import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_summary_card.dart';

void main() {
  group('DocumentPanelSummaryCard', () {
    testWidgets('renders summary text and optional trailing action', (
      tester,
    ) async {
      var acted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelSummaryCard(
              icon: Icons.format_list_numbered,
              title: '2 footnotes',
              subtitle: 'References are numbered in reading order.',
              trailing: IconButton(
                tooltip: 'Add item',
                onPressed: () => acted = true,
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2 footnotes'), findsOneWidget);
      expect(
        find.text('References are numbered in reading order.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);

      await tester.tap(find.byTooltip('Add item'));

      expect(acted, isTrue);
    });

    testWidgets('renders error tone without a trailing action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelSummaryCard(
              icon: Icons.spellcheck_outlined,
              title: '1 spelling issue',
              subtitle: '2 replacement suggestions available',
              tone: DocumentPanelSummaryTone.error,
            ),
          ),
        ),
      );

      expect(find.text('1 spelling issue'), findsOneWidget);
      expect(find.text('2 replacement suggestions available'), findsOneWidget);
      expect(find.byIcon(Icons.spellcheck_outlined), findsOneWidget);
    });
  });
}

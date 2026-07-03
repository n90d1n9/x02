import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_empty_state.dart';

void main() {
  group('DocumentPanelEmptyState', () {
    testWidgets('renders neutral empty state content and action', (
      tester,
    ) async {
      var acted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelEmptyState(
              icon: Icons.manage_search_outlined,
              title: 'No matches',
              message: 'Try another filter.',
              iconSize: 32,
              action: FilledButton(
                onPressed: () => acted = true,
                child: const Text('Reset'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('Try another filter.'), findsOneWidget);
      expect(find.byIcon(Icons.manage_search_outlined), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.manage_search_outlined)).size,
        32,
      );

      await tester.tap(find.text('Reset'));

      expect(acted, isTrue);
    });

    testWidgets('renders positive and centered tones', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DocumentPanelEmptyState(
                  icon: Icons.verified_outlined,
                  title: 'All clear',
                  message: 'No issues found.',
                  tone: DocumentPanelEmptyStateTone.positive,
                ),
                Expanded(
                  child: DocumentPanelEmptyState(
                    icon: Icons.subject_outlined,
                    title: 'No headings',
                    message: 'Use heading styles.',
                    tone: DocumentPanelEmptyStateTone.centered,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('All clear'), findsOneWidget);
      expect(find.text('No headings'), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.subject_outlined), findsOneWidget);
    });
  });
}

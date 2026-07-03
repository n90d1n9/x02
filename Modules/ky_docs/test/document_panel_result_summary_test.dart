import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_result_summary.dart';

void main() {
  group('DocumentPanelResultSummary', () {
    testWidgets('renders icon and result message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelResultSummary(
              icon: Icons.manage_search_outlined,
              message: '2 open comments for "draft"',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.manage_search_outlined), findsOneWidget);
      expect(find.text('2 open comments for "draft"'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_section_header.dart';

void main() {
  group('DocumentPanelSectionHeader', () {
    testWidgets('renders compact section heading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelSectionHeader(
              icon: Icons.query_stats_outlined,
              title: 'Document metrics',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.query_stats_outlined), findsOneWidget);
      expect(find.text('Document metrics'), findsOneWidget);
    });

    testWidgets('renders described section heading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelSectionHeader(
              icon: Icons.description_outlined,
              title: 'Page size',
              description: 'Choose the target paper format for export.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.text('Page size'), findsOneWidget);
      expect(
        find.text('Choose the target paper format for export.'),
        findsOneWidget,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_writing_insights.dart';
import 'package:ky_docs/docx/widgets/document_writing_metrics_grid.dart';

void main() {
  group('DocumentWritingMetricsGrid', () {
    testWidgets('renders compact writing metrics', (tester) async {
      final insights = DocumentWritingInsights.fromText(
        'Short sentences help. Clear paragraphs work.\n\n'
        'Another short thought.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentWritingMetricsGrid(metrics: insights.metrics),
          ),
        ),
      );

      expect(find.text('Words'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Avg sentence'), findsOneWidget);
      expect(find.text('3 words'), findsOneWidget);
      expect(find.text('Long sentences'), findsOneWidget);
      expect(find.text('Paragraphs'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}

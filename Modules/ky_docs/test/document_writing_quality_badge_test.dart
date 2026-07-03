import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_writing_insights.dart';
import 'package:ky_docs/docx/widgets/document_writing_quality_badge.dart';

void main() {
  group('DocumentWritingQualityBadge', () {
    testWidgets('renders a configurable writing quality label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentWritingQualityBadge(
              insights: DocumentWritingInsights.fromText(
                'This draft is clear. It has useful rhythm.',
              ),
              includePrefix: true,
              showScore: false,
            ),
          ),
        ),
      );

      expect(find.text('Quality: Polished'), findsOneWidget);
      expect(find.byIcon(Icons.auto_graph), findsOneWidget);
    });

    testWidgets('invokes the optional action when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentWritingQualityBadge(
              insights: DocumentWritingInsights.fromText(
                'This draft is clear. It has useful rhythm.',
              ),
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Polished 100/100'));

      expect(tapped, isTrue);
    });
  });
}

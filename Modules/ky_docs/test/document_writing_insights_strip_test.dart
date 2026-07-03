import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_writing_insights.dart';
import 'package:ky_docs/docx/widgets/document_writing_insights_strip.dart';

void main() {
  group('DocumentWritingInsightsStrip', () {
    testWidgets('renders score and insight chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentWritingInsightsStrip(
              insights: DocumentWritingInsights.fromText(
                'This draft is clear. It has useful rhythm.\n\n'
                'Readers can scan it quickly.',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Polished 100/100'), findsOneWidget);
      expect(find.text('Readability: Easy'), findsOneWidget);
      expect(find.text('Structure: Structured'), findsOneWidget);
      expect(find.text('Rhythm: Steady'), findsOneWidget);
    });

    testWidgets('opens details when the score badge is tapped', (tester) async {
      var opened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentWritingInsightsStrip(
              insights: DocumentWritingInsights.fromText(
                'This draft is clear. It has useful rhythm.',
              ),
              onOpenDetails: () => opened = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Polished 100/100'));

      expect(opened, isTrue);
    });
  });
}

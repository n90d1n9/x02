import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';
import 'package:ky_docs/docx/widgets/document_review_panel.dart';

void main() {
  group('DocumentReviewPanel', () {
    testWidgets('shows quality, metrics, suggestions, and focus areas', (
      tester,
    ) async {
      final longSentence = List.filled(38, 'strategy').join(' ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DocumentReviewPanel(
                statistics: DocumentTextStatistics.fromText(longSentence),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Document quality'), findsOneWidget);
      expect(find.text('Needs review 66/100'), findsOneWidget);
      expect(find.text('Document metrics'), findsOneWidget);
      expect(find.text('Avg sentence'), findsOneWidget);
      expect(find.text('38 words'), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(
        find.text('Break up long sentences for easier scanning'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(find.text('Focus areas'), 180);

      expect(find.text('Focus areas'), findsOneWidget);
      expect(find.text('Readability'), findsOneWidget);
    });

    testWidgets('opens details and closes through callbacks', (tester) async {
      var openedDetails = false;
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DocumentReviewPanel(
                statistics: DocumentTextStatistics.fromText(
                  'This draft is clear. It has structure.\n\n'
                  'Readers can scan quickly.',
                ),
                onOpenWritingInsights: () => openedDetails = true,
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Looks good for now'), findsOneWidget);

      await tester.tap(find.text('Open details'));
      await tester.tap(find.byTooltip('Close review'));

      expect(openedDetails, isTrue);
      expect(closed, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_statistics_status_chip.dart';

void main() {
  group('DocumentStatisticsStatusChip', () {
    testWidgets('opens compact document statistics popover', (tester) async {
      final statistics = DocumentTextStatistics.fromText(
        'First sentence. Second sentence.\n\nNext paragraph.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentStatisticsStatusChip(statistics: statistics),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentStatisticsStatusChip.chipKey), findsOneWidget);
      expect(find.text(statistics.wordCountLabel), findsOneWidget);
      expect(find.byTooltip(statistics.summaryTooltip), findsOneWidget);

      await tester.tap(find.byKey(DocumentStatisticsStatusChip.chipKey));
      await tester.pumpAndSettle();

      expect(find.byKey(DocumentStatisticsStatusChip.menuKey), findsOneWidget);
      expect(find.text('Document statistics'), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Without spaces'), findsOneWidget);
      expect(find.text('Paragraphs'), findsOneWidget);
      expect(find.text('Sentences'), findsOneWidget);
      expect(find.text('Reading time'), findsOneWidget);
      expect(find.text(statistics.characterCountNoSpacesLabel), findsOneWidget);
    });
  });
}

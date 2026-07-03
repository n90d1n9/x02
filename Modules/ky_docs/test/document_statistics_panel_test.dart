import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';
import 'package:ky_docs/docx/widgets/document_statistics_panel.dart';

void main() {
  group('DocumentStatisticsPanel', () {
    testWidgets('shows writing insights with the existing metrics', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(
        0,
        'This draft is clear. It has structure.\n\nReaders can scan quickly.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentStatisticsPanel(
              statistics: DocumentStatistics(controller),
            ),
          ),
        ),
      );

      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Read Time'), findsOneWidget);
      expect(find.text('1 min'), findsOneWidget);
      expect(find.text('Polished 100/100'), findsOneWidget);
      expect(find.text('Readability: Easy'), findsOneWidget);
    });

    testWidgets('opens writing insight details from the score badge', (
      tester,
    ) async {
      var opened = false;
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(
        0,
        'This draft is clear. It has structure.\n\nReaders can scan quickly.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentStatisticsPanel(
              statistics: DocumentStatistics(controller),
              onOpenWritingInsights: () => opened = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Polished 100/100'));

      expect(opened, isTrue);
    });

    testWidgets('shows an optional close action for docked usage', (
      tester,
    ) async {
      var closed = false;
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(0, 'Closeable statistics.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentStatisticsPanel(
              statistics: DocumentStatistics(controller),
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('Writing statistics'), findsOneWidget);

      await tester.tap(find.byKey(DocumentStatisticsPanel.closeButtonKey));

      expect(closed, isTrue);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_header.dart';

void main() {
  group('DocumentPanelHeader', () {
    testWidgets('renders title, subtitle, and close action', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelHeader(
              icon: Icons.rate_review_outlined,
              title: 'Review Hub',
              subtitle: '2 active items',
              closeTooltip: 'Close review hub',
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('Review Hub'), findsOneWidget);
      expect(find.text('2 active items'), findsOneWidget);
      expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
      expect(find.byTooltip('Close review hub'), findsOneWidget);

      await tester.tap(find.byTooltip('Close review hub'));

      expect(closed, isTrue);
    });

    testWidgets('omits close action when callback is absent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelHeader(
              icon: Icons.mode_comment_outlined,
              title: 'Comments',
              subtitle: '0 open, 0 total',
              closeTooltip: 'Close comments',
            ),
          ),
        ),
      );

      expect(find.text('Comments'), findsOneWidget);
      expect(find.byTooltip('Close comments'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/editor_app_bar/document_action_cluster.dart';

void main() {
  group('DocumentActionCluster', () {
    testWidgets('renders children inside a keyed command cluster', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentActionCluster(
              groupId: 'review',
              semanticLabel: 'Review actions',
              children: [
                IconButton(
                  tooltip: 'Review Hub',
                  icon: const Icon(Icons.rate_review_outlined),
                  onPressed: () => pressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byKey(DocumentActionCluster.groupKey('review')),
        findsOneWidget,
      );
      expect(find.byTooltip('Review Hub'), findsOneWidget);

      await tester.tap(find.byTooltip('Review Hub'));

      expect(pressed, isTrue);
    });

    testWidgets('does not paint an empty command cluster', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentActionCluster(
              groupId: 'empty',
              semanticLabel: 'Empty actions',
              children: [],
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentActionCluster.groupKey('empty')), findsNothing);
    });
  });
}

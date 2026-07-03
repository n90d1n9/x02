import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_tab_strip.dart';

enum _TabFixture { review, comments }

void main() {
  group('DocumentPanelTabStrip', () {
    testWidgets('renders tabs with counts and routes selection', (
      tester,
    ) async {
      _TabFixture? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelTabStrip<_TabFixture>(
              keyPrefix: 'fixture-tab',
              selectedValue: _TabFixture.review,
              options: const [
                DocumentPanelTabOption(
                  value: _TabFixture.review,
                  keySuffix: 'review',
                  label: 'Review',
                  icon: Icons.rate_review_outlined,
                  count: 2,
                  tooltip: 'Show review',
                ),
                DocumentPanelTabOption(
                  value: _TabFixture.comments,
                  keySuffix: 'comments',
                  label: 'Comments',
                  icon: Icons.mode_comment_outlined,
                  count: 1,
                  tooltip: 'Show comments',
                ),
              ],
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      );

      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byTooltip('Show comments'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fixture-tab-comments')));

      expect(selected, _TabFixture.comments);
    });
  });
}

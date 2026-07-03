import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_empty_state.dart';

void main() {
  group('DocumentCommandEmptyState', () {
    testWidgets('shows clear and reset actions when both filters apply', (
      tester,
    ) async {
      var clearedSearch = false;
      var resetCategory = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandEmptyState(
              query: 'share',
              categoryLabel: 'Review',
              canClearSearch: true,
              canResetCategory: true,
              onClearSearch: () => clearedSearch = true,
              onResetCategory: () => resetCategory = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(DocumentCommandEmptyState.emptyStateKey),
        findsOneWidget,
      );
      expect(find.text('No commands found'), findsOneWidget);
      expect(find.text('No matches for "share" in Review.'), findsOneWidget);

      await tester.tap(
        find.byKey(DocumentCommandEmptyState.clearSearchButtonKey),
      );
      await tester.tap(
        find.byKey(DocumentCommandEmptyState.resetCategoryButtonKey),
      );

      expect(clearedSearch, isTrue);
      expect(resetCategory, isTrue);
    });

    testWidgets('hides actions when there is nothing to reset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentCommandEmptyState(
              query: '',
              categoryLabel: 'All',
              canClearSearch: false,
              canResetCategory: false,
              onClearSearch: _noop,
              onResetCategory: _noop,
            ),
          ),
        ),
      );

      expect(
        find.byKey(DocumentCommandEmptyState.clearSearchButtonKey),
        findsNothing,
      );
      expect(
        find.byKey(DocumentCommandEmptyState.resetCategoryButtonKey),
        findsNothing,
      );
    });
  });
}

void _noop() {}

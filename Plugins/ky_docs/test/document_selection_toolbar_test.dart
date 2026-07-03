import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/selection_toolbar/document_selection_toolbar.dart';

void main() {
  group('DocumentSelectionToolbar', () {
    testWidgets('stays hidden when there is no active selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              visible: false,
              selectedCharacterCount: 0,
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentSelectionToolbar.toolbarKey), findsNothing);
    });

    testWidgets('renders selected text actions and routes callbacks', (
      tester,
    ) async {
      var boldTapped = false;
      var underlineTapped = false;
      var quoteTapped = false;
      var clearFormattingTapped = false;
      var copyTapped = false;
      var commentTapped = false;
      var improveTapped = false;
      var suggestTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              visible: true,
              selectedCharacterCount: 14,
              boldActive: true,
              underlineActive: true,
              quoteActive: true,
              onCopy: () => copyTapped = true,
              onBold: () => boldTapped = true,
              onUnderline: () => underlineTapped = true,
              onQuote: () => quoteTapped = true,
              onClearFormatting: () => clearFormattingTapped = true,
              onComment: () => commentTapped = true,
              onImprove: () => improveTapped = true,
              onSuggestChange: () => suggestTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('14 selected'), findsOneWidget);
      expect(find.byTooltip('Copy'), findsOneWidget);
      expect(find.byTooltip('Bold'), findsOneWidget);
      expect(find.byTooltip('Underline'), findsOneWidget);
      expect(find.byTooltip('Quote'), findsOneWidget);
      expect(find.byTooltip('Clear formatting'), findsOneWidget);
      expect(find.byTooltip('Comment'), findsOneWidget);
      expect(find.byTooltip('Improve'), findsOneWidget);
      expect(find.byTooltip('Suggest change'), findsOneWidget);

      await tester.tap(find.byTooltip('Copy'));
      await tester.tap(find.byTooltip('Bold'));
      await tester.tap(find.byTooltip('Underline'));
      await tester.tap(find.byTooltip('Quote'));
      await tester.tap(find.byTooltip('Clear formatting'));
      await tester.tap(find.byTooltip('Comment'));
      await tester.tap(find.byTooltip('Improve'));
      await tester.tap(find.byTooltip('Suggest change'));

      expect(copyTapped, isTrue);
      expect(boldTapped, isTrue);
      expect(underlineTapped, isTrue);
      expect(quoteTapped, isTrue);
      expect(clearFormattingTapped, isTrue);
      expect(commentTapped, isTrue);
      expect(improveTapped, isTrue);
      expect(suggestTapped, isTrue);
    });

    testWidgets('keeps viewing mode focused on copy-only selection work', (
      tester,
    ) async {
      var copyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              visible: true,
              selectedCharacterCount: 8,
              editingMode: DocumentEditingMode.viewing,
              onCopy: () => copyTapped = true,
              onBold: () {},
              onUnderline: () {},
              onQuote: () {},
              onClearFormatting: () {},
              onComment: () {},
              onImprove: () {},
              onSuggestChange: () {},
            ),
          ),
        ),
      );

      expect(find.text('8 selected'), findsOneWidget);
      expect(find.byKey(DocumentSelectionToolbar.modeBadgeKey), findsOneWidget);
      expect(find.text('Viewing'), findsOneWidget);
      expect(find.byTooltip('Copy'), findsOneWidget);
      expect(find.byTooltip('Bold'), findsNothing);
      expect(find.byTooltip('Underline'), findsNothing);
      expect(find.byTooltip('Quote'), findsNothing);
      expect(find.byTooltip('Clear formatting'), findsNothing);
      expect(find.byTooltip('Comment'), findsNothing);
      expect(find.byTooltip('Improve'), findsNothing);
      expect(find.byTooltip('Suggest change'), findsNothing);

      await tester.tap(find.byKey(DocumentSelectionToolbar.copyActionKey));

      expect(copyTapped, isTrue);
    });

    testWidgets('disables improve while AI processing is active', (
      tester,
    ) async {
      var improveTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentSelectionToolbar(
              visible: true,
              selectedCharacterCount: 4,
              aiProcessing: true,
              onImprove: () => improveTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Improving selection'));

      expect(improveTapped, isFalse);
    });
  });
}

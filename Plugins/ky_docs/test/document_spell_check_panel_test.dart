import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/spell_check_error.dart';
import 'package:ky_docs/docx/widgets/spell_check/document_spell_check_filter.dart';
import 'package:ky_docs/docx/widgets/spell_check/document_spell_check_panel.dart';

void main() {
  group('DocumentSpellCheckPanel', () {
    testWidgets('renders all-clear state when there are no errors', (
      tester,
    ) async {
      await _pumpPanel(tester, errors: const []);

      expect(find.text('All clear'), findsOneWidget);
      expect(find.text('No spelling issues found'), findsOneWidget);
    });

    testWidgets('renders issue summary and routes replacement actions', (
      tester,
    ) async {
      SpellCheckError? replacedError;
      String? replacement;
      final error = SpellCheckError(
        word: 'wrte',
        offset: 6,
        suggestions: const ['write', 'wrote'],
      );

      await _pumpPanel(
        tester,
        errors: [error],
        onReplaceWithSuggestion: (error, suggestion) {
          replacedError = error;
          replacement = suggestion;
        },
      );

      expect(find.text('1 spelling issue'), findsOneWidget);
      expect(find.text('2 replacement suggestions available'), findsOneWidget);
      expect(find.text('All 1'), findsOneWidget);
      expect(find.text('Suggestions 1'), findsOneWidget);
      expect(find.text('No suggestions 0'), findsOneWidget);
      expect(find.text('1 spelling issue visible'), findsOneWidget);
      expect(find.text('wrte'), findsOneWidget);
      expect(find.text('Character 6'), findsOneWidget);

      await tester.tap(find.text('write'));

      expect(replacedError, same(error));
      expect(replacement, 'write');
    });

    testWidgets('routes ignore and dictionary actions', (tester) async {
      SpellCheckError? ignoredError;
      SpellCheckError? dictionaryError;
      final error = SpellCheckError(
        word: 'teh',
        offset: 0,
        suggestions: const [],
      );

      await _pumpPanel(
        tester,
        errors: [error],
        onIgnore: (error) => ignoredError = error,
        onAddToDictionary: (error) => dictionaryError = error,
      );

      expect(find.text('No suggestions available'), findsOneWidget);

      await tester.tap(find.text('Ignore'));
      await tester.tap(find.text('Add to dictionary'));

      expect(ignoredError, same(error));
      expect(dictionaryError, same(error));
    });

    testWidgets('filters issues by suggestion availability', (tester) async {
      await _pumpPanel(
        tester,
        errors: [
          SpellCheckError(
            word: 'wrte',
            offset: 6,
            suggestions: const ['write'],
          ),
          SpellCheckError(word: 'teh', offset: 12, suggestions: const []),
        ],
      );

      await tester.tap(
        find.byKey(
          Key(
            '${DocumentSpellCheckPanel.filterPrefixKey}-'
            '${DocumentSpellCheckIssueFilter.withSuggestions.name}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('wrte'), findsOneWidget);
      expect(find.text('teh'), findsNothing);
      expect(find.text('1 issue with suggestions'), findsOneWidget);

      await tester.tap(
        find.byKey(
          Key(
            '${DocumentSpellCheckPanel.filterPrefixKey}-'
            '${DocumentSpellCheckIssueFilter.noSuggestions.name}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('wrte'), findsNothing);
      expect(find.text('teh'), findsOneWidget);
      expect(find.text('1 issue needing manual review'), findsOneWidget);
      expect(find.text('No suggestions available'), findsOneWidget);
    });

    testWidgets('shows an empty state for filters without matching issues', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        errors: [
          SpellCheckError(
            word: 'wrte',
            offset: 6,
            suggestions: const ['write'],
          ),
        ],
      );

      await tester.tap(
        find.byKey(
          Key(
            '${DocumentSpellCheckPanel.filterPrefixKey}-'
            '${DocumentSpellCheckIssueFilter.noSuggestions.name}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(DocumentSpellCheckPanel.filteredEmptyStateKey),
        findsOneWidget,
      );
      expect(find.text('No manual review needed'), findsOneWidget);
      expect(find.text('0 issues needing manual review'), findsOneWidget);
      expect(find.text('wrte'), findsNothing);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<SpellCheckError> errors,
  SpellCheckSuggestionAction? onReplaceWithSuggestion,
  ValueChanged<SpellCheckError>? onIgnore,
  ValueChanged<SpellCheckError>? onAddToDictionary,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DocumentSpellCheckPanel(
            errors: errors,
            onReplaceWithSuggestion: onReplaceWithSuggestion ?? (_, _) {},
            onIgnore: onIgnore ?? (_) {},
            onAddToDictionary: onAddToDictionary ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

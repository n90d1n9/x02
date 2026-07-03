import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/spell_check_error.dart';
import 'package:ky_docs/docx/widgets/spell_check/document_spell_check_filter.dart';

void main() {
  group('DocumentSpellCheckFilterModel', () {
    test('counts and filters issues by suggestion availability', () {
      final fixable = SpellCheckError(
        word: 'wrte',
        offset: 6,
        suggestions: const ['write'],
      );
      final manual = SpellCheckError(
        word: 'teh',
        offset: 12,
        suggestions: const [],
      );

      final model = DocumentSpellCheckFilterModel(
        errors: [fixable, manual],
        selectedFilter: DocumentSpellCheckIssueFilter.withSuggestions,
      );

      expect(model.countFor(DocumentSpellCheckIssueFilter.all), 2);
      expect(model.countFor(DocumentSpellCheckIssueFilter.withSuggestions), 1);
      expect(model.countFor(DocumentSpellCheckIssueFilter.noSuggestions), 1);
      expect(model.visibleErrors, [fixable]);
      expect(model.hasVisibleErrors, isTrue);
    });

    test('describes empty filtered result states', () {
      const model = DocumentSpellCheckFilterModel(
        errors: [],
        selectedFilter: DocumentSpellCheckIssueFilter.noSuggestions,
      );

      expect(model.visibleErrors, isEmpty);
      expect(model.emptyTitle, 'No manual review needed');
      expect(
        model.emptyMessage,
        'Every current issue has at least one replacement suggestion.',
      );
    });
  });
}

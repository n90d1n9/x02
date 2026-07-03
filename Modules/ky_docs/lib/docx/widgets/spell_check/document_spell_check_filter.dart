import '../../models/spell_check_error.dart';

/// Describes the issue filter used by the spell-check panel.
enum DocumentSpellCheckIssueFilter {
  all(label: 'All', description: 'Show every spelling issue'),
  withSuggestions(
    label: 'Suggestions',
    description: 'Show issues with replacement suggestions',
  ),
  noSuggestions(
    label: 'No suggestions',
    description: 'Show issues that need manual review',
  );

  final String label;
  final String description;

  const DocumentSpellCheckIssueFilter({
    required this.label,
    required this.description,
  });

  bool accepts(SpellCheckError error) {
    return switch (this) {
      DocumentSpellCheckIssueFilter.all => true,
      DocumentSpellCheckIssueFilter.withSuggestions =>
        error.suggestions.isNotEmpty,
      DocumentSpellCheckIssueFilter.noSuggestions => error.suggestions.isEmpty,
    };
  }
}

/// Builds filtered spell-check issue data for the panel UI.
class DocumentSpellCheckFilterModel {
  final List<SpellCheckError> errors;
  final DocumentSpellCheckIssueFilter selectedFilter;

  const DocumentSpellCheckFilterModel({
    required this.errors,
    required this.selectedFilter,
  });

  List<SpellCheckError> get visibleErrors {
    return errors.where(selectedFilter.accepts).toList(growable: false);
  }

  int countFor(DocumentSpellCheckIssueFilter filter) {
    return errors.where(filter.accepts).length;
  }

  bool get hasVisibleErrors => visibleErrors.isNotEmpty;

  String get emptyTitle {
    return switch (selectedFilter) {
      DocumentSpellCheckIssueFilter.all => 'No spelling issues found',
      DocumentSpellCheckIssueFilter.withSuggestions =>
        'No suggested fixes available',
      DocumentSpellCheckIssueFilter.noSuggestions => 'No manual review needed',
    };
  }

  String get emptyMessage {
    return switch (selectedFilter) {
      DocumentSpellCheckIssueFilter.all =>
        'The current text is clear of spelling issues.',
      DocumentSpellCheckIssueFilter.withSuggestions =>
        'Try reviewing all issues or adding words to the dictionary.',
      DocumentSpellCheckIssueFilter.noSuggestions =>
        'Every current issue has at least one replacement suggestion.',
    };
  }
}

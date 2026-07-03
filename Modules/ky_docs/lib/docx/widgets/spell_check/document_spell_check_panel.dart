import 'package:flutter/material.dart';

import '../../models/spell_check_error.dart';
import '../panel/document_panel_action_row.dart';
import '../panel/document_panel_empty_state.dart';
import '../panel/document_panel_filter_bar.dart';
import '../panel/document_panel_item_card.dart';
import '../panel/document_panel_result_summary.dart';
import '../panel/document_panel_summary_card.dart';
import 'document_spell_check_filter.dart';

typedef SpellCheckSuggestionAction =
    void Function(SpellCheckError error, String suggestion);

class DocumentSpellCheckPanel extends StatefulWidget {
  static const filterPrefixKey = 'document-spell-check-filter';
  static const filteredEmptyStateKey = ValueKey(
    'document-spell-check-filter-empty-state',
  );

  final List<SpellCheckError> errors;
  final SpellCheckSuggestionAction onReplaceWithSuggestion;
  final ValueChanged<SpellCheckError> onIgnore;
  final ValueChanged<SpellCheckError> onAddToDictionary;

  const DocumentSpellCheckPanel({
    super.key,
    required this.errors,
    required this.onReplaceWithSuggestion,
    required this.onIgnore,
    required this.onAddToDictionary,
  });

  @override
  State<DocumentSpellCheckPanel> createState() =>
      _DocumentSpellCheckPanelState();
}

class _DocumentSpellCheckPanelState extends State<DocumentSpellCheckPanel> {
  var _filter = DocumentSpellCheckIssueFilter.all;

  @override
  Widget build(BuildContext context) {
    if (widget.errors.isEmpty) return const _EmptySpellCheckState();

    final filterModel = DocumentSpellCheckFilterModel(
      errors: widget.errors,
      selectedFilter: _filter,
    );
    final visibleErrors = filterModel.visibleErrors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SpellCheckSummary(
          errorCount: widget.errors.length,
          suggestionCount: widget.errors.fold<int>(
            0,
            (count, error) => count + error.suggestions.length,
          ),
        ),
        const SizedBox(height: 14),
        _SpellCheckFilterBar(
          model: filterModel,
          onChanged: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: 10),
        _SpellCheckResultSummary(model: filterModel),
        const SizedBox(height: 14),
        if (visibleErrors.isEmpty)
          _FilteredSpellCheckEmptyState(model: filterModel)
        else
          for (var index = 0; index < visibleErrors.length; index++) ...[
            _SpellCheckIssueCard(
              error: visibleErrors[index],
              onReplaceWithSuggestion: widget.onReplaceWithSuggestion,
              onIgnore: widget.onIgnore,
              onAddToDictionary: widget.onAddToDictionary,
            ),
            if (index < visibleErrors.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _EmptySpellCheckState extends StatelessWidget {
  const _EmptySpellCheckState();

  @override
  Widget build(BuildContext context) {
    return const DocumentPanelEmptyState(
      icon: Icons.verified_outlined,
      title: 'All clear',
      message: 'No spelling issues found',
      tone: DocumentPanelEmptyStateTone.positive,
    );
  }
}

class _SpellCheckFilterBar extends StatelessWidget {
  final DocumentSpellCheckFilterModel model;
  final ValueChanged<DocumentSpellCheckIssueFilter> onChanged;

  const _SpellCheckFilterBar({required this.model, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelFilterBar<DocumentSpellCheckIssueFilter>(
      keyPrefix: DocumentSpellCheckPanel.filterPrefixKey,
      selectedValue: model.selectedFilter,
      options: [
        for (final filter in DocumentSpellCheckIssueFilter.values)
          DocumentPanelFilterOption(
            value: filter,
            keySuffix: filter.name,
            label: filter.label,
            count: model.countFor(filter),
            tooltip: filter.description,
          ),
      ],
      onSelected: onChanged,
    );
  }
}

class _FilteredSpellCheckEmptyState extends StatelessWidget {
  final DocumentSpellCheckFilterModel model;

  const _FilteredSpellCheckEmptyState({required this.model});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelEmptyState(
      key: DocumentSpellCheckPanel.filteredEmptyStateKey,
      icon: Icons.manage_search_outlined,
      title: model.emptyTitle,
      message: model.emptyMessage,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
    );
  }
}

class _SpellCheckResultSummary extends StatelessWidget {
  final DocumentSpellCheckFilterModel model;

  const _SpellCheckResultSummary({required this.model});

  @override
  Widget build(BuildContext context) {
    return DocumentPanelResultSummary(
      icon: Icons.filter_list_outlined,
      message: _summaryMessage,
    );
  }

  String get _summaryMessage {
    final count = model.visibleErrors.length;
    return switch (model.selectedFilter) {
      DocumentSpellCheckIssueFilter.all =>
        '$count spelling ${count == 1 ? 'issue' : 'issues'} visible',
      DocumentSpellCheckIssueFilter.withSuggestions =>
        '$count ${count == 1 ? 'issue' : 'issues'} with suggestions',
      DocumentSpellCheckIssueFilter.noSuggestions =>
        '$count ${count == 1 ? 'issue' : 'issues'} needing manual review',
    };
  }
}

class _SpellCheckSummary extends StatelessWidget {
  final int errorCount;
  final int suggestionCount;

  const _SpellCheckSummary({
    required this.errorCount,
    required this.suggestionCount,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelSummaryCard(
      icon: Icons.spellcheck_outlined,
      title: '$errorCount spelling ${errorCount == 1 ? 'issue' : 'issues'}',
      subtitle:
          '$suggestionCount replacement ${suggestionCount == 1 ? 'suggestion' : 'suggestions'} available',
      tone: DocumentPanelSummaryTone.error,
    );
  }
}

class _SpellCheckIssueCard extends StatelessWidget {
  final SpellCheckError error;
  final SpellCheckSuggestionAction onReplaceWithSuggestion;
  final ValueChanged<SpellCheckError> onIgnore;
  final ValueChanged<SpellCheckError> onAddToDictionary;

  const _SpellCheckIssueCard({
    required this.error,
    required this.onReplaceWithSuggestion,
    required this.onIgnore,
    required this.onAddToDictionary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DocumentPanelItemCard(
      leading: Icon(Icons.error_outline, color: colorScheme.error, size: 20),
      title: Text(
        error.word,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.error,
          decorationStyle: TextDecorationStyle.wavy,
        ),
      ),
      subtitle: Text(
        'Character ${error.offset}',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      body: error.suggestions.isEmpty
          ? Text(
              'No suggestions available',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : DocumentPanelActionRow(
              children: [
                for (final suggestion in error.suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    avatar: const Icon(Icons.swap_horiz, size: 16),
                    onPressed: () => onReplaceWithSuggestion(error, suggestion),
                  ),
              ],
            ),
      actions: DocumentPanelActionRow(
        children: [
          OutlinedButton.icon(
            onPressed: () => onIgnore(error),
            icon: const Icon(Icons.visibility_off_outlined, size: 18),
            label: const Text('Ignore'),
          ),
          OutlinedButton.icon(
            onPressed: () => onAddToDictionary(error),
            icon: const Icon(Icons.library_add_outlined, size: 18),
            label: const Text('Add to dictionary'),
          ),
        ],
      ),
    );
  }
}

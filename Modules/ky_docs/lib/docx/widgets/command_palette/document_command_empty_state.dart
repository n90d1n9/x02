import 'package:flutter/material.dart';

/// Presents recovery actions when command palette filters produce no results.
class DocumentCommandEmptyState extends StatelessWidget {
  static const emptyStateKey = ValueKey('document-command-empty-state');
  static const clearSearchButtonKey = ValueKey(
    'document-command-empty-clear-search',
  );
  static const resetCategoryButtonKey = ValueKey(
    'document-command-empty-reset-category',
  );

  final String query;
  final String categoryLabel;
  final bool canClearSearch;
  final bool canResetCategory;
  final VoidCallback onClearSearch;
  final VoidCallback onResetCategory;

  const DocumentCommandEmptyState({
    super.key = emptyStateKey,
    required this.query,
    required this.categoryLabel,
    required this.canClearSearch,
    required this.canResetCategory,
    required this.onClearSearch,
    required this.onResetCategory,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedQuery = query.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search,
            size: 34,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No commands found',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _messageFor(normalizedQuery),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (canClearSearch)
                OutlinedButton.icon(
                  key: clearSearchButtonKey,
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.close, size: 17),
                  label: const Text('Clear search'),
                ),
              if (canResetCategory)
                FilledButton.tonalIcon(
                  key: resetCategoryButtonKey,
                  onPressed: onResetCategory,
                  icon: const Icon(Icons.all_inbox_outlined, size: 17),
                  label: const Text('All commands'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _messageFor(String normalizedQuery) {
    if (normalizedQuery.isNotEmpty && canResetCategory) {
      return 'No matches for "$normalizedQuery" in $categoryLabel.';
    }
    if (normalizedQuery.isNotEmpty) {
      return 'No matches for "$normalizedQuery".';
    }
    if (canResetCategory) {
      return 'No commands available in $categoryLabel.';
    }
    return 'No commands are available right now.';
  }
}

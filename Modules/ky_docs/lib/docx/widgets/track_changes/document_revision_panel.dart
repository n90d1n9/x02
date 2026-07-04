import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../models/revision.dart';
import '../../states/doc_notifier.dart';
import '../panel/document_panel_empty_state.dart';
import '../panel/document_panel_header.dart';
import '../panel/document_panel_item_card.dart';
import '../panel/document_panel_shell.dart';

/// Provider for the revision panel state
final revisionPanelProvider = StateNotifierProvider<RevisionPanelNotifier, RevisionPanelState>(
  (ref) => RevisionPanelNotifier(),
);

/// State for the revision panel
class RevisionPanelState {
  final String? selectedRevisionId;
  final RevisionFilter filter;

  RevisionPanelState({
    this.selectedRevisionId,
    this.filter = RevisionFilter.pending,
  });

  RevisionPanelState copyWith({
    String? selectedRevisionId,
    RevisionFilter? filter,
  }) {
    return RevisionPanelState(
      selectedRevisionId: selectedRevisionId ?? this.selectedRevisionId,
      filter: filter ?? this.filter,
    );
  }
}

/// Filter options for revisions
enum RevisionFilter {
  all,
  pending,
  resolved,
}

/// Notifier for revision panel state
class RevisionPanelNotifier extends StateNotifier<RevisionPanelState> {
  RevisionPanelNotifier() : super(RevisionPanelState());

  void selectRevision(String? id) {
    state = state.copyWith(selectedRevisionId: id);
  }

  void setFilter(RevisionFilter filter) {
    state = state.copyWith(filter: filter);
  }
}

/// Panel displaying tracked changes (revisions) with accept/reject actions
class DocumentRevisionPanel extends ConsumerWidget {
  final VoidCallback? onClose;
  final bool showHeader;
  final bool showFrame;

  const DocumentRevisionPanel({
    super.key,
    this.onClose,
    this.showHeader = true,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentState = ref.watch(documentProvider);
    final panelState = ref.watch(revisionPanelProvider);
    final notifier = ref.read(revisionPanelProvider.notifier);
    final docNotifier = ref.read(documentProvider.notifier);

    final revisions = documentState.revisionManager.revisions;
    final filteredRevisions = _filterRevisions(revisions, panelState.filter);
    final pendingCount = revisions.where((r) => !r.isResolved).length;
    final resolvedCount = revisions.length - pendingCount;

    return DocumentPanelShell(
      showFrame: showFrame,
      child: Column(
        children: [
          if (showHeader)
            _RevisionPanelHeader(
              totalCount: revisions.length,
              pendingCount: pendingCount,
              resolvedCount: resolvedCount,
              currentFilter: panelState.filter,
              onFilterChanged: notifier.setFilter,
              onClose: onClose,
            ),
          _FilterBar(
            currentFilter: panelState.filter,
            onFilterChanged: notifier.setFilter,
          ),
          Expanded(
            child: filteredRevisions.isEmpty
                ? DocumentPanelEmptyState(
                    title: 'No revisions',
                    subtitle: panelState.filter == RevisionFilter.pending
                        ? 'All changes have been reviewed'
                        : 'No revisions match the current filter',
                  )
                : ListView.builder(
                    itemCount: filteredRevisions.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final revision = filteredRevisions[index];
                      final isSelected = panelState.selectedRevisionId == revision.id;
                      return _RevisionItemCard(
                        revision: revision,
                        isSelected: isSelected,
                        onSelect: () => notifier.selectRevision(revision.id),
                        onAccept: () => docNotifier.acceptRevision(revision.id),
                        onReject: () => docNotifier.rejectRevision(revision.id),
                        onJumpTo: () {
                          // TODO: Jump to the revision location in document
                        },
                      );
                    },
                  ),
          ),
          if (pendingCount > 0)
            _ActionRow(
              onAcceptAll: docNotifier.acceptAllRevisions,
              onRejectAll: docNotifier.rejectAllRevisions,
              onClearResolved: resolvedCount > 0
                  ? docNotifier.clearResolvedRevisions
                  : null,
            ),
        ],
      ),
    );
  }

  List<Revision> _filterRevisions(List<Revision> revisions, RevisionFilter filter) {
    switch (filter) {
      case RevisionFilter.pending:
        return revisions.where((r) => !r.isResolved).toList();
      case RevisionFilter.resolved:
        return revisions.where((r) => r.isResolved).toList();
      case RevisionFilter.all:
        return revisions;
    }
  }
}

class _RevisionPanelHeader extends StatelessWidget {
  final int totalCount;
  final int pendingCount;
  final int resolvedCount;
  final RevisionFilter currentFilter;
  final ValueChanged<RevisionFilter> onFilterChanged;
  final VoidCallback? onClose;

  const _RevisionPanelHeader({
    required this.totalCount,
    required this.pendingCount,
    required this.resolvedCount,
    required this.currentFilter,
    required this.onFilterChanged,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentPanelHeader(
      title: 'Track Changes',
      subtitle: '$totalCount total • $pendingCount pending • $resolvedCount resolved',
      onClose: onClose,
    );
  }
}

class _FilterBar extends StatelessWidget {
  final RevisionFilter currentFilter;
  final ValueChanged<RevisionFilter> onFilterChanged;

  const _FilterBar({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Pending',
            isSelected: currentFilter == RevisionFilter.pending,
            onTap: () => onFilterChanged(RevisionFilter.pending),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Resolved',
            isSelected: currentFilter == RevisionFilter.resolved,
            onTap: () => onFilterChanged(RevisionFilter.resolved),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'All',
            isSelected: currentFilter == RevisionFilter.all,
            onTap: () => onFilterChanged(RevisionFilter.all),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}

class _RevisionItemCard extends StatelessWidget {
  final Revision revision;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onJumpTo;

  const _RevisionItemCard({
    required this.revision,
    required this.isSelected,
    required this.onSelect,
    required this.onAccept,
    required this.onReject,
    required this.onJumpTo,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final isInsert = revision.type == RevisionType.insert;
    final isDelete = revision.type == RevisionType.delete;

    return DocumentPanelItemCard(
      isSelected: isSelected,
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInsert
                      ? Icons.add_circle_outline
                      : isDelete
                          ? Icons.remove_circle_outline
                          : Icons.edit_outlined,
                  size: 18,
                  color: isInsert
                      ? Colors.green
                      : isDelete
                          ? Colors.red
                          : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInsert
                        ? 'Insertion'
                        : isDelete
                            ? 'Deletion'
                            : 'Formatting change',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (revision.isResolved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Resolved',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getDataPreview(revision),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${revision.authorName} • ${dateFormat.format(revision.timestamp)}',
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (!revision.isResolved) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDataPreview(Revision revision) {
    if (revision.data is String) {
      return revision.data as String;
    }
    return 'Change at position ${revision.index}';
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onAcceptAll;
  final VoidCallback onRejectAll;
  final VoidCallback? onClearResolved;

  const _ActionRow({
    required this.onAcceptAll,
    required this.onRejectAll,
    this.onClearResolved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAcceptAll,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Accept All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRejectAll,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
          if (onClearResolved != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClearResolved,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear resolved',
            ),
          ],
        ],
      ),
    );
  }
}
